#include "automerge.h"

static const R_CallMethodDef CallEntries[] = {
    // Document lifecycle
    {"C_am_create", (DL_FUNC) &C_am_create, 1},
    {"C_am_save", (DL_FUNC) &C_am_save, 1},
    {"C_am_load", (DL_FUNC) &C_am_load, 1},
    {"C_am_fork", (DL_FUNC) &C_am_fork, 2},
    {"C_am_merge", (DL_FUNC) &C_am_merge, 2},
    {"C_am_get_actor", (DL_FUNC) &C_am_get_actor, 1},
    {"C_am_set_actor", (DL_FUNC) &C_am_set_actor, 2},
    {"C_am_commit", (DL_FUNC) &C_am_commit, 3},
    {"C_am_rollback", (DL_FUNC) &C_am_rollback, 1},
    {NULL, NULL, 0}
};

void R_init_automerge(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
