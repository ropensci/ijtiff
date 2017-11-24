#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* FIXME: 
   Check these declarations against the C/Fortran source code.
*/

/* .Call calls */
extern SEXP _ijtiff_dims_cpp(SEXP);
extern SEXP _ijtiff_float_max();
extern SEXP read_tif_c(SEXP);
extern SEXP write_tif_c(SEXP, SEXP, SEXP, SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"_ijtiff_dims_cpp",  (DL_FUNC) &_ijtiff_dims_cpp,  1},
    {"_ijtiff_float_max", (DL_FUNC) &_ijtiff_float_max, 0},
    {"read_tif_c",        (DL_FUNC) &read_tif_c,        1},
    {"write_tif_c",       (DL_FUNC) &write_tif_c,       5},
    {NULL, NULL, 0}
};

void R_init_ijtiff(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
