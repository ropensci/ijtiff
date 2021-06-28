#ifndef PKG_TIFF_COMMON_H__
#define PKG_TIFF_COMMON_H__

#include <stdio.h>
#include <stdint.h>
#include <tiff.h>
#include <tiffio.h>

#include <Rinternals.h>

typedef struct tiff_job {
    FILE *f;  // the TIFF file
    long ptr, len, alloc;
    char *data;
} tiff_job_t;

TIFF *TIFF_Open(const char *mode, tiff_job_t *rj);

void check_type_sizes(void);

void setAttr(SEXP x, const char *name, SEXP val);
SEXP getAttr(SEXP x, const char *name);


#endif  // PKG_TIFF_COMMON_H__
