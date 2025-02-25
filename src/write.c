#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <limits.h>

#include "common.h"

#include <Rinternals.h>
#include <Rversion.h>


SEXP write_tif_C(SEXP image, SEXP where, SEXP sBPS, SEXP sCompr, SEXP sFloats, SEXP sXResolution, SEXP sYResolution, SEXP sResolutionUnit, SEXP sOrientation, SEXP sXPosition, SEXP sYPosition, SEXP sCopyright, SEXP sArtist, SEXP sDocumentName, SEXP sDateTime) {
  check_type_sizes();
  SEXP dims, img_list = 0;
  tiff_job_t rj;
  TIFF *tiff;
  FILE *f;
  int bps = asInteger(sBPS), compression = asInteger(sCompr),	img_index = 0;
  int n_img = 1;
  uint32_t width, height, planes = 1;
  bool floats = asLogical(sFloats);
  if (TYPEOF(image) == VECSXP) {  // if the image was specified as a list
	  if ((n_img = LENGTH(image)) == 0) {
	    Rf_warning("empty image list, nothing to do");
	    return R_NilValue;
	  }
	  img_list = image;
  }
  if (bps != 8 && bps != 16 && bps != 32)
	  Rf_error("currently bits_per_sample must be 8, 16 or 32");
	const char *fn;
	if (TYPEOF(where) != STRSXP || LENGTH(where) != 1)
	  Rf_error("invalid filename");
	fn = CHAR(STRING_ELT(where, 0));
	f = fopen(fn, "w+b");
	if (!f) Rf_error("unable to create %s", fn);
	rj.f = f;
  tiff = TIFF_Open("wm", &rj);
  if (!tiff) {
	  if (!rj.f) free(rj.data);
	  Rf_error("cannot create TIFF structure");
  }
  while (true) {
	  if (img_list) image = VECTOR_ELT(img_list, img_index++);
	  if (TYPEOF(image) != REALSXP && TYPEOF(image) != INTSXP)
	    Rf_error("image must be a numeric array");
  	dims = Rf_getAttrib(image, R_DimSymbol);
	  if (dims == R_NilValue || TYPEOF(dims) != INTSXP ||
          LENGTH(dims) < 2 || LENGTH(dims) > 3) {
	    Rf_error("image must be an array of two or three dimensions");
	  }
    width = INTEGER(dims)[1];
    height = INTEGER(dims)[0];
    if (LENGTH(dims) == 3) planes = INTEGER(dims)[2];
	  TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, width);
	  TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, height);
	  TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, 1);
	  TIFFSetField(tiff, TIFFTAG_SOFTWARE,
                "ijtiff package, R " R_MAJOR "." R_MINOR);
	  TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, bps);
	  TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, planes);
	  TIFFSetField(tiff, TIFFTAG_SAMPLEFORMAT,
                 floats ? SAMPLEFORMAT_IEEEFP : SAMPLEFORMAT_UINT);
	  TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, height);
	  TIFFSetField(tiff, TIFFTAG_COMPRESSION, compression);
	  TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
	  
	  // Set XRESOLUTION if provided
	  if (sXResolution != R_NilValue) {
	    float xres = (float)asReal(sXResolution);
	    TIFFSetField(tiff, TIFFTAG_XRESOLUTION, xres);
	  }
	  
	  // Set YRESOLUTION if provided
	  if (sYResolution != R_NilValue) {
	    float yres = (float)asReal(sYResolution);
	    TIFFSetField(tiff, TIFFTAG_YRESOLUTION, yres);
	  }
	  
	  // Set RESOLUTIONUNIT if provided
	  if (sResolutionUnit != R_NilValue) {
	    int unit = asInteger(sResolutionUnit);
	    TIFFSetField(tiff, TIFFTAG_RESOLUTIONUNIT, unit);
	  }
	  
	  // Set ORIENTATION if provided
	  if (sOrientation != R_NilValue) {
	    int orientation = asInteger(sOrientation);
	    TIFFSetField(tiff, TIFFTAG_ORIENTATION, orientation);
	  }
	  
	  // Set XPOSITION if provided
	  if (sXPosition != R_NilValue) {
	    float xpos = asReal(sXPosition);
	    TIFFSetField(tiff, TIFFTAG_XPOSITION, xpos);
	  }
	  
	  // Set YPOSITION if provided
	  if (sYPosition != R_NilValue) {
	    float ypos = asReal(sYPosition);
	    TIFFSetField(tiff, TIFFTAG_YPOSITION, ypos);
	  }
	  
	  // Set COPYRIGHT if provided
	  if (sCopyright != R_NilValue) {
	    const char* copyright = CHAR(STRING_ELT(sCopyright, 0));
	    TIFFSetField(tiff, TIFFTAG_COPYRIGHT, copyright);
	  }
	  
	  // Set ARTIST if provided
	  if (sArtist != R_NilValue) {
	    const char* artist = CHAR(STRING_ELT(sArtist, 0));
	    TIFFSetField(tiff, TIFFTAG_ARTIST, artist);
	  }
	  
	  // Set DOCUMENTNAME if provided
	  if (sDocumentName != R_NilValue) {
	    const char* documentname = CHAR(STRING_ELT(sDocumentName, 0));
	    TIFFSetField(tiff, TIFFTAG_DOCUMENTNAME, documentname);
	  }
	  
	  // Set DATETIME if provided
	  if (sDateTime != R_NilValue) {
	    const char* datetime = CHAR(STRING_ELT(sDateTime, 0));
	    TIFFSetField(tiff, TIFFTAG_DATETIME, datetime);
	  }
	  
	  uint32_t x, y, pl;
	  tdata_t buf = _TIFFmalloc(width * height * planes * (bps / 8));
	  float *data_float;
	  uint8_t *data8;
	  uint16_t *data16;
	  uint32_t *data32;
	  double *real_arr = REAL(image);
	  if (floats) {
	    data_float = (float*) buf;
	    if (!buf) Rf_error("cannot allocate output image buffer");
	    for (y = 0; y < height; y++) {
	      for (x = 0; x < width; x++) {
	        for (pl = 0; pl < planes; pl++) {
	          data_float[(x + y * width) * planes + pl] =
	            (float) real_arr[y + x * height + pl * width * height];
	        }
	      }
	    }
	  } else {
  	  if (bps == 8) {
  	    data8 = (uint8_t*) buf;
  	    if (!buf) Rf_error("cannot allocate output image buffer");
  		  for (y = 0; y < height; y++) {
  		    for (x = 0; x < width; x++) {
  			    for (pl = 0; pl < planes; pl++) {
  			      data8[(x + y * width) * planes + pl] =
  			        (uint8_t) (real_arr[y + x * height + pl * width * height]);
  			    }
  		    }
  		  }
  	  } else if (bps == 16) {
  	    data16 = (uint16_t*) buf;
  	    if (!buf) Rf_error("cannot allocate output image buffer");
  		  for (y = 0; y < height; y++) {
  		    for (x = 0; x < width; x++) {
  			    for (pl = 0; pl < planes; pl++) {
  			      data16[(x + y * width) * planes + pl] =
  			        (uint16_t) (real_arr[y + x * height +
  			                               pl * width * height]);
  			    }
  		    }
  		  }
  	  } else if (bps == 32) {
  	    data32 = (uint32_t*) buf;
  	    if (!buf) Rf_error("cannot allocate output image buffer");
  		  for (y = 0; y < height; y++) {
  		    for (x = 0; x < width; x++) {
  			    for (pl = 0; pl < planes; pl++) {
  			      data32[(x + y * width) * planes + pl] =
  			        (uint32_t) (real_arr[y + x * height + pl * width * height]);
  			    }
  		    }
  		  }
  	  }
	  }
	  TIFFWriteEncodedStrip(tiff, 0, buf, width * height * planes * (bps / 8));
	  _TIFFfree(buf);
	  if (img_list && img_index < n_img) {
	    TIFFWriteDirectory(tiff);
	  } else {
	    break;
	  }
  }
  TIFFClose(tiff);
  return ScalarInteger(n_img);
}
