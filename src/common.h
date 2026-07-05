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

// Heap-owned context for a single TIFF operation. The libtiff client handle
// points at &ctx->rj, and the external-pointer finalizer (cleanup_tiff_ptr)
// owns this struct: it closes ctx->tiff (which reads ctx->rj) and frees ctx.
// Because rj lives on the heap inside ctx (lifetime tied to the external
// pointer), the finalizer always closes against valid memory even if the
// entry point longjmp'd out on a libtiff-internal error.
typedef struct tiff_ctx {
    TIFF *tiff;        // libtiff handle (NULL until opened / after close)
    tiff_job_t rj;     // job state — libtiff's client handle points at &ctx->rj
} tiff_ctx_t;

TIFF *TIFF_Open(const char *mode, tiff_job_t *rj);

// Allocate a zeroed tiff_ctx_t, wrap it in a finalized external pointer.
// Returns the (unprotected) external pointer; *out receives the ctx.
// The CALLER must PROTECT the returned SEXP.
SEXP new_tiff_ctx(tiff_ctx_t **out);

// Cleanup function to make sure all TIFF resources are released
void cleanup_tiff(void);

// Helper function for finalizers that safely close a TIFF pointer
void cleanup_tiff_ptr(SEXP ptr);

// Helper function to open a TIFF file
TIFF* open_tiff_file(const char* filename, tiff_job_t* rj, FILE** f);

// Open a TIFF from a filename (STRSXP) or an in-memory raw vector (RAWSXP)
TIFF* open_tiff_source(SEXP src, tiff_job_t* rj, FILE** f);

void check_type_sizes(void);

void setAttr(SEXP x, const char *name, SEXP val);
SEXP getAttr(SEXP x, const char *name);

// List of tags we want to read
extern const ttag_t supported_tags[];
extern const size_t n_supported_tags;

// Global variable to track the last opened TIFF handle for cleanup
extern TIFF *last_tiff;

#endif  // PKG_TIFF_COMMON_H__
