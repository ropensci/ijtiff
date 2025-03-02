#ifndef PKG_TIFF_COMMON_H__
#define PKG_TIFF_COMMON_H__

#include <stdbool.h>
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

// Cleanup function to make sure all TIFF resources are released
void cleanup_tiff(void);

// Helper function to open a TIFF file
TIFF* open_tiff_file(const char* filename, tiff_job_t* rj, FILE** f);

void check_type_sizes(void);

void setAttr(SEXP x, const char *name, SEXP val);
SEXP getAttr(SEXP x, const char *name);

// List of tags we want to read
extern const ttag_t supported_tags[];
extern const size_t n_supported_tags;

#endif  // PKG_TIFF_COMMON_H__
