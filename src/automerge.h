#ifndef R_AUTOMERGE_H
#define R_AUTOMERGE_H

#ifndef R_NO_REMAP
#define R_NO_REMAP
#endif
#ifndef STRICT_R_HEADERS
#define STRICT_R_HEADERS
#endif
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <automerge-c/automerge.h>

// Protect against malicious input causing stack overflow
#define MAX_ERROR_MSG_SIZE 8192

// Protect against malicious deeply nested structures causing stack overflow
#define MAX_RECURSION_DEPTH 100

// Memory Management Structures ------------------------------------------------

// Document wrapper (tracks ownership)
typedef struct {
    AMdoc* doc;
    bool is_owned;  // Track ownership to prevent double-free
} am_doc;

// Sync state wrapper (owns AMresult, state pointer is borrowed)
typedef struct {
    AMresult* result;       // Owns the sync state (must be freed by finalizer)
    AMsyncState* state;     // Borrowed pointer extracted from result
} am_syncstate;

// Function Declarations -------------------------------------------------------

// Finalizers
void am_doc_finalizer(SEXP ext_ptr);
void am_result_finalizer(SEXP ext_ptr);
void am_syncstate_finalizer(SEXP ext_ptr);

// Helper functions
static inline am_doc* get_doc(SEXP doc_ptr);
static inline const AMobjId* get_objid(SEXP obj_ptr);

#endif // R_AUTOMERGE_H
