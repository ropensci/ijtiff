#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>


/* .Call calls */
extern SEXP count_directories_C(SEXP);
extern SEXP dims_C(SEXP);
extern SEXP enlist_img_C(SEXP);
extern SEXP enlist_planes_C(SEXP);
extern SEXP float_max_C();
extern SEXP match_pillar_to_row_3_C(SEXP, SEXP);
extern SEXP read_tags_C(SEXP, SEXP);
extern SEXP read_tif_C(SEXP, SEXP);
extern SEXP write_tif_C(SEXP, SEXP, SEXP, SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"count_directories_C",     (DL_FUNC) &count_directories_C,     1},
    {"dims_C",                  (DL_FUNC) &dims_C,                  1},
    {"enlist_img_C",            (DL_FUNC) &enlist_img_C,            1},
    {"enlist_planes_C",         (DL_FUNC) &enlist_planes_C,         1},
    {"float_max_C",             (DL_FUNC) &float_max_C,             0},
    {"match_pillar_to_row_3_C", (DL_FUNC) &match_pillar_to_row_3_C, 2},
    {"read_tags_C",             (DL_FUNC) &read_tags_C,             2},
    {"read_tif_C",              (DL_FUNC) &read_tif_C,              2},
    {"write_tif_C",             (DL_FUNC) &write_tif_C,             5},
    {NULL, NULL, 0}
};

void R_init_ijtiff(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
