#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>
#include <limits.h>

#include "common.h"

#include <Rinternals.h>
#include <Rversion.h>

// Format the message, close+neutralize the heap-owned TIFF context, then raise
// the R error. Mirrors read.c's handle_error. cleanup_tiff_ptr does TIFFClose
// (which, for the in-memory job, frees ctx->rj.data because ctx->rj.alloc != 0)
// + free(ctx) + R_ClearExternalPtr (so the finalizer cannot re-close) + resets
// last_tiff. The job state ctx->rj lives on the heap inside the ctx, so the
// close reads valid memory whether it runs here or later in the finalizer.
static void write_handle_error(SEXP tiff_closer, const char *message, ...) {
  char buf[1024];
  va_list args;
  va_start(args, message);
  vsnprintf(buf, sizeof(buf), message, args);
  va_end(args);
  cleanup_tiff_ptr(tiff_closer);
  Rf_error("%s", buf);
}

// Helper function to set a float tag if not NULL
static void set_float_tag_if_provided(TIFF *tiff, SEXP value, ttag_t tag) {
  if (value != R_NilValue) {
    float val = (float)asReal(value);
    TIFFSetField(tiff, tag, val);
  }
}

// Helper function to set an integer tag if not NULL
static void set_int_tag_if_provided(TIFF *tiff, SEXP value, ttag_t tag) {
  if (value != R_NilValue) {
    int val = asInteger(value);
    TIFFSetField(tiff, tag, val);
  }
}

// Helper function to set a string tag if not NULL
static void set_string_tag_if_provided(TIFF *tiff, SEXP value, ttag_t tag) {
  if (value != R_NilValue) {
    const char* val = CHAR(STRING_ELT(value, 0));
    TIFFSetField(tiff, tag, val);
  }
}

// Helper function to set all required TIFF fields
static void set_required_tiff_fields(TIFF *tiff, uint32_t width, uint32_t height,
                                    uint32_t planes, int bps, int compression,
                                    bool floats, int photometric) {
  TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, width);
  TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, height);
  TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, 1);
  TIFFSetField(tiff, TIFFTAG_SOFTWARE, "ijtiff package, R " R_MAJOR "." R_MINOR);
  TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, bps);
  TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, planes);
  TIFFSetField(tiff, TIFFTAG_SAMPLEFORMAT, floats ? SAMPLEFORMAT_IEEEFP : SAMPLEFORMAT_UINT);
  TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, height);
  TIFFSetField(tiff, TIFFTAG_COMPRESSION, compression);
  TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, photometric);
  // Set ExtraSamples ONLY for RGBA (RGB + 4th alpha plane). Do NOT touch the
  // MINISBLACK path -- adding ExtraSamples there would change the bytes of
  // every existing multi-channel write for no functional gain.
  if (photometric == PHOTOMETRIC_RGB && planes == 4) {
    uint16_t extra[1] = { EXTRASAMPLE_UNASSALPHA };
    TIFFSetField(tiff, TIFFTAG_EXTRASAMPLES, 1, extra);
  }
}

// Helper function to set all optional TIFF tags
static void set_optional_tiff_tags(TIFF *tiff, SEXP sXResolution, SEXP sYResolution,
                                  SEXP sResolutionUnit, SEXP sOrientation,
                                  SEXP sXPosition, SEXP sYPosition, SEXP sCopyright,
                                  SEXP sArtist, SEXP sDocumentName, SEXP sDateTime,
                                  SEXP sImageDescription) {
  set_float_tag_if_provided(tiff, sXResolution, TIFFTAG_XRESOLUTION);
  set_float_tag_if_provided(tiff, sYResolution, TIFFTAG_YRESOLUTION);
  set_float_tag_if_provided(tiff, sXPosition, TIFFTAG_XPOSITION);
  set_float_tag_if_provided(tiff, sYPosition, TIFFTAG_YPOSITION);

  set_int_tag_if_provided(tiff, sResolutionUnit, TIFFTAG_RESOLUTIONUNIT);
  set_int_tag_if_provided(tiff, sOrientation, TIFFTAG_ORIENTATION);

  set_string_tag_if_provided(tiff, sCopyright, TIFFTAG_COPYRIGHT);
  set_string_tag_if_provided(tiff, sArtist, TIFFTAG_ARTIST);
  set_string_tag_if_provided(tiff, sDocumentName, TIFFTAG_DOCUMENTNAME);
  set_string_tag_if_provided(tiff, sDateTime, TIFFTAG_DATETIME);
  set_string_tag_if_provided(tiff, sImageDescription, TIFFTAG_IMAGEDESCRIPTION);
}

// Helper function to copy data from R array to TIFF buffer
static void copy_data_to_buffer(tdata_t buf, double *real_arr, uint32_t width, 
                               uint32_t height, uint32_t planes, int bps, bool floats) {
  uint32_t x, y, pl;
  if (floats) {
    float *data_float = (float*) buf;
    for (y = 0; y < height; y++) {
      for (x = 0; x < width; x++) {
        for (pl = 0; pl < planes; pl++) {
          data_float[(x + y * width) * planes + pl] =
            (float) real_arr[y + x * height + pl * width * height];
        }
      }
    }
  } else {
    for (y = 0; y < height; y++) {
      for (x = 0; x < width; x++) {
        for (pl = 0; pl < planes; pl++) {
          size_t buf_idx = (x + y * width) * planes + pl;
          double val = real_arr[y + x * height + pl * width * height];
          if (bps == 8) {
            ((uint8_t*)buf)[buf_idx] = (uint8_t)val;
          } else if (bps == 16) {
            ((uint16_t*)buf)[buf_idx] = (uint16_t)val;
          } else if (bps == 32) {
            ((uint32_t*)buf)[buf_idx] = (uint32_t)val;
          }
        }
      }
    }
  }
}

SEXP write_tif_C(SEXP image, SEXP where, SEXP sBPS, SEXP sCompr, SEXP sFloats,
                SEXP sXResolution, SEXP sYResolution, SEXP sResolutionUnit,
                SEXP sOrientation, SEXP sXPosition, SEXP sYPosition,
                SEXP sCopyright, SEXP sArtist, SEXP sDocumentName, SEXP sDateTime,
                SEXP sImageDescription, SEXP sPhotometric) {
  check_type_sizes();

  // Photometric interpretation: default MINISBLACK unless the R side has
  // resolved an explicit/auto-extracted writable photometric code.
  int photometric = (sPhotometric == R_NilValue)
      ? PHOTOMETRIC_MINISBLACK : asInteger(sPhotometric);
  
  // Validate and extract basic parameters
  int bps = asInteger(sBPS);
  if (bps != 8 && bps != 16 && bps != 32)
    Rf_error("currently bits_per_sample must be 8, 16 or 32");
  
  int compression = asInteger(sCompr);
  bool floats = asLogical(sFloats);
  
  // Handle image list or single image
  SEXP dims, img_list = 0;
  int img_index = 0;
  int n_img = 1;
  
  if (TYPEOF(image) == VECSXP) {  // if the image was specified as a list
    if ((n_img = LENGTH(image)) == 0) {
      Rf_warning("empty image list, nothing to do");
      return R_NilValue;
    }
    img_list = image;
  }
  
  // Heap-allocate the TIFF context and register its finalizer BEFORE opening,
  // so a failed open still frees the ctx via the finalizer. The job state
  // (ctx->rj) lives inside the ctx on the heap, so cleanup_tiff_ptr always
  // closes against valid memory even if a libtiff-internal error longjmps out.
  // For the in-memory job, TIFFClose's close proc frees ctx->rj.data because
  // ctx->rj.alloc != 0. write_tif_C's OWN post-open errors close synchronously
  // via write_handle_error (which calls cleanup_tiff_ptr); on the success paths
  // we also call cleanup_tiff_ptr, which clears the external pointer so the
  // finalizer can never double-close.
  tiff_ctx_t *ctx;
  SEXP tiff_closer = PROTECT(new_tiff_ctx(&ctx));

  // Open output: filename (STRSXP) or in-memory buffer (where == NULL)
  int to_memory = (where == R_NilValue);
  if (to_memory) {
    ctx->rj.alloc = 256 * 1024;   // non-zero alloc => close proc owns/frees data
    ctx->rj.data = malloc(ctx->rj.alloc);
    if (!ctx->rj.data) Rf_error("unable to allocate in-memory output buffer");
    ctx->rj.len = 0; ctx->rj.ptr = 0; ctx->rj.f = NULL;
  } else {
    if (TYPEOF(where) != STRSXP || LENGTH(where) != 1)
      Rf_error("invalid filename");
    const char *fn = CHAR(STRING_ELT(where, 0));
    ctx->rj.f = fopen(fn, "w+b");
    if (!ctx->rj.f) Rf_error("unable to create %s", fn);
  }

  TIFF *tiff = TIFF_Open("wm", &ctx->rj);
  if (!tiff) {
    // ctx->tiff is still NULL, so the finalizer won't TIFFClose (and thus won't
    // free ctx->rj.data via the close proc); free the in-memory buffer here.
    if (to_memory) { free(ctx->rj.data); ctx->rj.data = NULL; }
    Rf_error("cannot create TIFF structure");
  }

  // Store the handle in the ctx so the finalizer can close it.
  ctx->tiff = tiff;

  // Process each image
  while (true) {
    // Get current image from list if applicable
    if (img_list) image = VECTOR_ELT(img_list, img_index++);
    
    // Validate image (handle is open here: close synchronously on error)
    if (TYPEOF(image) != REALSXP && TYPEOF(image) != INTSXP)
      write_handle_error(tiff_closer, "image must be a numeric array");

    dims = Rf_getAttrib(image, R_DimSymbol);
    if (dims == R_NilValue || TYPEOF(dims) != INTSXP ||
        LENGTH(dims) < 2 || LENGTH(dims) > 3) {
      write_handle_error(tiff_closer,
                         "image must be an array of two or three dimensions");
    }
    
    // Extract image dimensions
    uint32_t width = INTEGER(dims)[1];
    uint32_t height = INTEGER(dims)[0];
    uint32_t planes = 1;
    if (LENGTH(dims) == 3) planes = INTEGER(dims)[2];
    
    // Set required and optional TIFF fields
    set_required_tiff_fields(tiff, width, height, planes, bps, compression, floats,
                            photometric);
    set_optional_tiff_tags(tiff, sXResolution, sYResolution, sResolutionUnit,
                          sOrientation, sXPosition, sYPosition, sCopyright,
                          sArtist, sDocumentName, sDateTime, sImageDescription);
    
    // Allocate and fill buffer
    tdata_t buf = _TIFFmalloc(width * height * planes * (bps / 8));
    if (!buf) write_handle_error(tiff_closer, "cannot allocate output image buffer");
    
    double *real_arr = REAL(image);
    copy_data_to_buffer(buf, real_arr, width, height, planes, bps, floats);
    
    // Write data and clean up
    TIFFWriteEncodedStrip(tiff, 0, buf, width * height * planes * (bps / 8));
    _TIFFfree(buf);
    
    // Move to next directory or exit loop
    if (img_list && img_index < n_img) {
      TIFFWriteDirectory(tiff);
    } else {
      break;
    }
  }
  
  if (to_memory) {
    SEXP res;
    TIFFFlush(tiff);
    // Extract bytes BEFORE close: cleanup_tiff_ptr's TIFFClose frees ctx->rj.data.
    res = PROTECT(allocVector(RAWSXP, ctx->rj.len));
    memcpy(RAW(res), ctx->rj.data, ctx->rj.len);
    cleanup_tiff_ptr(tiff_closer);  // TIFFClose frees rj.data, frees ctx, clears ptr
    UNPROTECT(2);      // res + tiff_closer
    return res;
  }
  cleanup_tiff_ptr(tiff_closer);  // TIFFClose, free ctx, clear ptr
  UNPROTECT(1);        // tiff_closer
  return ScalarInteger(n_img);
}
