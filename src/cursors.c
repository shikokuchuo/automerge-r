#include "automerge.h"

// Cursor Support -------------------------------------------------------------

/**
 * Create a cursor at a position in a text object.
 *
 * R signature: am_cursor(obj, position)
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param position R integer (0-based position)
 * @return External pointer to AMcursor wrapped as am_cursor S3 class
 */
SEXP C_am_cursor(SEXP obj_ptr, SEXP position) {
    // Get document from object ID
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);

    // Validate position (0-based indexing)
    if (TYPEOF(position) != INTSXP && TYPEOF(position) != REALSXP) {
        Rf_error("position must be numeric");
    }
    if (XLENGTH(position) != 1) {
        Rf_error("position must be a scalar");
    }
    int r_pos = Rf_asInteger(position);
    if (r_pos < 0) {
        Rf_error("position must be non-negative (uses 0-based indexing)");
    }
    size_t c_pos = (size_t) r_pos;  // Direct use, already 0-based

    // Call AMgetCursor (heads parameter NULL for current state)
    AMresult *result = AMgetCursor(doc, obj_id, c_pos, NULL);
    CHECK_RESULT(result, AM_VAL_TYPE_CURSOR);

    // Extract cursor from result item
    AMitem *item = AMresultItem(result);
    AMcursor const *cursor = NULL;
    AMitemToCursor(item, &cursor);

    // Wrap result as external pointer with parent = doc_ptr
    // The cursor pointer is borrowed from the result, so we wrap the result
    SEXP cursor_ptr = PROTECT(wrap_am_result(result, doc_ptr));

    // Set class to am_cursor
    Rf_classgets(cursor_ptr, Rf_mkString("am_cursor"));

    UNPROTECT(1);
    return cursor_ptr;
}

/**
 * Get the position of a cursor in a text object.
 *
 * R signature: am_cursor_position(obj, cursor)
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param cursor_ptr External pointer to AMresult containing cursor
 * @return R integer (0-based position)
 */
SEXP C_am_cursor_position(SEXP obj_ptr, SEXP cursor_ptr) {
    // Get document from object ID
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);

    // Extract cursor from cursor_ptr
    // The cursor is stored in an AMresult wrapped as external pointer
    if (TYPEOF(cursor_ptr) != EXTPTRSXP) {
        Rf_error("cursor must be an external pointer (am_cursor object)");
    }

    AMresult *cursor_result = (AMresult *) R_ExternalPtrAddr(cursor_ptr);
    if (!cursor_result) {
        Rf_error("Invalid cursor pointer (NULL or freed)");
    }

    AMitem *cursor_item = AMresultItem(cursor_result);
    AMcursor const *cursor = NULL;
    AMitemToCursor(cursor_item, &cursor);

    // Call AMgetCursorPosition (heads parameter NULL for current state)
    AMresult *result = AMgetCursorPosition(doc, obj_id, cursor, NULL);
    CHECK_RESULT(result, AM_VAL_TYPE_UINT);

    // Extract position from result
    AMitem *item = AMresultItem(result);
    uint64_t c_pos;
    AMitemToUint(item, &c_pos);

    // Return 0-based position directly
    if (c_pos > INT_MAX) {
        AMresultFree(result);
        Rf_error("Position too large to represent as R integer");
    }
    int r_pos = (int) c_pos;  // Direct use, 0-based

    AMresultFree(result);

    return Rf_ScalarInteger(r_pos);
}

// Mark Support ---------------------------------------------------------------

// Forward declaration
static SEXP amitem_to_r_value(AMitem *item);

/**
 * Helper: Convert single mark to R list.
 * Returns an unprotected R list (all internal allocations are cleaned up).
 */
static SEXP convert_mark_to_r_list(AMmark const *mark, size_t index) {
    AMbyteSpan name_span = AMmarkName(mark);
    size_t c_start = AMmarkStart(mark);
    size_t c_end = AMmarkEnd(mark);

    AMresult *value_result = AMmarkValue(mark);
    if (!value_result) {
        Rf_error("Failed to get mark value at index %zu", index);
    }

    AMitem *value_item = AMresultItem(value_result);

    const char *names[] = {"name", "value", "start", "end", ""};
    SEXP mark_list = PROTECT(Rf_mkNamed(VECSXP, names));
    SEXP name = Rf_mkCharLenCE((char *) name_span.src, name_span.count, CE_UTF8);
    SET_VECTOR_ELT(mark_list, 0, Rf_ScalarString(name));
    SET_VECTOR_ELT(mark_list, 1, amitem_to_r_value(value_item));
    SET_VECTOR_ELT(mark_list, 2, Rf_ScalarInteger((int)c_start));
    SET_VECTOR_ELT(mark_list, 3, Rf_ScalarInteger((int)c_end));

    AMresultFree(value_result);
    UNPROTECT(1);

    return mark_list;
}

/**
 * Implementation for getting marks with optional position filtering.
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param filter_position If >= 0, filter marks to include only those at this position.
 *                        If < 0, return all marks (no filtering).
 * @return R list of marks
 */
static SEXP C_am_marks_impl(SEXP obj_ptr, int filter_position) {
    // Get document from object ID
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);

    // Call AMmarks (heads parameter NULL for current state)
    AMresult *result = AMmarks(doc, obj_id, NULL);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    // Get items iterator
    AMitems items = AMresultItems(result);
    size_t total_count = AMitemsSize(&items);

    bool filtering = filter_position >= 0;
    size_t c_pos = filtering ? (size_t)filter_position : 0;

    // If filtering, need to count matches first
    size_t output_count = total_count;
    if (filtering) {
        output_count = 0;
        AMitems items_copy = AMresultItems(result);
        for (size_t i = 0; i < total_count; i++) {
            AMitem *item = AMitemsNext(&items_copy, 1);
            if (!item) break;

            AMmark const *mark = NULL;
            AMitemToMark(item, &mark);

            size_t c_start = AMmarkStart(mark);
            size_t c_end = AMmarkEnd(mark);

            // Mark range is [start, end) - includes start, excludes end
            if (c_start <= c_pos && c_pos < c_end) {
                output_count++;
            }
        }
    }

    // Create R list to store marks
    SEXP marks_list = PROTECT(Rf_allocVector(VECSXP, output_count));

    // Iterate and collect marks
    size_t output_index = 0;
    for (size_t i = 0; i < total_count; i++) {
        AMitem *item = AMitemsNext(&items, 1);

        // Extract mark
        AMmark const *mark = NULL;
        AMitemToMark(item, &mark);

        // Apply filter if needed
        if (filtering) {
            size_t c_start = AMmarkStart(mark);
            size_t c_end = AMmarkEnd(mark);

            // Mark range is [start, end) - includes start, excludes end
            if (!(c_start <= c_pos && c_pos < c_end)) {
                continue;  // Skip marks that don't include the position
            }
        }

        SEXP mark_list = convert_mark_to_r_list(mark, i);
        SET_VECTOR_ELT(marks_list, output_index, mark_list);

        output_index++;
    }

    AMresultFree(result);
    UNPROTECT(1);  // marks_list
    return marks_list;
}

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
        int64_t milliseconds = (int64_t) (seconds * 1000.0);
        return AMitemFromTimestamp(milliseconds);
    } else if (Rf_inherits(value, "am_counter")) {
        if (TYPEOF(value) != INTSXP || Rf_xlength(value) != 1) {
            Rf_error("Counter must be a scalar integer");
        }
        int64_t val = (int64_t) INTEGER(value)[0];
        return AMitemFromCounter(val);
    } else if (TYPEOF(value) == LGLSXP && Rf_xlength(value) == 1) {
        bool val = (bool) LOGICAL(value)[0];
        return AMitemFromBool(val);
    } else if (TYPEOF(value) == INTSXP && Rf_xlength(value) == 1) {
        int64_t val = (int64_t) INTEGER(value)[0];
        return AMitemFromInt(val);
    } else if (TYPEOF(value) == REALSXP && Rf_xlength(value) == 1) {
        double val = REAL(value)[0];
        return AMitemFromF64(val);
    } else if (TYPEOF(value) == STRSXP && Rf_xlength(value) == 1) {
        const char *str = CHAR(STRING_ELT(value, 0));
        AMbyteSpan span = {.src = (uint8_t const *) str, .count = strlen(str)};
        return AMitemFromStr(span);
    } else if (TYPEOF(value) == RAWSXP) {
        return AMitemFromBytes(RAW(value), (size_t) Rf_xlength(value));
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
            AMitemToBool(item, &val);
            return Rf_ScalarLogical(val);
        }
        case AM_VAL_TYPE_INT: {
            int64_t val;
            AMitemToInt(item, &val);
            if (val < INT_MIN || val > INT_MAX) {
                Rf_warning("Mark value integer out of R integer range, converting to double");
                return Rf_ScalarReal((double) val);
            }
            return Rf_ScalarInteger((int) val);
        }
        case AM_VAL_TYPE_UINT: {
            uint64_t val;
            AMitemToUint(item, &val);
            if (val > INT_MAX) {
                Rf_warning("Mark value unsigned integer out of R integer range, converting to double");
                return Rf_ScalarReal((double) val);
            }
            return Rf_ScalarInteger((int) val);
        }
        case AM_VAL_TYPE_F64: {
            double val;
            AMitemToF64(item, &val);
            return Rf_ScalarReal(val);
        }
        case AM_VAL_TYPE_STR: {
            AMbyteSpan span;
            AMitemToStr(item, &span);
            return Rf_ScalarString(Rf_mkCharLenCE((char *) span.src, span.count, CE_UTF8));
        }
        case AM_VAL_TYPE_BYTES: {
            AMbyteSpan span;
            AMitemToBytes(item, &span);
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
            double seconds = (double) val / 1000.0;
            SEXP result = PROTECT(Rf_ScalarReal(seconds));
            SEXP class_vec = Rf_allocVector(STRSXP, 2);
            Rf_classgets(result, class_vec);
            SET_STRING_ELT(class_vec, 0, Rf_mkChar("POSIXct"));
            SET_STRING_ELT(class_vec, 1, Rf_mkChar("POSIXt"));
            UNPROTECT(1);
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
                return Rf_ScalarReal((double) val);
            }
            SEXP result = PROTECT(Rf_ScalarInteger((int) val));
            Rf_classgets(result, Rf_mkString("am_counter"));
            UNPROTECT(1);
            return result;
        }
        default:
            Rf_error("Unsupported mark value type: %d", type);
    }
}

/**
 * Create a mark on a text range.
 *
 * R signature: am_mark_create(obj, start, end, name, value, expand = "none")
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param start R integer (1-based start position, inclusive)
 * @param end R integer (1-based end position, exclusive)
 * @param name R character string (mark name)
 * @param value R value (mark value - various types supported)
 * @param expand R character string (expand mode: "none", "before", "after", "both")
 * @return The text object (invisibly)
 */
SEXP C_am_mark_create(SEXP obj_ptr, SEXP start, SEXP end,
                      SEXP name, SEXP value, SEXP expand) {
    // Get document from object ID
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    // Get object ID
    const AMobjId *obj_id = get_objid(obj_ptr);

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
    size_t c_start = (size_t) r_start;  // Direct use, 0-based

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
    size_t c_end = (size_t) r_end;  // Direct use, 0-based

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

    // Call AMmarkCreate
    AMresult *result = AMmarkCreate(doc, obj_id, c_start, c_end, expand_mode,
                                     name_span, value_item);

    // Free value result
    AMresultFree(value_result);

    // Check result
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    AMresultFree(result);

    return obj_ptr;
}

/**
 * Get all marks in a text object.
 *
 * R signature: am_marks(obj)
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @return R list of marks, each mark is a list with: name, value, start, end
 */
SEXP C_am_marks(SEXP obj_ptr) {
    return C_am_marks_impl(obj_ptr, -1);  // -1 = no filtering
}

/**
 * Get marks at a specific position in a text object.
 *
 * R signature: am_marks_at(obj, position)
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param position R integer (0-based position)
 * @return R list of marks that include the position, each mark is a list with: name, value, start, end
 */
SEXP C_am_marks_at(SEXP obj_ptr, SEXP position) {
    // Validate position (0-based indexing)
    if (TYPEOF(position) != INTSXP && TYPEOF(position) != REALSXP) {
        Rf_error("position must be numeric");
    }
    if (XLENGTH(position) != 1) {
        Rf_error("position must be a scalar");
    }
    int r_pos = Rf_asInteger(position);
    if (r_pos < 0) {
        Rf_error("position must be non-negative (uses 0-based indexing)");
    }

    return C_am_marks_impl(obj_ptr, r_pos);
}
