#include "automerge.h"

// Synchronization Functions ------------------------------------------------

/**
 * Create a new sync state for managing synchronization with a peer.
 *
 * IMPORTANT: Sync state is document-independent. The document is passed
 * separately to am_sync_encode() and am_sync_decode() at call time.
 *
 * @return External pointer to am_syncstate structure (with class "am_syncstate")
 */
SEXP C_am_sync_state_new(void) {
    AMresult *result = AMsyncStateInit();
    CHECK_RESULT(result, AM_VAL_TYPE_SYNC_STATE);

    AMitem *item = AMresultItem(result);
    AMsyncState *state = NULL;
    AMitemToSyncState(item, &state);

    am_syncstate *state_wrapper = malloc(sizeof(am_syncstate));
    if (!state_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for sync state wrapper");
    }
    state_wrapper->result = result;  // Owning result
    state_wrapper->state = state;    // Borrowed from result

    // No parent to protect - sync state is document-independent
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(state_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_syncstate_finalizer);

    Rf_classgets(ext_ptr, Rf_mkString("am_syncstate"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Generate a sync message to send to a peer.
 *
 * Wraps AMgenerateSyncMessage(doc, sync_state).
 *
 * @param doc_ptr External pointer to am_doc
 * @param sync_state_ptr External pointer to am_syncstate
 * @return Raw vector containing sync message, or NULL if no message to send
 */
SEXP C_am_sync_encode(SEXP doc_ptr, SEXP sync_state_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    if (TYPEOF(sync_state_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for sync state");
    }
    am_syncstate *state_wrapper = (am_syncstate *) R_ExternalPtrAddr(sync_state_ptr);
    if (!state_wrapper || !state_wrapper->state) {
        Rf_error("Invalid sync state pointer (NULL or freed)");
    }

    AMresult *result = AMgenerateSyncMessage(doc, state_wrapper->state);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        Rf_error("AMgenerateSyncMessage returned NULL item");
    }

    AMvalType type = AMitemValType(item);

    if (type == AM_VAL_TYPE_VOID) {
        // No message to send - sync complete
        AMresultFree(result);
        return R_NilValue;
    }

    if (type != AM_VAL_TYPE_SYNC_MESSAGE) {
        AMresultFree(result);
        Rf_error("Unexpected result type from AMgenerateSyncMessage: %d", type);
    }

    AMsyncMessage const *msg = NULL;
    AMitemToSyncMessage(item, &msg);

    AMresult *encode_result = AMsyncMessageEncode(msg);
    CHECK_RESULT(encode_result, AM_VAL_TYPE_BYTES);

    AMitem *encode_item = AMresultItem(encode_result);
    AMbyteSpan bytes;
    AMitemToBytes(encode_item, &bytes);

    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(encode_result);
    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Receive and apply a sync message from a peer.
 *
 * Wraps AMreceiveSyncMessage(doc, sync_state, message).
 *
 * @param doc_ptr External pointer to am_doc
 * @param sync_state_ptr External pointer to am_syncstate
 * @param message Raw vector containing encoded sync message
 * @return The document pointer (invisibly, for chaining)
 */
SEXP C_am_sync_decode(SEXP doc_ptr, SEXP sync_state_ptr, SEXP message) {
    AMdoc *doc = get_doc(doc_ptr);

    if (TYPEOF(sync_state_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for sync state");
    }
    am_syncstate *state_wrapper = (am_syncstate *) R_ExternalPtrAddr(sync_state_ptr);
    if (!state_wrapper || !state_wrapper->state) {
        Rf_error("Invalid sync state pointer (NULL or freed)");
    }

    if (TYPEOF(message) != RAWSXP) {
        Rf_error("message must be a raw vector");
    }

    AMresult *decode_result = AMsyncMessageDecode(RAW(message), (size_t) XLENGTH(message));
    CHECK_RESULT(decode_result, AM_VAL_TYPE_SYNC_MESSAGE);

    AMitem *decode_item = AMresultItem(decode_result);
    AMsyncMessage const *msg = NULL;
    AMitemToSyncMessage(decode_item, &msg);

    AMresult *result = AMreceiveSyncMessage(doc, state_wrapper->state, msg);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    AMresultFree(decode_result);
    return doc_ptr;
}

// Change Tracking and History Functions -------------------------------------

/**
 * Get the current heads (latest change hashes) of a document.
 *
 * Wraps AMgetHeads(doc).
 *
 * @param doc_ptr External pointer to am_doc
 * @return List of raw vectors (change hashes)
 */
SEXP C_am_get_heads(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetHeads(doc);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE_HASH);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

    SEXP heads_list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMbyteSpan hash;
        AMitemToChangeHash(item, &hash);

        SEXP r_hash = Rf_allocVector(RAWSXP, hash.count);
        memcpy(RAW(r_hash), hash.src, hash.count);
        SET_VECTOR_ELT(heads_list, i, r_hash);
    }

    AMresultFree(result);
    UNPROTECT(1);
    return heads_list;
}

/**
 * Get changes since specified heads (or all changes if heads is NULL).
 *
 * Wraps AMgetChanges(doc, heads).
 *
 * @param doc_ptr External pointer to am_doc
 * @param heads List of raw vectors (change hashes), or NULL for all changes
 * @return List of raw vectors (serialized changes)
 */
SEXP C_am_get_changes(SEXP doc_ptr, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = NULL;

    if (heads == R_NilValue) {
        result = AMgetChanges(doc, NULL);
    } else {
        if (TYPEOF(heads) != VECSXP) {
            Rf_error("heads must be NULL or a list of raw vectors");
        }

        R_xlen_t heads_count = Rf_xlength(heads);
        if (heads_count == 0) {
            // Empty list treated same as NULL
            result = AMgetChanges(doc, NULL);
        } else if (heads_count == 1) {
            SEXP r_hash = VECTOR_ELT(heads, 0);
            if (TYPEOF(r_hash) != RAWSXP) {
                Rf_error("Each head must be a raw vector");
            }

            AMbyteSpan hash_span = {
                .src = RAW(r_hash),
                .count = (size_t)Rf_xlength(r_hash)
            };

            AMresult *heads_result = AMitemFromChangeHash(hash_span);
            if (!heads_result || AMresultStatus(heads_result) != AM_STATUS_OK) {
                if (heads_result) AMresultFree(heads_result);
                Rf_error("Invalid change hash");
            }

            AMitems heads_items = AMresultItems(heads_result);
            result = AMgetChanges(doc, &heads_items);

            AMresultFree(heads_result);
        } else {
            // Multiple heads not yet implemented
            Rf_error("Getting changes since multiple specific heads not yet implemented (use single head or NULL)");
        }
    }

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

    SEXP changes_list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMchange *change = NULL;
        AMitemToChange(item, &change);

        AMbyteSpan bytes = AMchangeRawBytes(change);

        SEXP r_bytes = Rf_allocVector(RAWSXP, bytes.count);
        memcpy(RAW(r_bytes), bytes.src, bytes.count);
        SET_VECTOR_ELT(changes_list, i, r_bytes);
    }

    AMresultFree(result);
    UNPROTECT(1);
    return changes_list;
}

/**
 * Apply changes from another peer to this document.
 *
 * Uses AMloadIncremental() to apply each serialized change.
 *
 * @param doc_ptr External pointer to am_doc
 * @param changes List of raw vectors (serialized changes)
 * @return The document pointer (invisibly, for chaining)
 */
SEXP C_am_apply_changes(SEXP doc_ptr, SEXP changes) {
    AMdoc *doc = get_doc(doc_ptr);

    if (TYPEOF(changes) != VECSXP) {
        Rf_error("changes must be a list of raw vectors");
    }

    R_xlen_t n_changes = XLENGTH(changes);
    if (n_changes == 0) {
        return doc_ptr;
    }

    for (R_xlen_t i = 0; i < n_changes; i++) {
        SEXP change_bytes = VECTOR_ELT(changes, i);
        if (TYPEOF(change_bytes) != RAWSXP) {
            Rf_error("All changes must be raw vectors (got type %d at index %lld)",
                    TYPEOF(change_bytes), (long long) i);
        }

        AMresult *result = AMloadIncremental(doc, RAW(change_bytes), (size_t) XLENGTH(change_bytes));

        // Provide context about which change failed
        if (AMresultStatus(result) != AM_STATUS_OK) {
            AMbyteSpan error_span = AMresultError(result);
            size_t msg_size = error_span.count < MAX_ERROR_MSG_SIZE ?
                              error_span.count : MAX_ERROR_MSG_SIZE;
            char error_msg[MAX_ERROR_MSG_SIZE + 1];
            memcpy(error_msg, error_span.src, msg_size);
            error_msg[msg_size] = '\0';

            AMresultFree(result);
            Rf_error("Failed to apply change at index %lld: %s", (long long) i, error_msg);
        }

        AMresultFree(result);
    }

    return doc_ptr;
}
