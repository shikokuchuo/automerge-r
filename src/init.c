#include "automerge.h"

static const R_CallMethodDef CallEntries[] = {
    // Add entries as: {"C_am_create", (DL_FUNC) &C_am_create, 1},
    {NULL, NULL, 0}
};

void R_init_automerge(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
