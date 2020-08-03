#include <float.h>
#include <string.h>
#include <stdbool.h>

#include <Rinternals.h>

#include "common.h"

SEXP float_max_C() {
  SEXP out = PROTECT(Rf_allocVector(REALSXP, 1));
  REAL(out)[0] = FLT_MAX;
  UNPROTECT(1);
  return out;
}

SEXP dims_C(SEXP lst) {
  const R_xlen_t sz = Rf_xlength(lst);
  SEXP dims = PROTECT(Rf_allocVector(VECSXP, sz));
  for (R_xlen_t i = 0; i != sz; ++i) {
    SEXP arr_i = VECTOR_ELT(lst, i);
    SEXP dim_i = PROTECT(getAttr(arr_i, "dim"));
    SET_VECTOR_ELT(dims, i, dim_i);
    UNPROTECT(1);
  }
  UNPROTECT(1);
  return dims;
}

SEXP enlist_img_C(SEXP arr4d) {  // arr4d must be a 4d array of doubles
  SEXP d4 = PROTECT(getAttr(arr4d, "dim"));
  int *d4_int = INTEGER(d4);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, d4_int[3]));
  R_xlen_t sub_len = d4_int[0] * d4_int[1] * d4_int[2];
  double *arr4d_dbl = REAL(arr4d);
  for (R_xlen_t j = 0; j != d4_int[3]; ++j) {
    double *start = arr4d_dbl + j * sub_len;
    SEXP out_j = PROTECT(
      Rf_alloc3DArray(REALSXP, d4_int[0], d4_int[1], d4_int[2])
    );
    double *out_j_dbl = REAL(out_j);
    memcpy(out_j_dbl, start, sub_len * sizeof(double));
    SET_VECTOR_ELT(out, j, out_j);
    UNPROTECT(1);
  }
  UNPROTECT(2);
  return out;
}

SEXP enlist_planes_C(SEXP arr3d) {  // arr3d must be a 3d array of doubles
  SEXP d3 = PROTECT(getAttr(arr3d, "dim"));
  int *d3_int = INTEGER(d3);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, d3_int[2]));
  R_xlen_t sub_len = d3_int[0] * d3_int[1];
  double *arr4d_dbl = REAL(arr3d);
  for (R_xlen_t j = 0; j != d3_int[2]; ++j) {
    double *start = arr4d_dbl + j * sub_len;
    SEXP out_j = PROTECT(
      Rf_allocMatrix(REALSXP, d3_int[0], d3_int[1])
    );
    double *out_j_dbl = REAL(out_j);
    memcpy(out_j_dbl, start, sub_len * sizeof(double));
    SET_VECTOR_ELT(out, j, out_j);
    UNPROTECT(1);
  }
  UNPROTECT(2);
  return out;
}

SEXP match_pillar_to_row_3_C(SEXP arr3d, SEXP mat) {
  SEXP d = PROTECT(getAttr(arr3d, "dim"));
  int *d_int = INTEGER(d), *mat_int = INTEGER(mat);
  double *arr3d_dbl = REAL(arr3d);
  SEXP out = PROTECT(Rf_allocMatrix(INTSXP, d_int[0], d_int[1]));
  int *out_int = INTEGER(out);
  R_xlen_t out_len = Rf_xlength(out);
  for (R_xlen_t i = 0; i != out_len; ++i) {
    bool found = false;
    R_xlen_t mat_nrow = nrows(mat);
    for (R_xlen_t j = 0; j != mat_nrow; ++j) {
      if (arr3d_dbl[i] == mat_int[j] &&
          arr3d_dbl[i + out_len] == mat_int[j + mat_nrow] &&
          arr3d_dbl[i + 2 * out_len] == mat_int[j + 2 * mat_nrow]) {
        found = true;
        out_int[i] = j;
        break;
      }
    }
    if (!found) {  // shouldn't happen
      out_int[i] = NA_INTEGER;
    }
  }
  UNPROTECT(2);
  return out;
}
