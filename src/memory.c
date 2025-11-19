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
            AMresultFree(doc_wrapper->result);  // Free the owning result
            doc_wrapper->result = NULL;
        }
        // Note: doc pointer is borrowed from result, freed automatically above
        free(doc_wrapper);  // Free the wrapper struct
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
            AMresultFree(sync_state->result);  // Frees the owning result
            sync_state->result = NULL;
        }
        // Note: state pointer is borrowed from result, freed automatically above
        free(sync_state);  // Free the wrapper struct
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
    return doc_wrapper->doc;  // Return borrowed AMdoc*
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
    return (const AMobjId *) R_ExternalPtrAddr(obj_ptr);
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
    Rf_setAttrib(ext_ptr, Rf_install("class"), Rf_mkString("am_result"));
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

    // Wrap AMobjId* directly, use EXTPTR_PROT to keep parent result alive
    // No finalizer needed - obj_id is borrowed, parent will free it
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr((void *) obj_id, R_NilValue, parent_result_sexp));
    Rf_setAttrib(ext_ptr, Rf_install("class"), Rf_mkString("am_objid"));
    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Wrap nested object as am_object S3 class.
 * Returns a list with 'doc' and 'obj_id' elements.
 *
 * @param obj_id The AMobjId* for the nested object (borrowed)
 * @param parent_result_sexp The external pointer wrapping the owning AMresult*
 * @return SEXP am_object S3 class (list with doc and obj_id)
 */
SEXP am_wrap_nested_object(const AMobjId *obj_id, SEXP parent_result_sexp) {
    if (!obj_id) return R_NilValue;

    // Get the document from the result's parent (stored in EXTPTR_PROT)
    SEXP parent_doc_sexp = R_ExternalPtrProtected(parent_result_sexp);

    // Wrap the AMobjId* as external pointer
    SEXP obj_id_ptr = PROTECT(am_wrap_objid(obj_id, parent_result_sexp));

    // Create am_object S3 class as a list with doc and obj_id elements
    SEXP am_obj = PROTECT(Rf_allocVector(VECSXP, 2));
    SET_VECTOR_ELT(am_obj, 0, parent_doc_sexp);
    SET_VECTOR_ELT(am_obj, 1, obj_id_ptr);

    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(names, 0, Rf_mkChar("doc"));
    SET_STRING_ELT(names, 1, Rf_mkChar("obj_id"));
    Rf_namesgets(am_obj, names);

    Rf_classgets(am_obj, Rf_mkString("am_object"));

    UNPROTECT(3);
    return am_obj;
}
