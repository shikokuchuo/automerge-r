#include "automerge.h"

/**
 * Check AMresult for errors and validate expected type.
 * This is implemented as a function to be called by the CHECK_RESULT macro.
 *
 * AMresultError() returns AMbyteSpan, with a .src (pointer) and
 * .count (size) fields.
 *
 * @param result The AMresult* to check
 * @param expected_type Expected AMvalType (or AM_VAL_TYPE_VOID to skip type check)
 * @param file Source file name (from __FILE__)
 * @param line Line number (from __LINE__)
 * @return true if result is valid, false otherwise (does not return, calls Rf_error)
 */
void check_result_impl(AMresult *result, AMvalType expected_type,
                       const char *file, int line) {
    AMstatus status = AMresultStatus(result);

    if (status != AM_STATUS_OK) {
        AMbyteSpan err_span = AMresultError(result);

        size_t msg_size = err_span.count < MAX_ERROR_MSG_SIZE ?
                          err_span.count : MAX_ERROR_MSG_SIZE;
        char err_msg[MAX_ERROR_MSG_SIZE + 1];
        memcpy(err_msg, err_span.src, msg_size);
        err_msg[msg_size] = '\0';

        AMresultFree(result);
        Rf_error("Automerge error at %s:%d: %s", file, line, err_msg);
    }

    if (expected_type != AM_VAL_TYPE_VOID) {
        AMitem *item = AMresultItem(result);
        if (!item) {
            AMresultFree(result);
            Rf_error("Type check failed at %s:%d: AMresultItem returned NULL",
                     file, line);
        }
        AMvalType actual_type = AMitemValType(item);
        if (actual_type != expected_type) {
            AMresultFree(result);
            Rf_error("Type mismatch at %s:%d: expected %d, got %d",
                     file, line, expected_type, actual_type);
        }
    }
}
