#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>
#include <limits.h>

#include "common.h"

#include <Rinternals.h>
#include <Rversion.h>

// Format the message, close+neutralize the TIFF handle while rj is still on the
// live stack, then raise the R error. Mirrors read.c's handle_error: rj is a
// stack local in write_tif_C, so the close MUST happen synchronously here (while
// rj is alive) -- deferring it to the external-pointer finalizer would run
// TIFFClose against a dead stack frame. cleanup_tiff_ptr does TIFFClose (which,
// for the in-memory job, frees rj.data because rj.alloc != 0) +
// R_ClearExternalPtr (so the finalizer cannot re-close) + resets last_tiff.
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
                                    bool floats) {
  TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, width);
  TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, height);
  TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, 1);
  TIFFSetField(tiff, TIFFTAG_SOFTWARE, "ijtiff package, R " R_MAJOR "." R_MINOR);
  TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, bps);
  TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, planes);
  TIFFSetField(tiff, TIFFTAG_SAMPLEFORMAT, floats ? SAMPLEFORMAT_IEEEFP : SAMPLEFORMAT_UINT);
  TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, height);
  TIFFSetField(tiff, TIFFTAG_COMPRESSION, compression);
  TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
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
                SEXP sImageDescription) {
  check_type_sizes();
  
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
  
  // Open output: filename (STRSXP) or in-memory buffer (where == NULL)
  tiff_job_t rj;
  memset(&rj, 0, sizeof(rj));
  int to_memory = (where == R_NilValue);
  if (to_memory) {
    rj.alloc = 256 * 1024;   // non-zero alloc => close proc owns/frees rj.data
    rj.data = malloc(rj.alloc);
    if (!rj.data) Rf_error("unable to allocate in-memory output buffer");
    rj.len = 0; rj.ptr = 0; rj.f = NULL;
  } else {
    if (TYPEOF(where) != STRSXP || LENGTH(where) != 1)
      Rf_error("invalid filename");
    const char *fn = CHAR(STRING_ELT(where, 0));
    rj.f = fopen(fn, "w+b");
    if (!rj.f) Rf_error("unable to create %s", fn);
  }

  TIFF *tiff = TIFF_Open("wm", &rj);
  if (!tiff) {
    if (to_memory) free(rj.data);
    Rf_error("cannot create TIFF structure");
  }

  // write_tif_C has no other owner of the handle, so register an
  // external-pointer finalizer exactly like read_tif_C, as a backstop for a
  // libtiff-internal error that longjmps past the manual TIFFClose (without it
  // that leaks the TIFF handle and, for the in-memory job, the malloc'd rj.data
  // buffer). cleanup_tiff_ptr closes once when tiff_closer becomes unreachable,
  // and the in-memory close proc frees rj.data because rj.alloc != 0.
  // write_tif_C's OWN post-open errors instead close synchronously via
  // write_handle_error (rj is a stack local, so the close must happen while rj
  // is still alive rather than being deferred to the finalizer). On the success
  // paths we close manually and R_ClearExternalPtr so the finalizer can never
  // double-close.
  SEXP tiff_closer = PROTECT(R_MakeExternalPtr(NULL, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(tiff_closer, (R_CFinalizer_t)cleanup_tiff_ptr, TRUE);
  R_SetExternalPtrAddr(tiff_closer, tiff);

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
    set_required_tiff_fields(tiff, width, height, planes, bps, compression, floats);
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
    res = PROTECT(allocVector(RAWSXP, rj.len));  // extract bytes BEFORE close
    memcpy(RAW(res), rj.data, rj.len);
    TIFFClose(tiff);   // frees rj.data via close proc
    R_ClearExternalPtr(tiff_closer);  // finalizer must not double-close
    UNPROTECT(2);      // res + tiff_closer
    return res;
  }
  TIFFClose(tiff);
  R_ClearExternalPtr(tiff_closer);  // finalizer must not double-close
  UNPROTECT(1);        // tiff_closer
  return ScalarInteger(n_img);
}
