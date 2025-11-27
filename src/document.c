#include "automerge.h"

// Document Lifecycle Functions ------------------------------------------------

/**
 * Create a new Automerge document.
 *
 * @param actor_id R object: NULL for random actor ID, character hex string,
 *                 or raw bytes
 * @return External pointer to am_doc structure (with class "am_doc")
 */
SEXP C_am_create(SEXP actor_id) {
    AMresult *result = NULL;

    // Handle actor ID parameter
    if (actor_id == R_NilValue) {
        // NULL actor_id: AMcreate() will generate random actor ID
        result = AMcreate(NULL);
    } else if (TYPEOF(actor_id) == STRSXP && XLENGTH(actor_id) == 1) {
        // Hex string: convert to actor ID using AMactorIdFromStr
        const char *hex_str = CHAR(STRING_ELT(actor_id, 0));
        AMbyteSpan hex_span = {.src = (uint8_t const *) hex_str, .count = strlen(hex_str)};
        AMresult *actor_result = AMactorIdFromStr(hex_span);
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);

        AMitem *actor_item = AMresultItem(actor_result);
        AMactorId const *actor = NULL;
        AMitemToActorId(actor_item, &actor);

        result = AMcreate(actor);
        AMresultFree(actor_result);
    } else if (TYPEOF(actor_id) == RAWSXP) {
        // Raw bytes: convert to actor ID using AMactorIdFromBytes
        AMresult *actor_result = AMactorIdFromBytes(RAW(actor_id), (size_t) XLENGTH(actor_id));
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);

        AMitem *actor_item = AMresultItem(actor_result);
        AMactorId const *actor = NULL;
        AMitemToActorId(actor_item, &actor);

        result = AMcreate(actor);
        AMresultFree(actor_result);
    } else {
        Rf_error("actor_id must be NULL, a character string (hex), or raw bytes");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    // Extract the AMdoc* from the result
    AMitem *item = AMresultItem(result);
    AMdoc *doc = NULL;
    AMitemToDoc(item, &doc);

    // Create wrapper structure
    am_doc *doc_wrapper = malloc(sizeof(am_doc));
    if (!doc_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for document wrapper");
    }
    doc_wrapper->result = result;  // Store owning result
    doc_wrapper->doc = doc;        // Store borrowed doc pointer

    // Create external pointer with finalizer
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(doc_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_doc_finalizer);

    // Set class attribute
    SEXP class = Rf_allocVector(STRSXP, 2);
    Rf_classgets(ext_ptr, class);
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));
    
    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Save an Automerge document to binary format.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Raw vector containing the serialized document
 */
SEXP C_am_save(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMsave(doc);
    CHECK_RESULT(result, AM_VAL_TYPE_BYTES);

    // Extract bytes from result
    AMitem *item = AMresultItem(result);
    AMbyteSpan bytes;
    AMitemToBytes(item, &bytes);

    // Copy to R raw vector
    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Load an Automerge document from binary format.
 *
 * @param data Raw vector containing serialized document
 * @return External pointer to am_doc structure
 */
SEXP C_am_load(SEXP data) {
    if (TYPEOF(data) != RAWSXP) {
        Rf_error("data must be a raw vector");
    }

    AMresult *result = AMload(RAW(data), (size_t) XLENGTH(data));
    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    // Extract the AMdoc* from the result
    AMitem *item = AMresultItem(result);
    AMdoc *doc = NULL;
    AMitemToDoc(item, &doc);

    // Create wrapper structure
    am_doc *doc_wrapper = malloc(sizeof(am_doc));
    if (!doc_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for document wrapper");
    }
    doc_wrapper->result = result;
    doc_wrapper->doc = doc;

    // Create external pointer with finalizer
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(doc_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_doc_finalizer);

    // Set class attribute
    SEXP class = Rf_allocVector(STRSXP, 2);
    Rf_classgets(ext_ptr, class);
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Helper: Convert R list of change hashes to AMitems struct.
 *
 * Takes an R list of raw vectors (change hashes) and creates the necessary
 * AMresult objects, then extracts AMitems for use with C API functions.
 *
 * @param heads_list R list of raw vectors (change hashes)
 * @param results_out Output parameter: array of AMresult pointers to keep alive
 * @param n_results Output parameter: number of results in array
 * @return AMresult containing change hash items (must be freed by caller)
 */
static AMresult* convert_r_heads_to_amresult(SEXP heads_list, AMresult ***results_out, size_t *n_results) {
    if (TYPEOF(heads_list) != VECSXP) {
        Rf_error("heads must be NULL or a list of raw vectors");
    }

    R_xlen_t n_heads = XLENGTH(heads_list);
    if (n_heads == 0) {
        *results_out = NULL;
        *n_results = 0;
        return NULL;
    }

    // Allocate array to hold AMresult pointers (for memory management)
    AMresult **results = malloc(n_heads * sizeof(AMresult *));
    if (!results) {
        Rf_error("Failed to allocate memory for change hash results");
    }

    // Convert each R raw vector to AMresult containing a change hash
    for (R_xlen_t i = 0; i < n_heads; i++) {
        SEXP r_hash = VECTOR_ELT(heads_list, i);
        if (TYPEOF(r_hash) != RAWSXP) {
            for (R_xlen_t j = 0; j < i; j++) {
                AMresultFree(results[j]);
            }
            free(results);
            Rf_error("All heads must be raw vectors (change hashes)");
        }

        // Create AMbyteSpan for this hash
        AMbyteSpan hash_span = {
            .src = RAW(r_hash),
            .count = (size_t) XLENGTH(r_hash)
        };

        // Convert to change hash item
        results[i] = AMitemFromChangeHash(hash_span);
        if (!results[i] || AMresultStatus(results[i]) != AM_STATUS_OK) {
            for (R_xlen_t j = 0; j <= i; j++) {
                if (results[j]) AMresultFree(results[j]);
            }
            free(results);
            Rf_error("Invalid change hash at index %lld", (long long) i);
        }
    }

    *results_out = results;
    *n_results = (size_t) n_heads;

    // For a single head, return the result directly
    if (n_heads == 1) {
        return results[0];
    }

    // For multiple heads, we need to combine them into a single AMresult
    // The most straightforward approach is to use the first result and note
    // that AMfork expects AMitems from a result like AMgetHeads()
    // Since we don't have a public API to build multi-item AMresults,
    // we'll use a workaround for now and implement this properly
    Rf_error("Forking at multiple specific heads not yet fully implemented (use single head or NULL)");

    return NULL;  // Not reached
}

/**
 * Fork an Automerge document at current or specified heads.
 *
 * @param doc_ptr External pointer to am_doc
 * @param heads R object: NULL for current heads, or list of change hashes (raw vectors)
 * @return External pointer to forked am_doc
 */
SEXP C_am_fork(SEXP doc_ptr, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = NULL;
    AMresult **head_results = NULL;
    size_t n_head_results = 0;

    if (heads == R_NilValue || (TYPEOF(heads) == VECSXP && XLENGTH(heads) == 0)) {
        // Fork at current heads (NULL or empty list)
        result = AMfork(doc, NULL);
    } else {
        // Fork at specified heads
        AMresult *heads_result = convert_r_heads_to_amresult(heads, &head_results, &n_head_results);

        if (n_head_results == 0) {
            // Empty list case - treat as NULL
            result = AMfork(doc, NULL);
        } else if (heads_result && n_head_results == 1) {
            // Single head case - can handle this
            AMitems heads_items = AMresultItems(heads_result);
            result = AMfork(doc, &heads_items);

            // Clean up head result
            AMresultFree(heads_result);
            free(head_results);
        } else {
            // Multiple heads case - not yet fully implemented
            // Clean up allocated resources
            if (head_results) {
                for (size_t i = 0; i < n_head_results; i++) {
                    AMresultFree(head_results[i]);
                }
                free(head_results);
            }
            Rf_error("Forking at multiple specific heads not yet fully implemented");
        }
    }

    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    // Extract the AMdoc* from the result
    AMitem *item = AMresultItem(result);
    AMdoc *forked_doc = NULL;
    AMitemToDoc(item, &forked_doc);

    // Create wrapper structure
    am_doc *doc_wrapper = malloc(sizeof(am_doc));
    if (!doc_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for forked document wrapper");
    }
    doc_wrapper->result = result;
    doc_wrapper->doc = forked_doc;

    // Create external pointer with finalizer
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(doc_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_doc_finalizer);

    // Set class attribute
    SEXP class = Rf_allocVector(STRSXP, 2);
    Rf_classgets(ext_ptr, class);
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Merge changes from another document.
 *
 * @param doc_ptr External pointer to am_doc (target document)
 * @param other_ptr External pointer to am_doc (source document)
 * @return The target document pointer (for chaining)
 */
SEXP C_am_merge(SEXP doc_ptr, SEXP other_ptr) {
    AMdoc *doc = get_doc(doc_ptr);
    AMdoc *other_doc = get_doc(other_ptr);

    AMresult *result = AMmerge(doc, other_doc);

    // AMmerge returns heads (change hashes) if changes were merged,
    // but result can be empty if there were no new changes
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;  // Return document for chaining
}

/**
 * Get the actor ID of a document.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Raw vector containing actor ID bytes
 */
SEXP C_am_get_actor(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetActorId(doc);
    CHECK_RESULT(result, AM_VAL_TYPE_ACTOR_ID);

    // Extract actor ID
    AMitem *item = AMresultItem(result);
    AMactorId const *actor_id = NULL;
    AMitemToActorId(item, &actor_id);

    // Convert to bytes
    AMbyteSpan bytes = AMactorIdBytes(actor_id);

    // Copy to R raw vector
    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Get the actor ID as hex string.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Character string containing hex-encoded actor ID
 */
SEXP C_am_get_actor_hex(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetActorId(doc);
    CHECK_RESULT(result, AM_VAL_TYPE_ACTOR_ID);

    AMitem *item = AMresultItem(result);
    AMactorId const *actor_id = NULL;
    AMitemToActorId(item, &actor_id);

    AMbyteSpan hex_str = AMactorIdStr(actor_id);

    SEXP r_str = Rf_ScalarString(Rf_mkCharLenCE((const char*) hex_str.src, hex_str.count, CE_UTF8));

    AMresultFree(result);
    return r_str;
}

/**
 * Set the actor ID of a document.
 *
 * @param doc_ptr External pointer to am_doc
 * @param actor_id R object: NULL for random, character hex string, or raw bytes
 * @return The document pointer (for chaining)
 */
SEXP C_am_set_actor(SEXP doc_ptr, SEXP actor_id) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *actor_result = NULL;
    AMresult *put_result = NULL;
    AMactorId const *actor = NULL;

    if (actor_id == R_NilValue) {
        // NULL: generate random actor ID
        actor_result = AMactorIdInit();
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        AMitemToActorId(actor_item, &actor);
    } else if (TYPEOF(actor_id) == STRSXP && XLENGTH(actor_id) == 1) {
        // Hex string
        const char *hex_str = CHAR(STRING_ELT(actor_id, 0));
        AMbyteSpan hex_span = {.src = (uint8_t const *) hex_str, .count = strlen(hex_str)};
        actor_result = AMactorIdFromStr(hex_span);
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        AMitemToActorId(actor_item, &actor);
    } else if (TYPEOF(actor_id) == RAWSXP) {
        // Raw bytes
        actor_result = AMactorIdFromBytes(RAW(actor_id), (size_t) XLENGTH(actor_id));
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        AMitemToActorId(actor_item, &actor);
    } else {
        Rf_error("actor_id must be NULL, a character string (hex), or raw bytes");
    }

    // Set the actor ID
    put_result = AMsetActorId(doc, actor);

    AMresultFree(put_result);
    AMresultFree(actor_result);
    return doc_ptr;  // Return document for chaining
}

/**
 * Commit pending changes with optional message and timestamp.
 *
 * @param doc_ptr External pointer to am_doc
 * @param message Character string commit message (or NULL)
 * @param time POSIXct timestamp (or NULL for current time)
 * @return The document pointer (for chaining)
 */
SEXP C_am_commit(SEXP doc_ptr, SEXP message, SEXP time) {
    AMdoc *doc = get_doc(doc_ptr);

    // Handle message parameter
    AMbyteSpan msg_span = {.src = NULL, .count = 0};
    if (message != R_NilValue) {
        if (TYPEOF(message) != STRSXP || XLENGTH(message) != 1) {
            Rf_error("message must be NULL or a single character string");
        }
        const char *msg_str = CHAR(STRING_ELT(message, 0));
        msg_span.src = (uint8_t const *) msg_str;
        msg_span.count = strlen(msg_str);
    }

    // Handle time parameter
    int64_t timestamp = 0;
    if (time != R_NilValue) {
        if (!Rf_inherits(time, "POSIXct") || Rf_xlength(time) != 1) {
            Rf_error("time must be NULL or a scalar POSIXct object");
        }
        double seconds = REAL(time)[0];
        timestamp = (int64_t)(seconds * 1000.0);  // Convert to milliseconds
    }

    AMresult *result = AMcommit(doc, msg_span, time == R_NilValue ? NULL : &timestamp);

    // AMcommit returns VOID if there were no pending operations,
    // or CHANGE_HASH if changes were committed
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;  // Return document for chaining
}

/**
 * Roll back pending operations in the current transaction.
 *
 * @param doc_ptr External pointer to am_doc
 * @return The document pointer (for chaining)
 */
SEXP C_am_rollback(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMrollback(doc);

    return doc_ptr;  // Return document for chaining
}

// Historical Query and Advanced Fork/Merge Functions (Phase 6) ---------------

/**
 * Get the last change made by the local actor.
 *
 * Returns the most recent change created by this document's actor,
 * or NULL if no local changes have been made.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Raw vector containing the serialized change, or NULL if none
 */
SEXP C_am_get_last_local_change(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetLastLocalChange(doc);

    // Check result status
    AMstatus status = AMresultStatus(result);
    if (status != AM_STATUS_OK) {
        AMresultFree(result);
        return R_NilValue;
    }

    // Check if there are any items
    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        // No local changes
        AMresultFree(result);
        return R_NilValue;
    }

    // Extract the first item
    AMitem *item = AMitemsNext(&items, 1);
    if (!item) {
        AMresultFree(result);
        return R_NilValue;
    }

    // Check if it's actually a change (not void)
    AMchange *change = NULL;
    if (!AMitemToChange(item, &change) || !change) {
        AMresultFree(result);
        return R_NilValue;
    }

    // Serialize change to bytes
    AMbyteSpan bytes = AMchangeRawBytes(change);

    // Copy to R raw vector
    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Get a specific change by its hash.
 *
 * @param doc_ptr External pointer to am_doc
 * @param hash Raw vector containing the change hash (32 bytes)
 * @return Raw vector containing the serialized change, or NULL if not found
 */
SEXP C_am_get_change_by_hash(SEXP doc_ptr, SEXP hash) {
    AMdoc *doc = get_doc(doc_ptr);

    // Validate hash parameter
    if (TYPEOF(hash) != RAWSXP) {
        Rf_error("hash must be a raw vector");
    }

    size_t hash_len = (size_t) XLENGTH(hash);
    if (hash_len != 32) {  // AM_CHANGE_HASH_SIZE
        Rf_error("Change hash must be exactly 32 bytes");
    }

    // Get change by hash
    AMresult *result = AMgetChangeByHash(doc, RAW(hash), hash_len);

    // Check status
    AMstatus status = AMresultStatus(result);
    if (status != AM_STATUS_OK) {
        AMresultFree(result);
        return R_NilValue;  // Change not found
    }

    // Extract the change
    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return R_NilValue;
    }

    AMitem *item = AMitemsNext(&items, 1);
    if (!item) {
        AMresultFree(result);
        return R_NilValue;
    }

    // Check if it's actually a change
    AMchange *change = NULL;
    if (!AMitemToChange(item, &change) || !change) {
        AMresultFree(result);
        return R_NilValue;  // Change not found
    }

    // Serialize change to bytes
    AMbyteSpan bytes = AMchangeRawBytes(change);

    // Copy to R raw vector
    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Get changes in doc2 that are not in doc1.
 *
 * Compares two documents and returns the changes that exist in doc2
 * but not in doc1. Useful for determining what changes need to be
 * applied to bring doc1 up to date with doc2.
 *
 * @param doc1_ptr External pointer to am_doc (base document)
 * @param doc2_ptr External pointer to am_doc (comparison document)
 * @return List of raw vectors (serialized changes)
 */
SEXP C_am_get_changes_added(SEXP doc1_ptr, SEXP doc2_ptr) {
    AMdoc *doc1 = get_doc(doc1_ptr);
    AMdoc *doc2 = get_doc(doc2_ptr);

    AMresult *result = AMgetChangesAdded(doc1, doc2);

    // Check result status
    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE);  // Will error and free
    }

    // Count change items
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
        AMitemToChange(item, &change);

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
