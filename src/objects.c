#include "automerge.h"

// Type Conversion Helpers -----------------------------------------------------

/**
 * Convert R value to appropriate AMmapPut* or AMlistPut* call.
 * Handles type dispatch for scalar values.
 */
static AMresult* am_put_value(AMdoc* doc, const AMobjId* obj_id,
                               SEXP key_or_pos, bool is_map, SEXP value) {
    // Determine whether to insert (for lists)
    bool insert = false;
    size_t pos = 0;
    AMbyteSpan key = {.src = NULL, .count = 0};

    if (is_map) {
        // Map: key must be character string
        if (TYPEOF(key_or_pos) != STRSXP || Rf_length(key_or_pos) != 1) {
            Rf_error("Map key must be a single character string");
        }
        const char* key_str = CHAR(STRING_ELT(key_or_pos, 0));
        key.src = (uint8_t const*)key_str;
        key.count = strlen(key_str);
    } else {
        // List: position can be numeric or "end" marker
        if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
            if (Rf_length(key_or_pos) != 1) {
                Rf_error("List position must be a scalar");
            }
            // R uses 1-based indexing, C uses 0-based
            pos = (size_t)(Rf_asInteger(key_or_pos) - 1);
            insert = false;  // Replace at position
        } else if (TYPEOF(key_or_pos) == STRSXP && Rf_length(key_or_pos) == 1) {
            const char* pos_str = CHAR(STRING_ELT(key_or_pos, 0));
            if (strcmp(pos_str, "end") == 0) {
                pos = SIZE_MAX;  // Append at end
                insert = true;
            } else {
                Rf_error("List position must be numeric or \"end\"");
            }
        } else {
            Rf_error("List position must be numeric or \"end\"");
        }
    }

    // Dispatch based on R value type
    if (value == R_NilValue) {
        // NULL
        return is_map ? AMmapPutNull(doc, obj_id, key) :
                       AMlistPutNull(doc, obj_id, pos, insert);
    } else if (TYPEOF(value) == LGLSXP && Rf_length(value) == 1) {
        // Logical (boolean)
        bool val = (bool)LOGICAL(value)[0];
        return is_map ? AMmapPutBool(doc, obj_id, key, val) :
                       AMlistPutBool(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == INTSXP && Rf_length(value) == 1) {
        // Integer
        int64_t val = (int64_t)INTEGER(value)[0];
        return is_map ? AMmapPutInt(doc, obj_id, key, val) :
                       AMlistPutInt(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == REALSXP && Rf_length(value) == 1) {
        // Numeric (double)
        double val = REAL(value)[0];
        return is_map ? AMmapPutF64(doc, obj_id, key, val) :
                       AMlistPutF64(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == RAWSXP) {
        // Raw bytes
        AMbyteSpan val = {.src = RAW(value), .count = (size_t)Rf_length(value)};
        return is_map ? AMmapPutBytes(doc, obj_id, key, val) :
                       AMlistPutBytes(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == STRSXP && Rf_length(value) == 1) {
        // String - check if it's an object type constant first
        const char* str = CHAR(STRING_ELT(value, 0));

        // Check for object type creation
        if (strcmp(str, "list") == 0) {
            return is_map ? AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_LIST) :
                           AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_LIST);
        } else if (strcmp(str, "map") == 0) {
            return is_map ? AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_MAP) :
                           AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_MAP);
        } else if (strcmp(str, "text") == 0) {
            return is_map ? AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_TEXT) :
                           AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_TEXT);
        }

        // Regular string
        AMbyteSpan val = {.src = (uint8_t const*)str, .count = strlen(str)};
        return is_map ? AMmapPutStr(doc, obj_id, key, val) :
                       AMlistPutStr(doc, obj_id, pos, insert, val);
    } else {
        Rf_error("Unsupported value type for am_put()");
    }

    return NULL;  // Unreachable
}

/**
 * Convert AMitem to R value.
 * Handles type conversion from Automerge to R.
 */
static SEXP am_item_to_r(AMitem* item, SEXP parent_doc_sexp, SEXP parent_result_sexp) {
    AMvalType val_type = AMitemValType(item);

    switch (val_type) {
        case AM_VAL_TYPE_NULL:
            return R_NilValue;

        case AM_VAL_TYPE_BOOL: {
            bool val;
            if (!AMitemToBool(item, &val)) {
                Rf_error("Failed to extract boolean value");
            }
            SEXP result = PROTECT(Rf_allocVector(LGLSXP, 1));
            LOGICAL(result)[0] = val ? TRUE : FALSE;
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_INT: {
            int64_t val;
            if (!AMitemToInt(item, &val)) {
                Rf_error("Failed to extract integer value");
            }
            SEXP result = PROTECT(Rf_allocVector(INTSXP, 1));
            INTEGER(result)[0] = (int)val;
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_UINT: {
            uint64_t val;
            if (!AMitemToUint(item, &val)) {
                Rf_error("Failed to extract unsigned integer value");
            }
            SEXP result = PROTECT(Rf_allocVector(REALSXP, 1));
            REAL(result)[0] = (double)val;
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_F64: {
            double val;
            if (!AMitemToF64(item, &val)) {
                Rf_error("Failed to extract double value");
            }
            SEXP result = PROTECT(Rf_allocVector(REALSXP, 1));
            REAL(result)[0] = val;
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_STR: {
            AMbyteSpan val;
            if (!AMitemToStr(item, &val)) {
                Rf_error("Failed to extract string value");
            }
            SEXP result = PROTECT(Rf_allocVector(STRSXP, 1));
            SET_STRING_ELT(result, 0, Rf_mkCharLen((const char*)val.src, val.count));
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_BYTES: {
            AMbyteSpan val;
            if (!AMitemToBytes(item, &val)) {
                Rf_error("Failed to extract bytes value");
            }
            SEXP result = PROTECT(Rf_allocVector(RAWSXP, val.count));
            memcpy(RAW(result), val.src, val.count);
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_TIMESTAMP: {
            int64_t val;
            if (!AMitemToTimestamp(item, &val)) {
                Rf_error("Failed to extract timestamp value");
            }
            // Convert milliseconds to seconds for POSIXct
            SEXP result = PROTECT(Rf_allocVector(REALSXP, 1));
            REAL(result)[0] = (double)val / 1000.0;
            Rf_classgets(result, Rf_mkString("POSIXct"));
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_COUNTER: {
            int64_t val;
            if (!AMitemToCounter(item, &val)) {
                Rf_error("Failed to extract counter value");
            }
            SEXP result = PROTECT(Rf_allocVector(INTSXP, 1));
            INTEGER(result)[0] = (int)val;
            Rf_setAttrib(result, Rf_install("class"), Rf_mkString("am_counter"));
            UNPROTECT(1);
            return result;
        }

        case AM_VAL_TYPE_OBJ_TYPE: {
            // Nested object - return am_object wrapper
            AMobjId const* obj_id = AMitemObjId(item);
            return am_wrap_nested_object(obj_id, parent_result_sexp);
        }

        default:
            Rf_error("Unsupported Automerge value type: %d", val_type);
    }

    return R_NilValue;  // Unreachable
}

// Object Operations -----------------------------------------------------------

/**
 * Put a value into a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param key_or_pos For maps: character key. For lists: numeric position or "end"
 * @param value R value to insert
 * @return The document pointer (for chaining)
 */
SEXP C_am_put(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos, SEXP value) {
    AMdoc* doc = get_doc(doc_ptr);
    const AMobjId* obj_id = get_objid(obj_ptr);

    // Determine if this is a map or list
    bool is_map;
    if (obj_id == NULL) {
        // Root is always a map
        is_map = true;
    } else {
        // Get object type directly
        AMobjType obj_type = AMobjObjType(doc, obj_id);
        is_map = (obj_type == AM_OBJ_TYPE_MAP);
    }

    // Perform the put operation
    AMresult* result = am_put_value(doc, obj_id, key_or_pos, is_map, value);

    // Check if result contains an object ID (creating nested object)
    if (AMresultStatus(result) == AM_STATUS_OK) {
        AMitem* item = AMresultItem(result);
        if (item && AMitemValType(item) == AM_VAL_TYPE_OBJ_TYPE) {
            // Creating a nested object - wrap and return it
            SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
            AMobjId const* new_obj_id = AMitemObjId(item);
            SEXP wrapped_obj = PROTECT(am_wrap_nested_object(new_obj_id, result_sexp));
            UNPROTECT(2);
            return wrapped_obj;
        }
    }

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;  // Return document for chaining
}

/**
 * Get a value from a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param key_or_pos For maps: character key. For lists: numeric position (1-based)
 * @return R value
 */
SEXP C_am_get(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos) {
    AMdoc* doc = get_doc(doc_ptr);
    const AMobjId* obj_id = get_objid(obj_ptr);

    AMresult* result;

    // Dispatch based on key type
    if (TYPEOF(key_or_pos) == STRSXP && Rf_length(key_or_pos) == 1) {
        // Map get
        const char* key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const*)key_str, .count = strlen(key_str)};
        result = AMmapGet(doc, obj_id, key, NULL);  // NULL = current heads
    } else if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
        // List get
        if (Rf_length(key_or_pos) != 1) {
            Rf_error("List position must be a scalar");
        }
        size_t pos = (size_t)(Rf_asInteger(key_or_pos) - 1);  // Convert to 0-based
        result = AMlistGet(doc, obj_id, pos, NULL);  // NULL = current heads
    } else {
        Rf_error("Key must be a character string (map) or numeric (list)");
    }

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error
    }

    // Check if value exists
    AMitem* item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        return R_NilValue;  // Key/position not found
    }

    // Check if the item type is VOID (means key/position doesn't exist)
    AMvalType val_type = AMitemValType(item);
    if (val_type == AM_VAL_TYPE_VOID || val_type == 0 || val_type == 1) {
        AMresultFree(result);
        return R_NilValue;  // Key/position not found
    }

    // Wrap result for memory management
    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));

    // Convert to R value
    SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));

    UNPROTECT(2);
    return r_value;
}

/**
 * Delete a key from a map or position from a list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param key_or_pos For maps: character key. For lists: numeric position (1-based)
 * @return The document pointer (for chaining)
 */
SEXP C_am_delete(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos) {
    AMdoc* doc = get_doc(doc_ptr);
    const AMobjId* obj_id = get_objid(obj_ptr);

    AMresult* result;

    // Dispatch based on key type
    if (TYPEOF(key_or_pos) == STRSXP && Rf_length(key_or_pos) == 1) {
        // Map delete
        const char* key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const*)key_str, .count = strlen(key_str)};
        result = AMmapDelete(doc, obj_id, key);
    } else if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
        // List delete
        if (Rf_length(key_or_pos) != 1) {
            Rf_error("List position must be a scalar");
        }
        size_t pos = (size_t)(Rf_asInteger(key_or_pos) - 1);  // Convert to 0-based
        result = AMlistDelete(doc, obj_id, pos);
    } else {
        Rf_error("Key must be a character string (map) or numeric (list)");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;  // Return document for chaining
}

/**
 * Get all keys from a map.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @return Character vector of keys
 */
SEXP C_am_keys(SEXP doc_ptr, SEXP obj_ptr) {
    AMdoc* doc = get_doc(doc_ptr);
    const AMobjId* obj_id = get_objid(obj_ptr);

    AMresult* result = AMkeys(doc, obj_id, NULL);  // NULL = current heads

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error
    }

    // Count keys
    AMitems items = AMresultItems(result);
    size_t count = 0;
    AMitem* item;
    while ((item = AMitemsNext(&items, 1)) != NULL) {
        count++;
    }

    // Allocate R character vector
    SEXP keys = PROTECT(Rf_allocVector(STRSXP, count));

    // Reset iterator and populate
    items = AMresultItems(result);
    size_t i = 0;
    while ((item = AMitemsNext(&items, 1)) != NULL) {
        AMbyteSpan key_span;
        if (AMitemToStr(item, &key_span)) {
            SET_STRING_ELT(keys, i, Rf_mkCharLen((const char*)key_span.src, key_span.count));
            i++;
        }
    }

    AMresultFree(result);
    UNPROTECT(1);
    return keys;
}

/**
 * Get the length/size of a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @return Integer length
 */
SEXP C_am_length(SEXP doc_ptr, SEXP obj_ptr) {
    AMdoc* doc = get_doc(doc_ptr);
    const AMobjId* obj_id = get_objid(obj_ptr);

    size_t size = AMobjSize(doc, obj_id, NULL);  // NULL = current heads

    SEXP result = PROTECT(Rf_allocVector(INTSXP, 1));
    INTEGER(result)[0] = (int)size;
    UNPROTECT(1);
    return result;
}

/**
 * Insert a value into a list at a specific position.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (must be a list)
 * @param pos Numeric position (1-based, or use "end" via am_put)
 * @param value R value to insert
 * @return The document pointer (for chaining)
 */
SEXP C_am_insert(SEXP doc_ptr, SEXP obj_ptr, SEXP pos, SEXP value) {
    // am_insert is just am_put with insert=true for lists
    // We'll use the same implementation
    return C_am_put(doc_ptr, obj_ptr, pos, value);
}
