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
    } else if (TYPEOF(actor_id) == STRSXP && Rf_length(actor_id) == 1) {
        // Hex string: convert to actor ID using AMactorIdFromStr
        const char *hex_str = CHAR(STRING_ELT(actor_id, 0));
        AMbyteSpan hex_span = {.src = (uint8_t const *) hex_str, .count = strlen(hex_str)};
        AMresult *actor_result = AMactorIdFromStr(hex_span);
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);

        AMitem *actor_item = AMresultItem(actor_result);
        AMactorId const *actor = NULL;
        if (!AMitemToActorId(actor_item, &actor)) {
            AMresultFree(actor_result);
            Rf_error("Failed to extract actor ID from string");
        }

        result = AMcreate(actor);
        AMresultFree(actor_result);
    } else if (TYPEOF(actor_id) == RAWSXP) {
        // Raw bytes: convert to actor ID using AMactorIdFromBytes
        AMresult *actor_result = AMactorIdFromBytes(RAW(actor_id), (size_t) Rf_length(actor_id));
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);

        AMitem *actor_item = AMresultItem(actor_result);
        AMactorId const *actor = NULL;
        if (!AMitemToActorId(actor_item, &actor)) {
            AMresultFree(actor_result);
            Rf_error("Failed to extract actor ID from bytes");
        }

        result = AMcreate(actor);
        AMresultFree(actor_result);
    } else {
        Rf_error("actor_id must be NULL, a character string (hex), or raw bytes");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    // Extract the AMdoc* from the result
    AMitem *item = AMresultItem(result);
    AMdoc *doc = NULL;
    if (!AMitemToDoc(item, &doc)) {
        AMresultFree(result);
        Rf_error("Failed to extract document from result");
    }

    // Create wrapper structure
    am_doc *doc_wrapper = (am_doc *) malloc(sizeof(am_doc));
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
    SEXP class = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));
    Rf_classgets(ext_ptr, class);

    UNPROTECT(2);
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
    if (!AMitemToBytes(item, &bytes)) {
        AMresultFree(result);
        Rf_error("Failed to extract bytes from save result");
    }

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

    AMresult *result = AMload(RAW(data), (size_t) Rf_length(data));
    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    // Extract the AMdoc* from the result
    AMitem *item = AMresultItem(result);
    AMdoc *doc = NULL;
    if (!AMitemToDoc(item, &doc)) {
        AMresultFree(result);
        Rf_error("Failed to extract document from load result");
    }

    // Create wrapper structure
    am_doc *doc_wrapper = (am_doc *) malloc(sizeof(am_doc));
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
    SEXP class = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));
    Rf_classgets(ext_ptr, class);

    UNPROTECT(2);
    return ext_ptr;
}

/**
 * Fork an Automerge document at current or specified heads.
 *
 * @param doc_ptr External pointer to am_doc
 * @param heads R object: NULL for current heads, or list of change hashes
 * @return External pointer to forked am_doc
 */
SEXP C_am_fork(SEXP doc_ptr, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = NULL;

    if (heads == R_NilValue) {
        // Fork at current heads
        result = AMfork(doc, NULL);
    } else {
        // Fork at specified heads - implementation deferred to Phase 5
        // (requires change handling which is in Phase 5)
        Rf_error("Forking at specific heads not yet implemented (Phase 5)");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    // Extract the AMdoc* from the result
    AMitem *item = AMresultItem(result);
    AMdoc *forked_doc = NULL;
    if (!AMitemToDoc(item, &forked_doc)) {
        AMresultFree(result);
        Rf_error("Failed to extract forked document from result");
    }

    // Create wrapper structure
    am_doc *doc_wrapper = (am_doc *) malloc(sizeof(am_doc));
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
    SEXP class = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));
    Rf_classgets(ext_ptr, class);

    UNPROTECT(2);
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
    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error and free
    }

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
    if (!AMitemToActorId(item, &actor_id)) {
        AMresultFree(result);
        Rf_error("Failed to extract actor ID from result");
    }

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
 * Set the actor ID of a document.
 *
 * @param doc_ptr External pointer to am_doc
 * @param actor_id R object: NULL for random, character hex string, or raw bytes
 * @return The document pointer (for chaining)
 */
SEXP C_am_set_actor(SEXP doc_ptr, SEXP actor_id) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *actor_result, *put_result = NULL;
    AMactorId const *actor = NULL;

    if (actor_id == R_NilValue) {
        // NULL: generate random actor ID
        actor_result = AMactorIdInit();
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        if (!AMitemToActorId(actor_item, &actor)) {
            AMresultFree(actor_result);
            Rf_error("Failed to extract actor ID from init");
        }
    } else if (TYPEOF(actor_id) == STRSXP && Rf_length(actor_id) == 1) {
        // Hex string
        const char *hex_str = CHAR(STRING_ELT(actor_id, 0));
        AMbyteSpan hex_span = {.src = (uint8_t const *) hex_str, .count = strlen(hex_str)};
        actor_result = AMactorIdFromStr(hex_span);
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        if (!AMitemToActorId(actor_item, &actor)) {
            AMresultFree(actor_result);
            Rf_error("Failed to extract actor ID from string");
        }
    } else if (TYPEOF(actor_id) == RAWSXP) {
        // Raw bytes
        actor_result = AMactorIdFromBytes(RAW(actor_id), (size_t) Rf_length(actor_id));
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        if (!AMitemToActorId(actor_item, &actor)) {
            AMresultFree(actor_result);
            Rf_error("Failed to extract actor ID from bytes");
        }
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
        if (TYPEOF(message) != STRSXP || Rf_length(message) != 1) {
            Rf_error("message must be NULL or a single character string");
        }
        const char *msg_str = CHAR(STRING_ELT(message, 0));
        msg_span.src = (uint8_t const *) msg_str;
        msg_span.count = strlen(msg_str);
    }

    // Handle time parameter
    int64_t timestamp = 0;
    if (time != R_NilValue) {
        if (!Rf_inherits(time, "POSIXct") || Rf_length(time) != 1) {
            Rf_error("time must be NULL or a scalar POSIXct object");
        }
        double seconds = REAL(time)[0];
        timestamp = (int64_t)(seconds * 1000.0);  // Convert to milliseconds
    }

    AMresult *result = AMcommit(doc, msg_span, time == R_NilValue ? NULL : &timestamp);

    // AMcommit returns VOID if there were no pending operations,
    // or CHANGE_HASH if changes were committed
    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error and free
    }

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
