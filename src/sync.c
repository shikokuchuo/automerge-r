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
    // Initialize sync state (no document parameter)
    AMresult *result = AMsyncStateInit();
    CHECK_RESULT(result, AM_VAL_TYPE_SYNC_STATE);

    // Extract the AMsyncState* from the result using AMitemToSyncState()
    AMitem *item = AMresultItem(result);
    AMsyncState *state = NULL;
    if (!AMitemToSyncState(item, &state)) {
        AMresultFree(result);
        Rf_error("Failed to extract sync state from result");
    }

    // Create wrapper structure
    am_syncstate *state_wrapper = (am_syncstate *) malloc(sizeof(am_syncstate));
    if (!state_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for sync state wrapper");
    }
    state_wrapper->result = result;  // Store owning result
    state_wrapper->state = state;    // Store borrowed state pointer

    // Create external pointer with finalizer
    // NOTE: No parent to protect - sync state is document-independent
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(state_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_syncstate_finalizer);

    // Set class attribute
    SEXP class = Rf_mkString("am_syncstate");
    Rf_classgets(ext_ptr, class);

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

    // Extract sync state
    if (TYPEOF(sync_state_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for sync state");
    }
    am_syncstate *state_wrapper = (am_syncstate *) R_ExternalPtrAddr(sync_state_ptr);
    if (!state_wrapper || !state_wrapper->state) {
        Rf_error("Invalid sync state pointer (NULL or freed)");
    }

    // Generate sync message
    AMresult *result = AMgenerateSyncMessage(doc, state_wrapper->state);

    // Check result status
    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error and free
    }

    // Get result item and check type
    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        Rf_error("AMgenerateSyncMessage returned NULL item");
    }

    AMvalType type = AMitemValType(item);

    if (type == AM_VAL_TYPE_VOID) {
        // No message to send (sync complete)
        AMresultFree(result);
        return R_NilValue;
    }

    if (type != AM_VAL_TYPE_SYNC_MESSAGE) {
        AMresultFree(result);
        Rf_error("Unexpected result type from AMgenerateSyncMessage: %d", type);
    }

    // Extract sync message
    AMsyncMessage const *msg = NULL;
    if (!AMitemToSyncMessage(item, &msg)) {
        AMresultFree(result);
        Rf_error("Failed to extract sync message from result");
    }

    // Encode sync message to bytes
    AMresult *encode_result = AMsyncMessageEncode(msg);
    CHECK_RESULT(encode_result, AM_VAL_TYPE_BYTES);

    AMitem *encode_item = AMresultItem(encode_result);
    AMbyteSpan bytes;
    if (!AMitemToBytes(encode_item, &bytes)) {
        AMresultFree(encode_result);
        AMresultFree(result);
        Rf_error("Failed to extract bytes from encoded sync message");
    }

    // Copy to R raw vector
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

    // Extract sync state
    if (TYPEOF(sync_state_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for sync state");
    }
    am_syncstate *state_wrapper = (am_syncstate *) R_ExternalPtrAddr(sync_state_ptr);
    if (!state_wrapper || !state_wrapper->state) {
        Rf_error("Invalid sync state pointer (NULL or freed)");
    }

    // Validate message parameter
    if (TYPEOF(message) != RAWSXP) {
        Rf_error("message must be a raw vector");
    }

    // Decode sync message from bytes
    AMresult *decode_result = AMsyncMessageDecode(RAW(message), (size_t) XLENGTH(message));
    CHECK_RESULT(decode_result, AM_VAL_TYPE_SYNC_MESSAGE);

    AMitem *decode_item = AMresultItem(decode_result);
    AMsyncMessage const *msg = NULL;
    if (!AMitemToSyncMessage(decode_item, &msg)) {
        AMresultFree(decode_result);
        Rf_error("Failed to extract sync message from decoded bytes");
    }

    // Receive sync message
    AMresult *result = AMreceiveSyncMessage(doc, state_wrapper->state, msg);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    AMresultFree(decode_result);
    return doc_ptr;  // Return document for chaining
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

    // Check result status
    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE_HASH);  // Will error and free
    }

    // Count items (may be 0 for new document)
    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    // If no heads, return empty list
    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

    // Create R list to hold change hashes
    SEXP heads_list = PROTECT(Rf_allocVector(VECSXP, count));

    // Iterate and extract each change hash
    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMbyteSpan hash;
        if (!AMitemToChangeHash(item, &hash)) {
            AMresultFree(result);
            UNPROTECT(1);
            Rf_error("Failed to extract change hash at index %zu", i);
        }

        // Copy hash to R raw vector
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

    // Get changes - for now only support NULL heads (all changes)
    // TODO Phase 5+: Support getting changes since specific heads
    if (heads != R_NilValue) {
        Rf_error("Getting changes since specific heads not yet implemented (use NULL for all changes)");
    }

    AMresult *result = AMgetChanges(doc, NULL);

    // Check result status
    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE);  // Will error and free
    }

    // Count change items (may be 0 for empty document)
    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    // If no changes, return empty list
    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

    // Create R list to hold serialized changes
    SEXP changes_list = PROTECT(Rf_allocVector(VECSXP, count));

    // Iterate and serialize each change
    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMchange *change = NULL;
        if (!AMitemToChange(item, &change)) {
            AMresultFree(result);
            UNPROTECT(1);
            Rf_error("Failed to extract change at index %zu", i);
        }

        // Serialize change to bytes
        AMbyteSpan bytes = AMchangeRawBytes(change);

        // Copy to R raw vector
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

    // Validate changes parameter
    if (TYPEOF(changes) != VECSXP) {
        Rf_error("changes must be a list of raw vectors");
    }

    R_xlen_t n_changes = XLENGTH(changes);
    if (n_changes == 0) {
        // No changes to apply
        return doc_ptr;
    }

    // Apply each change using AMloadIncremental
    for (R_xlen_t i = 0; i < n_changes; i++) {
        SEXP change_bytes = VECTOR_ELT(changes, i);
        if (TYPEOF(change_bytes) != RAWSXP) {
            Rf_error("All changes must be raw vectors (got type %d at index %lld)",
                    TYPEOF(change_bytes), (long long) i);
        }

        // Apply this change incrementally
        AMresult *result = AMloadIncremental(doc, RAW(change_bytes), (size_t) XLENGTH(change_bytes));

        // Check for errors
        if (AMresultStatus(result) != AM_STATUS_OK) {
            // Extract error message
            AMbyteSpan error_span = AMresultError(result);
            char error_msg[MAX_ERROR_MSG_SIZE];
            size_t msg_len = error_span.count < MAX_ERROR_MSG_SIZE - 1 ?
                           error_span.count : MAX_ERROR_MSG_SIZE - 1;
            memcpy(error_msg, error_span.src, msg_len);
            error_msg[msg_len] = '\0';

            AMresultFree(result);
            Rf_error("Failed to apply change at index %lld: %s", (long long) i, error_msg);
        }

        AMresultFree(result);
    }

    return doc_ptr;  // Return document for chaining
}
