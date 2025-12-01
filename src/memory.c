#include "automerge.h"

// Finalizers ------------------------------------------------------------------

/**
 * Finalizer for AMdoc external pointer.
 * Frees the owning AMresult*, which automatically frees the borrowed AMdoc*.
 */
void am_doc_finalizer(SEXP ext_ptr) {
    am_doc *doc_wrapper = (am_doc *) R_ExternalPtrAddr(ext_ptr);
    if (doc_wrapper) {
        if (doc_wrapper->result) {
            AMresultFree(doc_wrapper->result);
            doc_wrapper->result = NULL;
        }
        // doc pointer is borrowed from result, freed automatically above
        free(doc_wrapper); 
    }
    R_ClearExternalPtr(ext_ptr);
}

/**
 * Finalizer for AMresult external pointer.
 * AMresult* is wrapped directly (not in a struct).
 */
void am_result_finalizer(SEXP ext_ptr) {
    AMresult *result = (AMresult *) R_ExternalPtrAddr(ext_ptr);
    if (result) {
        AMresultFree(result);
    }
    R_ClearExternalPtr(ext_ptr);
}

/**
 * Finalizer for AMsyncState external pointer.
 * Frees the owning AMresult*, which automatically frees the borrowed state pointer.
 */
void am_syncstate_finalizer(SEXP ext_ptr) {
    am_syncstate *sync_state = (am_syncstate *) R_ExternalPtrAddr(ext_ptr);
    if (sync_state) {
        if (sync_state->result) {
            AMresultFree(sync_state->result);
            sync_state->result = NULL;
        }
        // state pointer is borrowed from result, freed automatically above
        free(sync_state);
    }
    R_ClearExternalPtr(ext_ptr);
}

// Helper Functions ------------------------------------------------------------

/**
 * Get AMdoc* from external pointer with validation.
 * Returns the borrowed AMdoc* pointer, not the wrapper.
 */
AMdoc *get_doc(SEXP doc_ptr) {
    if (TYPEOF(doc_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for document");
    }
    am_doc *doc_wrapper = (am_doc *) R_ExternalPtrAddr(doc_ptr);
    if (!doc_wrapper || !doc_wrapper->doc) {
        Rf_error("Invalid document pointer (NULL or freed)");
    }
    return doc_wrapper->doc;
}

/**
 * Get AMobjId* from external pointer.
 * Handles NULL (which represents AM_ROOT).
 */
const AMobjId *get_objid(SEXP obj_ptr) {
    if (obj_ptr == R_NilValue) {
        return NULL;  // AM_ROOT
    }
    if (TYPEOF(obj_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for object ID");
    }
    const AMobjId *obj_id = (const AMobjId *) R_ExternalPtrAddr(obj_ptr);
    if (!obj_id) {
        Rf_error("Invalid object ID pointer (NULL or freed)");
    }
    return obj_id;
}

/**
 * Get document external pointer from am_object (obj_id external pointer).
 * Extracts the doc from the protection chain: obj_id -> result -> doc.
 *
 * @param obj_ptr External pointer to AMobjId (with am_object class)
 * @return SEXP external pointer to am_doc
 */
SEXP get_doc_from_objid(SEXP obj_ptr) {
    if (TYPEOF(obj_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for am_object");
    }

    SEXP result_ptr = R_ExternalPtrProtected(obj_ptr);
    if (!result_ptr || result_ptr == R_NilValue) {
        Rf_error("Invalid am_object: no parent result in protection chain");
    }

    SEXP doc_ptr = R_ExternalPtrProtected(result_ptr);
    if (!doc_ptr || doc_ptr == R_NilValue) {
        Rf_error("Invalid am_object: no parent document in protection chain");
    }

    return doc_ptr;
}

/**
 * C wrapper for R .Call() interface.
 * Exports get_doc_from_objid for use in R code.
 */
SEXP C_get_doc_from_objid(SEXP obj_ptr) {
    return get_doc_from_objid(obj_ptr);
}

/**
 * Wrap AMresult* as R external pointer with parent document protection.
 * Uses EXTPTR_PROT to keep parent document alive.
 *
 * @param result The AMresult* to wrap (ownership transferred)
 * @param parent_doc_sexp The external pointer to the parent document (or R_NilValue)
 * @return SEXP external pointer to the result
 */
SEXP wrap_am_result(AMresult *result, SEXP parent_doc_sexp) {
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(result, R_NilValue, parent_doc_sexp));
    R_RegisterCFinalizer(ext_ptr, am_result_finalizer);
    Rf_classgets(ext_ptr, Rf_mkString("am_result"));
    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Wrap AMobjId* as R external pointer with parent result protection.
 * The obj_id pointer is borrowed from the result and must stay alive.
 *
 * @param obj_id The AMobjId* to wrap (borrowed, not owned)
 * @param parent_result_sexp The external pointer wrapping the owning AMresult*
 * @return SEXP external pointer to the object ID
 */
SEXP am_wrap_objid(const AMobjId *obj_id, SEXP parent_result_sexp) {
    if (!obj_id) return R_NilValue;

    // No finalizer needed - obj_id is borrowed, parent will free it
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr((void *) obj_id, R_NilValue, parent_result_sexp));
    Rf_classgets(ext_ptr, Rf_mkString("am_objid"));
    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Wrap nested object as am_object S3 class.
 * Returns an external pointer to AMobjId with appropriate class.
 * The class vector includes the specific type (am_map, am_list, or am_text)
 * followed by the base class am_object.
 *
 * The parent document is preserved through the protection chain:
 * obj_id_ptr -> result_ptr -> doc_ptr
 *
 * @param obj_id The AMobjId* for the nested object (borrowed)
 * @param parent_result_sexp The external pointer wrapping the owning AMresult*
 * @return SEXP am_object S3 class (external pointer to AMobjId)
 */
SEXP am_wrap_nested_object(const AMobjId *obj_id, SEXP parent_result_sexp) {
    if (!obj_id) return R_NilValue;

    SEXP parent_doc_sexp = R_ExternalPtrProtected(parent_result_sexp);

    SEXP obj_id_ptr = PROTECT(am_wrap_objid(obj_id, parent_result_sexp));

    AMdoc *doc = get_doc(parent_doc_sexp);
    AMobjType obj_type = AMobjObjType(doc, obj_id);

    SEXP classes = Rf_allocVector(STRSXP, 2);
    Rf_classgets(obj_id_ptr, classes);
    switch(obj_type) {
        case AM_OBJ_TYPE_MAP:
            SET_STRING_ELT(classes, 0, Rf_mkChar("am_map"));
            break;
        case AM_OBJ_TYPE_LIST:
            SET_STRING_ELT(classes, 0, Rf_mkChar("am_list"));
            break;
        case AM_OBJ_TYPE_TEXT:
            SET_STRING_ELT(classes, 0, Rf_mkChar("am_text"));
            break;
        default:
            SET_STRING_ELT(classes, 0, Rf_mkChar("am_unknown"));
            break;
    }
    SET_STRING_ELT(classes, 1, Rf_mkChar("am_object"));

    UNPROTECT(1);
    return obj_id_ptr;
}
