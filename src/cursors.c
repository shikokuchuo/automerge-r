#include "automerge.h"

// Cursor Support -------------------------------------------------------------

/**
 * Create a cursor at a position in a text object.
 *
 * R signature: am_cursor(doc, obj, position)
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param position R integer (0-based position)
 * @return External pointer to AMcursor wrapped as am_cursor S3 class
 */
SEXP C_am_cursor(SEXP doc_ptr, SEXP obj_ptr, SEXP position) {
    // Get document
    AMdoc *doc = get_doc(doc_ptr);
    if (!doc) {
        Rf_error("Invalid document pointer");
    }

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);
    if (!obj_id) {
        Rf_error("Invalid object ID");
    }

    // Validate position (0-based indexing)
    if (TYPEOF(position) != INTSXP && TYPEOF(position) != REALSXP) {
        Rf_error("position must be numeric");
    }
    if (Rf_xlength(position) != 1) {
        Rf_error("position must be a scalar");
    }
    int r_pos = Rf_asInteger(position);
    if (r_pos < 0) {
        Rf_error("position must be non-negative (uses 0-based indexing)");
    }
    size_t c_pos = (size_t)r_pos;  // Direct use, already 0-based

    // Call AMgetCursor (heads parameter NULL for current state)
    AMresult *result = AMgetCursor(doc, obj_id, c_pos, NULL);
    CHECK_RESULT(result, AM_VAL_TYPE_CURSOR);

    // Extract cursor from result item
    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        Rf_error("Failed to get cursor item from result");
    }

    AMcursor const *cursor = NULL;
    if (!AMitemToCursor(item, &cursor)) {
        AMresultFree(result);
        Rf_error("Failed to extract cursor from item");
    }

    if (!cursor) {
        AMresultFree(result);
        Rf_error("Cursor extraction returned NULL");
    }

    // Wrap result as external pointer with parent = doc_ptr
    // The cursor pointer is borrowed from the result, so we wrap the result
    SEXP cursor_ptr = PROTECT(wrap_am_result(result, doc_ptr));

    // Set class to am_cursor
    SEXP class_vec = PROTECT(Rf_allocVector(STRSXP, 1));
    SET_STRING_ELT(class_vec, 0, Rf_mkChar("am_cursor"));
    Rf_classgets(cursor_ptr, class_vec);

    UNPROTECT(2);  // cursor_ptr, class_vec
    return cursor_ptr;
}

/**
 * Get the position of a cursor in a text object.
 *
 * R signature: am_cursor_position(doc, obj, cursor)
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param cursor_ptr External pointer to AMresult containing cursor
 * @return R integer (0-based position)
 */
SEXP C_am_cursor_position(SEXP doc_ptr, SEXP obj_ptr, SEXP cursor_ptr) {
    // Get document
    AMdoc *doc = get_doc(doc_ptr);
    if (!doc) {
        Rf_error("Invalid document pointer");
    }

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);
    if (!obj_id) {
        Rf_error("Invalid object ID");
    }

    // Extract cursor from cursor_ptr
    // The cursor is stored in an AMresult wrapped as external pointer
    if (TYPEOF(cursor_ptr) != EXTPTRSXP) {
        Rf_error("cursor must be an external pointer (am_cursor object)");
    }

    AMresult *cursor_result = (AMresult *)R_ExternalPtrAddr(cursor_ptr);
    if (!cursor_result) {
        Rf_error("Invalid cursor pointer (NULL or freed)");
    }

    AMitem *cursor_item = AMresultItem(cursor_result);
    if (!cursor_item) {
        Rf_error("Failed to get cursor item from result");
    }

    AMcursor const *cursor = NULL;
    if (!AMitemToCursor(cursor_item, &cursor)) {
        Rf_error("Failed to extract cursor from item");
    }

    if (!cursor) {
        Rf_error("Cursor extraction returned NULL");
    }

    // Call AMgetCursorPosition (heads parameter NULL for current state)
    AMresult *result = AMgetCursorPosition(doc, obj_id, cursor, NULL);
    CHECK_RESULT(result, AM_VAL_TYPE_UINT);

    // Extract position from result
    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        Rf_error("Failed to get position item from result");
    }

    uint64_t c_pos;
    if (!AMitemToUint(item, &c_pos)) {
        AMresultFree(result);
        Rf_error("Failed to extract position from item");
    }

    // Return 0-based position directly
    if (c_pos > INT_MAX) {
        AMresultFree(result);
        Rf_error("Position too large to represent as R integer");
    }
    int r_pos = (int)c_pos;  // Direct use, 0-based

    AMresultFree(result);

    return Rf_ScalarInteger(r_pos);
}

// Mark Support ---------------------------------------------------------------

/**
 * Helper: Convert R expand string to AMmarkExpand enum.
 */
static AMmarkExpand r_expand_to_c(SEXP expand) {
    if (TYPEOF(expand) != STRSXP || Rf_xlength(expand) != 1) {
        Rf_error("expand must be a single character string");
    }

    const char *expand_str = CHAR(STRING_ELT(expand, 0));

    if (strcmp(expand_str, "none") == 0) {
        return AM_MARK_EXPAND_NONE;
    } else if (strcmp(expand_str, "before") == 0) {
        return AM_MARK_EXPAND_BEFORE;
    } else if (strcmp(expand_str, "after") == 0) {
        return AM_MARK_EXPAND_AFTER;
    } else if (strcmp(expand_str, "both") == 0) {
        return AM_MARK_EXPAND_BOTH;
    } else {
        Rf_error("Invalid expand value: must be \"none\", \"before\", \"after\", or \"both\"");
    }
}

/**
 * Helper: Convert R value to AMitem for mark value.
 */
static AMresult* r_value_to_amitem(SEXP value) {
    // Check S3 classes BEFORE generic TYPEOF checks
    if (value == R_NilValue) {
        return AMitemFromNull();
    } else if (Rf_inherits(value, "POSIXct")) {
        if (Rf_xlength(value) != 1) {
            Rf_error("Mark value must be scalar");
        }
        double seconds = Rf_asReal(value);
        int64_t milliseconds = (int64_t)(seconds * 1000.0);
        return AMitemFromTimestamp(milliseconds);
    } else if (Rf_inherits(value, "am_counter")) {
        if (TYPEOF(value) != INTSXP || Rf_xlength(value) != 1) {
            Rf_error("Counter must be a scalar integer");
        }
        int64_t val = (int64_t)INTEGER(value)[0];
        return AMitemFromCounter(val);
    } else if (TYPEOF(value) == LGLSXP && Rf_xlength(value) == 1) {
        bool val = (bool)LOGICAL(value)[0];
        return AMitemFromBool(val);
    } else if (TYPEOF(value) == INTSXP && Rf_xlength(value) == 1) {
        int64_t val = (int64_t)INTEGER(value)[0];
        return AMitemFromInt(val);
    } else if (TYPEOF(value) == REALSXP && Rf_xlength(value) == 1) {
        double val = REAL(value)[0];
        return AMitemFromF64(val);
    } else if (TYPEOF(value) == STRSXP && Rf_xlength(value) == 1) {
        const char *str = CHAR(STRING_ELT(value, 0));
        AMbyteSpan span = {.src = (uint8_t const *)str, .count = strlen(str)};
        return AMitemFromStr(span);
    } else if (TYPEOF(value) == RAWSXP) {
        return AMitemFromBytes(RAW(value), (size_t)Rf_xlength(value));
    } else {
        Rf_error("Unsupported mark value type");
    }
}

/**
 * Helper: Convert AMitem to R value for mark value.
 */
static SEXP amitem_to_r_value(AMitem *item) {
    AMvalType type = AMitemValType(item);

    switch (type) {
        case AM_VAL_TYPE_NULL:
            return R_NilValue;
        case AM_VAL_TYPE_BOOL: {
            bool val;
            if (!AMitemToBool(item, &val)) {
                Rf_error("Failed to extract boolean from mark value");
            }
            return Rf_ScalarLogical(val);
        }
        case AM_VAL_TYPE_INT: {
            int64_t val;
            if (!AMitemToInt(item, &val)) {
                Rf_error("Failed to extract integer from mark value");
            }
            if (val < INT_MIN || val > INT_MAX) {
                Rf_warning("Mark value integer out of R integer range, converting to double");
                return Rf_ScalarReal((double)val);
            }
            return Rf_ScalarInteger((int)val);
        }
        case AM_VAL_TYPE_UINT: {
            uint64_t val;
            if (!AMitemToUint(item, &val)) {
                Rf_error("Failed to extract unsigned integer from mark value");
            }
            if (val > INT_MAX) {
                Rf_warning("Mark value unsigned integer out of R integer range, converting to double");
                return Rf_ScalarReal((double)val);
            }
            return Rf_ScalarInteger((int)val);
        }
        case AM_VAL_TYPE_F64: {
            double val;
            if (!AMitemToF64(item, &val)) {
                Rf_error("Failed to extract double from mark value");
            }
            return Rf_ScalarReal(val);
        }
        case AM_VAL_TYPE_STR: {
            AMbyteSpan span;
            if (!AMitemToStr(item, &span)) {
                Rf_error("Failed to extract string from mark value");
            }
            return Rf_ScalarString(Rf_mkCharLenCE((char *)span.src, span.count, CE_UTF8));
        }
        case AM_VAL_TYPE_BYTES: {
            AMbyteSpan span;
            if (!AMitemToBytes(item, &span)) {
                Rf_error("Failed to extract bytes from mark value");
            }
            SEXP raw = PROTECT(Rf_allocVector(RAWSXP, span.count));
            memcpy(RAW(raw), span.src, span.count);
            UNPROTECT(1);
            return raw;
        }
        case AM_VAL_TYPE_TIMESTAMP: {
            int64_t val;
            // Try AMitemToTimestamp first, then fall back to AMitemToInt
            if (!AMitemToTimestamp(item, &val)) {
                if (!AMitemToInt(item, &val)) {
                    Rf_error("Failed to extract timestamp from mark value");
                }
            }
            double seconds = (double)val / 1000.0;
            SEXP result = PROTECT(Rf_ScalarReal(seconds));
            SEXP class_vec = PROTECT(Rf_allocVector(STRSXP, 2));
            SET_STRING_ELT(class_vec, 0, Rf_mkChar("POSIXct"));
            SET_STRING_ELT(class_vec, 1, Rf_mkChar("POSIXt"));
            Rf_classgets(result, class_vec);
            UNPROTECT(2);
            return result;
        }
        case AM_VAL_TYPE_COUNTER: {
            int64_t val;
            // For counters, try both AMitemToInt and AMitemToCounter
            if (!AMitemToCounter(item, &val)) {
                // Fallback to AMitemToInt
                if (!AMitemToInt(item, &val)) {
                    Rf_error("Failed to extract counter from mark value");
                }
            }
            if (val < INT_MIN || val > INT_MAX) {
                Rf_warning("Counter value out of R integer range, converting to double");
                return Rf_ScalarReal((double)val);
            }
            SEXP result = PROTECT(Rf_ScalarInteger((int)val));
            SEXP class_vec = PROTECT(Rf_allocVector(STRSXP, 1));
            SET_STRING_ELT(class_vec, 0, Rf_mkChar("am_counter"));
            Rf_classgets(result, class_vec);
            UNPROTECT(2);
            return result;
        }
        default:
            Rf_error("Unsupported mark value type: %d", type);
    }
}

/**
 * Create a mark on a text range.
 *
 * R signature: am_mark_create(doc, obj, start, end, name, value, expand = "none")
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param start R integer (1-based start position, inclusive)
 * @param end R integer (1-based end position, exclusive)
 * @param name R character string (mark name)
 * @param value R value (mark value - various types supported)
 * @param expand R character string (expand mode: "none", "before", "after", "both")
 * @return The document (invisibly)
 */
SEXP C_am_mark_create(SEXP doc_ptr, SEXP obj_ptr, SEXP start, SEXP end,
                      SEXP name, SEXP value, SEXP expand) {
    // Get document
    AMdoc *doc = get_doc(doc_ptr);
    if (!doc) {
        Rf_error("Invalid document pointer");
    }

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);
    if (!obj_id) {
        Rf_error("Invalid object ID");
    }

    // Validate start position (0-based indexing)
    if (TYPEOF(start) != INTSXP && TYPEOF(start) != REALSXP) {
        Rf_error("start must be numeric");
    }
    if (Rf_xlength(start) != 1) {
        Rf_error("start must be a scalar");
    }
    int r_start = Rf_asInteger(start);
    if (r_start < 0) {
        Rf_error("start must be non-negative (uses 0-based indexing)");
    }
    size_t c_start = (size_t)r_start;  // Direct use, 0-based

    // Validate end position (0-based indexing)
    if (TYPEOF(end) != INTSXP && TYPEOF(end) != REALSXP) {
        Rf_error("end must be numeric");
    }
    if (Rf_xlength(end) != 1) {
        Rf_error("end must be a scalar");
    }
    int r_end = Rf_asInteger(end);
    if (r_end < 0) {
        Rf_error("end must be non-negative (uses 0-based indexing)");
    }
    size_t c_end = (size_t)r_end;  // Direct use, 0-based

    if (c_end <= c_start) {
        Rf_error("end must be greater than start");
    }

    // Validate and convert name
    if (TYPEOF(name) != STRSXP || Rf_xlength(name) != 1) {
        Rf_error("name must be a single character string");
    }
    const char *name_str = CHAR(STRING_ELT(name, 0));
    AMbyteSpan name_span = {.src = (uint8_t const *)name_str, .count = strlen(name_str)};

    // Convert expand parameter
    AMmarkExpand expand_mode = r_expand_to_c(expand);

    // Convert value to AMitem
    AMresult *value_result = r_value_to_amitem(value);
    if (!value_result) {
        Rf_error("Failed to convert mark value to AMitem");
    }

    AMitem *value_item = AMresultItem(value_result);
    if (!value_item) {
        AMresultFree(value_result);
        Rf_error("Failed to get value item from result");
    }

    // Call AMmarkCreate
    AMresult *result = AMmarkCreate(doc, obj_id, c_start, c_end, expand_mode,
                                     name_span, value_item);

    // Free value result
    AMresultFree(value_result);

    // Check result
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    AMresultFree(result);

    return doc_ptr;
}

/**
 * Get all marks in a text object.
 *
 * R signature: am_marks(doc, obj)
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @return R list of marks, each mark is a list with: name, value, start, end
 */
SEXP C_am_marks(SEXP doc_ptr, SEXP obj_ptr) {
    // Get document
    AMdoc *doc = get_doc(doc_ptr);
    if (!doc) {
        Rf_error("Invalid document pointer");
    }

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);
    if (!obj_id) {
        Rf_error("Invalid object ID");
    }

    // Call AMmarks (heads parameter NULL for current state)
    AMresult *result = AMmarks(doc, obj_id, NULL);

    // Check if result is valid
    AMstatus status = AMresultStatus(result);
    if (status != AM_STATUS_OK) {
        AMbyteSpan err_span = AMresultError(result);
        if (err_span.count > 0) {
            size_t msg_size = err_span.count < MAX_ERROR_MSG_SIZE ?
                              err_span.count : MAX_ERROR_MSG_SIZE;
            char err_msg[msg_size + 1];
            memcpy(err_msg, err_span.src, msg_size);
            err_msg[msg_size] = '\0';
            AMresultFree(result);
            Rf_error("Automerge error: %s", err_msg);
        } else {
            AMresultFree(result);
            Rf_error("Automerge error: unknown error (no error message)");
        }
    }

    // Get items iterator
    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    // Create R list to store marks
    SEXP marks_list = PROTECT(Rf_allocVector(VECSXP, count));

    // Iterate over marks
    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) {
            AMresultFree(result);
            UNPROTECT(1);
            Rf_error("Failed to get mark item at index %zu", i);
        }

        // Extract mark
        AMmark const *mark = NULL;
        if (!AMitemToMark(item, &mark)) {
            AMresultFree(result);
            UNPROTECT(1);
            Rf_error("Failed to extract mark from item at index %zu", i);
        }

        // Get mark properties
        AMbyteSpan name_span = AMmarkName(mark);
        size_t c_start = AMmarkStart(mark);
        size_t c_end = AMmarkEnd(mark);

        // Get mark value
        AMresult *value_result = AMmarkValue(mark);
        if (!value_result) {
            AMresultFree(result);
            UNPROTECT(1);
            Rf_error("Failed to get mark value at index %zu", i);
        }

        AMitem *value_item = AMresultItem(value_result);
        if (!value_item) {
            AMresultFree(value_result);
            AMresultFree(result);
            UNPROTECT(1);
            Rf_error("Failed to get value item at index %zu", i);
        }

        SEXP r_value = PROTECT(amitem_to_r_value(value_item));
        AMresultFree(value_result);

        // Use 0-based positions directly
        int r_start = (int)c_start;
        int r_end = (int)c_end;

        // Create R list for this mark
        SEXP mark_list = PROTECT(Rf_allocVector(VECSXP, 4));
        SEXP mark_names = PROTECT(Rf_allocVector(STRSXP, 4));

        // Set field names
        SET_STRING_ELT(mark_names, 0, Rf_mkChar("name"));
        SET_STRING_ELT(mark_names, 1, Rf_mkChar("value"));
        SET_STRING_ELT(mark_names, 2, Rf_mkChar("start"));
        SET_STRING_ELT(mark_names, 3, Rf_mkChar("end"));
        Rf_namesgets(mark_list, mark_names);

        // Set field values
        SEXP name_str = PROTECT(Rf_ScalarString(Rf_mkCharLenCE((char *)name_span.src,
                                                                 name_span.count, CE_UTF8)));
        SET_VECTOR_ELT(mark_list, 0, name_str);
        SET_VECTOR_ELT(mark_list, 1, r_value);
        SET_VECTOR_ELT(mark_list, 2, Rf_ScalarInteger(r_start));
        SET_VECTOR_ELT(mark_list, 3, Rf_ScalarInteger(r_end));
        UNPROTECT(1);  // name_str

        // Add to marks list
        SET_VECTOR_ELT(marks_list, i, mark_list);

        UNPROTECT(3);  // r_value, mark_list, mark_names
    }

    AMresultFree(result);
    UNPROTECT(1);  // marks_list
    return marks_list;
}
