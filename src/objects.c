#include "automerge.h"

// Forward declarations --------------------------------------------------------

static void populate_object_from_r_list(AMdoc *doc, const AMobjId *obj_id,
                                         SEXP r_list, AMresult *parent_result);

// Type Conversion Helpers -----------------------------------------------------

/**
 * Convert R value to appropriate AMmapPut* or AMlistPut* call.
 * Handles type dispatch for scalar values and recursive conversion.
 */
static AMresult *am_put_value(AMdoc *doc, const AMobjId *obj_id,
                               SEXP key_or_pos, bool is_map, SEXP value, bool force_insert) {
    // Determine whether to insert (for lists)
    bool insert = false;
    size_t pos = 0;
    AMbyteSpan key = {.src = NULL, .count = 0};

    if (is_map) {
        // Map: key must be character string
        if (TYPEOF(key_or_pos) != STRSXP || XLENGTH(key_or_pos) != 1) {
            Rf_error("Map key must be a single character string");
        }
        const char* key_str = CHAR(STRING_ELT(key_or_pos, 0));
        key.src = (uint8_t const *) key_str;
        key.count = strlen(key_str);
    } else {
        // List: position can be numeric or "end" marker
        if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
            if (XLENGTH(key_or_pos) != 1) {
                Rf_error("List position must be a scalar");
            }
            // R uses 1-based indexing, C uses 0-based
            int r_pos = Rf_asInteger(key_or_pos);
            if (r_pos < 1) {
                Rf_error("List position must be positive");
            }
            pos = (size_t)(r_pos - 1);
            insert = force_insert;  // Use caller's preference for insert vs replace
        } else if (TYPEOF(key_or_pos) == STRSXP && XLENGTH(key_or_pos) == 1) {
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
    // NOTE: Check S3 classes BEFORE generic TYPEOF checks since POSIXct is REALSXP and am_counter is INTSXP
    if (value == R_NilValue) {
        // NULL
        return is_map ? AMmapPutNull(doc, obj_id, key) :
                       AMlistPutNull(doc, obj_id, pos, insert);
    } else if (Rf_inherits(value, "POSIXct")) {
        // POSIXct timestamp - convert to milliseconds (must check before REALSXP)
        if (Rf_xlength(value) != 1) {
            Rf_error("Timestamp must be scalar");
        }
        double seconds = Rf_asReal(value);
        int64_t milliseconds = (int64_t)(seconds * 1000.0);
        return is_map ? AMmapPutTimestamp(doc, obj_id, key, milliseconds) :
                       AMlistPutTimestamp(doc, obj_id, pos, insert, milliseconds);
    } else if (Rf_inherits(value, "am_counter")) {
        // Counter type (must check before INTSXP)
        if (TYPEOF(value) != INTSXP || XLENGTH(value) != 1) {
            Rf_error("Counter must be a scalar integer");
        }
        int64_t val = (int64_t) INTEGER(value)[0];
        return is_map ? AMmapPutCounter(doc, obj_id, key, val) :
                       AMlistPutCounter(doc, obj_id, pos, insert, val);
    } else if (Rf_inherits(value, "am_text_type")) {
        // Text object with initial content (must check before STRSXP)
        if (TYPEOF(value) != STRSXP || XLENGTH(value) != 1) {
            Rf_error("am_text must be a single character string");
        }

        // Create text object
        AMresult *text_result = is_map ?
            AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_TEXT) :
            AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_TEXT);

        CHECK_RESULT(text_result, AM_VAL_TYPE_OBJ_TYPE);

        // Get the text object ID
        AMitem *text_item = AMresultItem(text_result);
        const AMobjId *text_obj = AMitemObjId(text_item);

        // Get initial string content
        const char *initial = CHAR(STRING_ELT(value, 0));
        size_t initial_len = strlen(initial);

        if (initial_len > 0) {
            // Insert initial text at position 0
            AMbyteSpan str_span = {.src = (uint8_t const *) initial, .count = initial_len};
            AMresult *splice_result = AMspliceText(doc, text_obj, 0, 0, str_span);
            if (AMresultStatus(splice_result) != AM_STATUS_OK) {
                AMresultFree(text_result);
                CHECK_RESULT(splice_result, AM_VAL_TYPE_VOID);
            }
            AMresultFree(splice_result);
        }

        return text_result;
    } else if (TYPEOF(value) == LGLSXP && XLENGTH(value) == 1) {
        // Logical (boolean)
        bool val = (bool) LOGICAL(value)[0];
        return is_map ? AMmapPutBool(doc, obj_id, key, val) :
                       AMlistPutBool(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == INTSXP && XLENGTH(value) == 1) {
        // Integer
        int64_t val = (int64_t) INTEGER(value)[0];
        return is_map ? AMmapPutInt(doc, obj_id, key, val) :
                       AMlistPutInt(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == REALSXP && XLENGTH(value) == 1) {
        // Numeric (double)
        double val = REAL(value)[0];
        return is_map ? AMmapPutF64(doc, obj_id, key, val) :
                       AMlistPutF64(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == RAWSXP) {
        // Raw bytes
        AMbyteSpan val = {.src = RAW(value), .count = (size_t) XLENGTH(value)};
        return is_map ? AMmapPutBytes(doc, obj_id, key, val) :
                       AMlistPutBytes(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == VECSXP) {
        // R list - handle recursive conversion or explicit type markers

        // Determine nested object type
        AMobjType nested_type;

        if (Rf_inherits(value, "am_list_type")) {
            // Explicit list type
            nested_type = AM_OBJ_TYPE_LIST;
        } else if (Rf_inherits(value, "am_map_type")) {
            // Explicit map type
            nested_type = AM_OBJ_TYPE_MAP;
        } else {
            // Auto-detect: named list = map, unnamed list = list
            SEXP names = Rf_getAttrib(value, R_NamesSymbol);
            nested_type = (names == R_NilValue) ? AM_OBJ_TYPE_LIST : AM_OBJ_TYPE_MAP;
        }

        // Create nested object
        AMresult *obj_result = is_map ?
            AMmapPutObject(doc, obj_id, key, nested_type) :
            AMlistPutObject(doc, obj_id, pos, insert, nested_type);

        CHECK_RESULT(obj_result, AM_VAL_TYPE_OBJ_TYPE);

        // Recursively populate nested object from R list
        AMitem *obj_item = AMresultItem(obj_result);
        const AMobjId *nested_obj = AMitemObjId(obj_item);
        populate_object_from_r_list(doc, nested_obj, value, obj_result);

        return obj_result;
    } else if (TYPEOF(value) == STRSXP && XLENGTH(value) == 1) {
        // String - check if it's an object type constant first
        const char *str = CHAR(STRING_ELT(value, 0));

        // Check for object type creation constants (have "am_obj_type" class)
        if (Rf_inherits(value, "am_obj_type")) {
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
        }

        // Regular string value
        AMbyteSpan val = {.src = (uint8_t const *) str, .count = strlen(str)};
        return is_map ? AMmapPutStr(doc, obj_id, key, val) :
                       AMlistPutStr(doc, obj_id, pos, insert, val);
    } else {
        Rf_error("Unsupported value type for am_put()");
    }

    return NULL;  // Unreachable
}

/**
 * Recursively populate Automerge object from R list.
 *
 * This enables single-call nested object creation:
 *   am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L,
 *                                     address = list(city = "NYC")))
 *
 * @param doc The Automerge document
 * @param obj_id The object to populate (must be a list or map)
 * @param r_list The R list with content
 * @param parent_result The AMresult* that owns this object (freed on error)
 */
static void populate_object_from_r_list(AMdoc *doc, const AMobjId *obj_id,
                                         SEXP r_list, AMresult *parent_result) {
    if (TYPEOF(r_list) != VECSXP) {
        if (parent_result) AMresultFree(parent_result);
        Rf_error("Expected R list for nested object population");
    }

    // Determine if this is a map or list
    SEXP names = Rf_getAttrib(r_list, R_NamesSymbol);
    bool is_map = (names != R_NilValue);

    R_xlen_t n = Rf_xlength(r_list);

    for (R_xlen_t i = 0; i < n; i++) {
        SEXP elem = VECTOR_ELT(r_list, i);

        if (is_map) {
            // Map: use names as keys
            // Create a temporary key SEXP for the call
            SEXP key_sexp = PROTECT(Rf_ScalarString(STRING_ELT(names, i)));

            AMresult *result = am_put_value(doc, obj_id, key_sexp, true, elem, false);
            if (result) {
                if (AMresultStatus(result) != AM_STATUS_OK) {
                    if (parent_result) AMresultFree(parent_result);
                    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
                }
                AMresultFree(result);
            }

            UNPROTECT(1);
        } else {
            // List: use position with "end" marker for append
            SEXP end_marker = PROTECT(Rf_mkString("end"));

            AMresult *result = am_put_value(doc, obj_id, end_marker, false, elem, false);
            if (result) {
                if (AMresultStatus(result) != AM_STATUS_OK) {
                    if (parent_result) AMresultFree(parent_result);
                    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
                }
                AMresultFree(result);
            }

            UNPROTECT(1);
        }
    }
}

/**
 * Convert AMitem to R value.
 * Handles type conversion from Automerge to R.
 */
static SEXP am_item_to_r(AMitem *item, SEXP parent_doc_sexp, SEXP parent_result_sexp) {
    AMvalType val_type = AMitemValType(item);
    SEXP result;

    switch (val_type) {
        case AM_VAL_TYPE_NULL:
            result = R_NilValue;
            break;

        case AM_VAL_TYPE_BOOL: {
            bool val;
            if (!AMitemToBool(item, &val)) {
                Rf_error("Failed to extract boolean value");
            }
            result = Rf_ScalarLogical(val);
            break;
        }

        case AM_VAL_TYPE_INT: {
            int64_t val;
            if (!AMitemToInt(item, &val)) {
                Rf_error("Failed to extract integer value");
            }
            result = val > INT_MAX || val < INT_MIN ?
                Rf_ScalarReal((double) val):
                Rf_ScalarInteger((int) val);
            break;
        }

        case AM_VAL_TYPE_UINT: {
            uint64_t val;
            if (!AMitemToUint(item, &val)) {
                Rf_error("Failed to extract unsigned integer value");
            }
            result = Rf_ScalarReal((double) val);
            break;
        }

        case AM_VAL_TYPE_F64: {
            double val;
            if (!AMitemToF64(item, &val)) {
                Rf_error("Failed to extract double value");
            }
            result = Rf_ScalarReal(val);
            break;
        }

        case AM_VAL_TYPE_STR: {
            AMbyteSpan val;
            if (!AMitemToStr(item, &val)) {
                Rf_error("Failed to extract string value");
            }
            result = Rf_ScalarString(Rf_mkCharLen((const char *) val.src, val.count));
            break;
        }

        case AM_VAL_TYPE_BYTES: {
            AMbyteSpan val;
            if (!AMitemToBytes(item, &val)) {
                Rf_error("Failed to extract bytes value");
            }
            result = PROTECT(Rf_allocVector(RAWSXP, val.count));
            memcpy(RAW(result), val.src, val.count);
            UNPROTECT(1);
            break;
        }

        case AM_VAL_TYPE_TIMESTAMP: {
            int64_t val;
            if (!AMitemToTimestamp(item, &val)) {
                Rf_error("Failed to extract timestamp value");
            }
            // Convert milliseconds to seconds for POSIXct
            result = PROTECT(Rf_ScalarReal((double) val / 1000.0));

            // Set POSIXct class (requires both "POSIXct" and "POSIXt")
            SEXP classes = PROTECT(Rf_allocVector(STRSXP, 2));
            SET_STRING_ELT(classes, 0, Rf_mkChar("POSIXct"));
            SET_STRING_ELT(classes, 1, Rf_mkChar("POSIXt"));
            Rf_classgets(result, classes);

            UNPROTECT(2);
            break;
        }

        case AM_VAL_TYPE_COUNTER: {
            int64_t val;
            if (!AMitemToCounter(item, &val)) {
                Rf_error("Failed to extract counter value");
            }
            result = val > INT_MAX || val < INT_MIN ?
                Rf_ScalarReal((double) val):
                Rf_ScalarInteger((int) val);
            Rf_setAttrib(result, Rf_install("class"), Rf_mkString("am_counter"));
            break;
        }

        case AM_VAL_TYPE_OBJ_TYPE: {
            // Nested object - return am_object wrapper
            AMobjId const *obj_id = AMitemObjId(item);
            result = am_wrap_nested_object(obj_id, parent_result_sexp);
            break;
        }

        default:
            Rf_error("Unsupported Automerge value type: %d", val_type);
            result = R_NilValue; // unreachable
    }

    return result;
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
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

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

    // Perform the put operation (insert=false means replace for numeric positions)
    AMresult *result = am_put_value(doc, obj_id, key_or_pos, is_map, value, false);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;  // Always return document for consistency
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
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *result;

    // Dispatch based on key type
    if (TYPEOF(key_or_pos) == STRSXP && XLENGTH(key_or_pos) == 1) {
        // Map get
        const char *key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const *) key_str, .count = strlen(key_str)};
        result = AMmapGet(doc, obj_id, key, NULL);  // NULL = current heads
    } else if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
        // List get
        if (XLENGTH(key_or_pos) != 1) {
            Rf_error("List position must be a scalar");
        }
        int r_pos = Rf_asInteger(key_or_pos);
        if (r_pos < 1) {
            return R_NilValue;  // Out-of-bounds list index
        }
        size_t pos = (size_t)(r_pos - 1);  // Convert to 0-based
        result = AMlistGet(doc, obj_id, pos, NULL);  // NULL = current heads
    } else {
        Rf_error("Key must be a character string (map) or numeric (list)");
    }

    // Check status - for lists, out-of-bounds returns error, but we want to return NULL
    if (AMresultStatus(result) != AM_STATUS_OK) {
        // For list operations, check if it's an out-of-bounds error
        if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
            AMresultFree(result);
            return R_NilValue;  // Out-of-bounds list index
        }
        // For maps or other errors, propagate the error
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error
    }

    // Check if value exists
    AMitem *item = AMresultItem(result);
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
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *result;

    // Dispatch based on key type
    if (TYPEOF(key_or_pos) == STRSXP && XLENGTH(key_or_pos) == 1) {
        // Map delete
        const char *key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const *) key_str, .count = strlen(key_str)};
        result = AMmapDelete(doc, obj_id, key);
    } else if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
        // List delete
        if (XLENGTH(key_or_pos) != 1) {
            Rf_error("List position must be a scalar");
        }
        int r_pos = Rf_asInteger(key_or_pos);
        if (r_pos < 1) {
            Rf_error("List position must be positive");
        }
        size_t pos = (size_t)(r_pos - 1);  // Convert to 0-based
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
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *result = AMkeys(doc, obj_id, NULL);  // NULL = current heads

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error
    }

    // Count keys
    AMitems items = AMresultItems(result);
    size_t count = 0;
    AMitem *item;
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
            SET_STRING_ELT(keys, i, Rf_mkCharLen((const char *) key_span.src, key_span.count));
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
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    size_t size = AMobjSize(doc, obj_id, NULL);  // NULL = current heads

    if (size > INT_MAX) {
        return Rf_ScalarReal((double) size);
    } else {
        SEXP result = PROTECT(Rf_allocVector(INTSXP, 1));
        INTEGER(result)[0] = (int) size;
        UNPROTECT(1);
        return result;
    }
}

/**
 * Insert a value into a list at a specific position.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (must be a list)
 * @param pos Numeric position (1-based) or "end" string
 * @param value R value to insert
 * @return The document pointer (for chaining)
 */
SEXP C_am_insert(SEXP doc_ptr, SEXP obj_ptr, SEXP pos, SEXP value) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    // Verify this is a list object
    AMobjType obj_type = AMobjObjType(doc, obj_id);
    if (obj_type != AM_OBJ_TYPE_LIST) {
        Rf_error("am_insert() can only be used on list objects");
    }

    // Perform the insert operation (insert=true means insert/shift for numeric positions)
    AMresult *result = am_put_value(doc, obj_id, pos, false, value, true);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;  // Return document for chaining
}

/**
 * Splice text in a text object.
 *
 * @param text_ptr External pointer to AMobjId (must be a text object)
 * @param pos Numeric position (0-based for text operations)
 * @param del_count Number of characters to delete
 * @param text Character string to insert
 * @return The text object pointer (for chaining)
 */
SEXP C_am_text_splice(SEXP text_ptr, SEXP pos, SEXP del_count, SEXP text) {
    SEXP doc_ptr = get_doc_from_objid(text_ptr);
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *text_obj = get_objid(text_ptr);

    if (TYPEOF(pos) != INTSXP && TYPEOF(pos) != REALSXP) {
        Rf_error("pos must be numeric");
    }
    if (TYPEOF(del_count) != INTSXP && TYPEOF(del_count) != REALSXP) {
        Rf_error("del_count must be numeric");
    }
    if (TYPEOF(text) != STRSXP || XLENGTH(text) != 1) {
        Rf_error("text must be a single character string");
    }

    int r_pos = Rf_asInteger(pos);
    if (r_pos < 0) {
        Rf_error("pos must be non-negative");
    }
    int r_del = Rf_asInteger(del_count);
    if (r_del < 0) {
        Rf_error("del_count must be non-negative");
    }
    size_t pos_val = (size_t) r_pos;
    size_t del_val = (size_t) r_del;
    const char *text_str = CHAR(STRING_ELT(text, 0));

    AMbyteSpan text_span = {.src = (uint8_t const *) text_str, .count = strlen(text_str)};
    AMresult *result = AMspliceText(doc, text_obj, pos_val, del_val, text_span);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return text_ptr;  // Return text object for chaining
}

/**
 * Get the full text content from a text object.
 *
 * @param text_ptr External pointer to AMobjId (must be a text object)
 * @return Character string with the full text content
 */
SEXP C_am_text_get(SEXP text_ptr) {
    SEXP doc_ptr = get_doc_from_objid(text_ptr);
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *text_obj = get_objid(text_ptr);

    AMresult *result = AMtext(doc, text_obj, NULL);  // NULL = current heads

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);  // Will error
    }

    // Get string from result item
    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        return Rf_mkString("");
    }

    AMbyteSpan text_span;
    if (!AMitemToStr(item, &text_span)) {
        AMresultFree(result);
        Rf_error("Failed to extract text string");
    }

    SEXP text_sexp = Rf_ScalarString(Rf_mkCharLen((const char *) text_span.src, text_span.count));

    AMresultFree(result);
    return text_sexp;
}

/**
 * Get all values from a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @return R list of values
 */
SEXP C_am_values(SEXP doc_ptr, SEXP obj_ptr) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    // Determine object type
    AMobjType obj_type = obj_id ? AMobjObjType(doc, obj_id) : AM_OBJ_TYPE_MAP;
    bool is_list = (obj_type == AM_OBJ_TYPE_LIST);

    // Get size
    size_t count = AMobjSize(doc, obj_id, NULL);

    // Allocate R list
    SEXP values = PROTECT(Rf_allocVector(VECSXP, count));

    if (is_list) {
        // For lists, iterate by position
        for (size_t i = 0; i < count; i++) {
            AMresult *result = AMlistGet(doc, obj_id, i, NULL);
            if (AMresultStatus(result) == AM_STATUS_OK) {
                AMitem *item = AMresultItem(result);
                if (item) {
                    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
                    SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
                    SET_VECTOR_ELT(values, i, r_value);
                    UNPROTECT(2);
                } else {
                    AMresultFree(result);
                }
            } else {
                AMresultFree(result);
            }
        }
    } else {
        // For maps, iterate by keys
        AMresult *keys_result = AMkeys(doc, obj_id, NULL);
        if (AMresultStatus(keys_result) != AM_STATUS_OK) {
            AMresultFree(keys_result);
            UNPROTECT(1);
            Rf_error("Failed to get keys");
        }

        AMitems key_items = AMresultItems(keys_result);
        AMitem *key_item;
        size_t i = 0;

        while ((key_item = AMitemsNext(&key_items, 1)) != NULL && i < count) {
            AMbyteSpan key_span;
            if (AMitemToStr(key_item, &key_span)) {
                AMresult *result = AMmapGet(doc, obj_id, key_span, NULL);
                if (AMresultStatus(result) == AM_STATUS_OK) {
                    AMitem *item = AMresultItem(result);
                    if (item) {
                        SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
                        SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
                        SET_VECTOR_ELT(values, i, r_value);
                        UNPROTECT(2);
                    } else {
                        AMresultFree(result);
                    }
                } else {
                    AMresultFree(result);
                }
                i++;
            }
        }

        AMresultFree(keys_result);
    }

    UNPROTECT(1);
    return values;
}

/**
 * Increment a counter value
 *
 * @param doc_ptr External pointer to AMdoc
 * @param obj_ptr External pointer to AMobjId (or R_NilValue for AM_ROOT)
 * @param key_or_pos Character string (map) or integer position (list, 1-based)
 * @param delta Integer value to increment by (can be negative)
 * @return The document (invisibly)
 */
SEXP C_am_counter_increment(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos, SEXP delta) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);
    if (TYPEOF(delta) != INTSXP && TYPEOF(delta) != REALSXP) {
        Rf_error("Delta must be numeric");
    }
    if (XLENGTH(delta) != 1) {
        Rf_error("Delta must be scalar");
    }
    int64_t delta_val = (int64_t) Rf_asInteger(delta);

    AMobjType obj_type = obj_id ? AMobjObjType(doc, obj_id) : AM_OBJ_TYPE_MAP;
    bool is_map = (obj_type == AM_OBJ_TYPE_MAP);

    AMresult *result = NULL;

    if (is_map) {
        // Map: key must be character string
        if (TYPEOF(key_or_pos) != STRSXP || XLENGTH(key_or_pos) != 1) {
            Rf_error("Map key must be a single character string");
        }
        const char *key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const *)key_str, .count = strlen(key_str)};

        result = AMmapIncrement(doc, obj_id, key, delta_val);
    } else if (obj_type == AM_OBJ_TYPE_LIST) {
        // List: position must be numeric (1-based)
        if (TYPEOF(key_or_pos) != INTSXP && TYPEOF(key_or_pos) != REALSXP) {
            Rf_error("List position must be numeric");
        }
        if (XLENGTH(key_or_pos) != 1) {
            Rf_error("List position must be scalar");
        }

        // Convert from R's 1-based indexing to C's 0-based
        int r_pos = Rf_asInteger(key_or_pos);
        if (r_pos < 1) {
            Rf_error("List position must be >= 1 (R uses 1-based indexing)");
        }
        size_t pos = (size_t)(r_pos - 1);

        result = AMlistIncrement(doc, obj_id, pos, delta_val);
    } else {
        Rf_error("Cannot increment counter in text object");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    AMresultFree(result);

    // Return document invisibly for chaining
    return doc_ptr;
}
