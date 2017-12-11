#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#include "common.h"

#include <Rinternals.h>

/* avoid protection issues with setAttrib where new symbols may trigger GC probelms */
static void setAttr(SEXP x, const char *name, SEXP val) {
    PROTECT(val);
    setAttrib(x, Rf_install(name), val);
    UNPROTECT(1);
}

/* add information attributes accorsing to the TIFF tags.
   Only a somewhat random set (albeit mostly baseline) is supported */
static void TIFF_add_info(TIFF *tiff, SEXP res) {
  uint32 i32;
  uint16 i16;
  float f;
  char *c = 0;

  if (TIFFGetField(tiff, TIFFTAG_IMAGEDEPTH, &i32))
	  setAttr(res, "depth", ScalarInteger(i32));
  if (TIFFGetField(tiff, TIFFTAG_BITSPERSAMPLE, &i16))
	  setAttr(res, "bits_per_sample", ScalarInteger(i16));
  if (TIFFGetField(tiff, TIFFTAG_SAMPLESPERPIXEL, &i16))
	  setAttr(res, "samples_per_pixel", ScalarInteger(i16));
  if (TIFFGetField(tiff, TIFFTAG_SAMPLEFORMAT, &i16)) {
  	char uv[24];
  	const char *name = 0;
  	switch (i16) {
  	case 1: name = "uint"; break;
  	case 2: name = "int"; break;
  	case 3: name = "float"; break;
  	case 4: name = "undefined"; break;
  	case 5: name = "complex int"; break;
  	case 6: name = "complex float"; break;
  	default:
  	  snprintf(uv, sizeof(uv), "unknown (%d)", i16);
  	  name = uv;
  	}
	  setAttr(res, "sample_format", mkString(name));
  } else {
    setAttr(res, "sample_format", mkString("uint"));
  }
  if (TIFFGetField(tiff, TIFFTAG_PLANARCONFIG, &i16)) {
	  if (i16 == PLANARCONFIG_CONTIG) {
	    setAttr(res, "planar_config", mkString("contiguous"));
	  }	else if (i16 == PLANARCONFIG_SEPARATE) {
	    setAttr(res, "planar_config", mkString("separate"));
	  }	else {
	    char uv[24];
	    snprintf(uv, sizeof(uv), "unknown (%d)", i16);
	    setAttr(res, "planar_config", mkString(uv));
	  }
  }
    if (TIFFGetField(tiff, TIFFTAG_COMPRESSION, &i16)) {  // working here
	char uv[24];
	const char *name = 0;
	switch (i16) {
	case 1: name = "none"; break;
	case 2: name = "CCITT RLE"; break;
	case 32773: name = "PackBits"; break;
	case 3: name = "CCITT Group 3 fax"; break;
	case 4: name = "CCITT Group 4 fax"; break;
	case 5: name = "LZW"; break;
	case 6: name = "old JPEG"; break;
	case 7: name = "JPEG"; break;
	case 8: name = "deflate"; break;
	case 9: name = "JBIG b/w"; break;
	case 10: name = "JBIG color"; break;
	default:
	    snprintf(uv, sizeof(uv), "unknown (%d)", i16);
	    name = uv;
	}
	setAttr(res, "compression", mkString(name));
    }
    if (TIFFGetField(tiff, TIFFTAG_THRESHHOLDING, &i16))
	setAttr(res, "threshholding", ScalarInteger(i16));
    if (TIFFGetField(tiff, TIFFTAG_XRESOLUTION, &f))
	setAttr(res, "x_resolution", ScalarReal(f));
    if (TIFFGetField(tiff, TIFFTAG_YRESOLUTION, &f))
	setAttr(res, "y_resolution", ScalarReal(f));
    if (TIFFGetField(tiff, TIFFTAG_RESOLUTIONUNIT, &i16)) {
	const char *name = "unknown";
	switch (i16) {
	case 1: name = "none"; break;
	case 2: name = "inch"; break;
	case 3: name = "cm"; break;
	}
	setAttr(res, "resolution_unit", mkString(name));
    }
#ifdef TIFFTAG_INDEXED /* very recent in libtiff even though it's an old tag */
    if (TIFFGetField(tiff, TIFFTAG_INDEXED, &i16))
	setAttr(res, "indexed", ScalarLogical(i16));
#endif
    if (TIFFGetField(tiff, TIFFTAG_ORIENTATION, &i16)) {
	const char *name = "<invalid>";
	switch (i16) {
	case 1: name = "top_left"; break;
	case 2: name = "top_right"; break;
	case 3: name = "bottom_right"; break;
	case 4: name = "bottom_left"; break;
	case 5: name = "left_top"; break;
	case 6: name = "right_top"; break;
	case 7: name = "right_bottom"; break;
	case 8: name = "left_bottom"; break;
	}
	setAttr(res, "orientation", mkString(name));
    }
    if (TIFFGetField(tiff, TIFFTAG_COPYRIGHT, &c) && c)
	setAttr(res, "copyright", mkString(c));
    if (TIFFGetField(tiff, TIFFTAG_ARTIST, &c) && c)
	setAttr(res, "artist", mkString(c));
    if (TIFFGetField(tiff, TIFFTAG_DOCUMENTNAME, &c) && c)
	setAttr(res, "document_name", mkString(c));
    if (TIFFGetField(tiff, TIFFTAG_DATETIME, &c) && c)
	setAttr(res, "date_time", mkString(c));
    if (TIFFGetField(tiff, TIFFTAG_IMAGEDESCRIPTION, &c) && c)
	setAttr(res, "description", mkString(c));
    if (TIFFGetField(tiff, TIFFTAG_SOFTWARE, &c) && c)
	setAttr(res, "software", mkString(c));
    if (TIFFGetField(tiff, TIFFTAG_PHOTOMETRIC, &i16)) {
	char uv[24];
	const char *name = 0;
	switch (i16) {
	case 0: name = "white is zero"; break;
	case 1: name = "black is zero"; break;
	case 2: name = "RGB"; break;
	case 3: name = "palette"; break;
	case 4: name = "mask"; break;
	case 5: name = "separated"; break;
	case 6: name = "YCbCr"; break;
	case 8: name = "CIELAB"; break;
	case 9: name = "ICCLab"; break;
	case 10: name = "ITULab"; break;
	default:
	    snprintf(uv, sizeof(uv), "unknown (%d)", i16);
	    name = uv;
	}
	setAttr(res, "color_space", mkString(name));
    }
}

SEXP read_tif_c(SEXP sFn /*filename*/) {
  check_type_sizes();
  SEXP res = R_NilValue, multi_res = R_NilValue, multi_tail = R_NilValue, dim;
  const char *fn;
  int n_img = 0;
  tiff_job_t rj;
  TIFF *tiff;
  FILE *f;
	if (TYPEOF(sFn) != STRSXP || LENGTH(sFn) != 1) Rf_error("invalid filename");
	fn = CHAR(STRING_ELT(sFn, 0));
	f = fopen(fn, "rb");
	if (!f) {
	  Rf_error("unable to open %s", fn);
	  return R_NilValue;
	}
	rj.f = f;
  tiff = TIFF_Open("rmc", &rj); /* no mmap, no chopping */
  if (!tiff) {
    Rf_error("Unable to open TIFF");
    return R_NilValue;
  }

  while (true) { /* loop over separate image in a directory if desired */
  	uint32 imageWidth = 0, imageLength = 0, imageDepth;
  	uint32 tileWidth, tileLength;
  	uint32 x, y;
  	uint16 config, bps = 8, spp = 1, sformat = 1, out_spp;
  	tdata_t buf;
  	double *real_arr;
  	uint16 *colormap[3] = {0, 0, 0};
  	bool is_float = false;

  	TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &imageWidth);
  	TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &imageLength);
  	if (!TIFFGetField(tiff, TIFFTAG_IMAGEDEPTH, &imageDepth)) imageDepth = 0;
  	if (TIFFGetField(tiff, TIFFTAG_TILEWIDTH, &tileWidth)) {
  	  TIFFGetField(tiff, TIFFTAG_TILELENGTH, &tileLength);
  	}	else {  // no tiles
  	  tileWidth = tileLength = 0;
  	}
  	TIFFGetField(tiff, TIFFTAG_PLANARCONFIG, &config);
  	TIFFGetField(tiff, TIFFTAG_BITSPERSAMPLE, &bps);
  	TIFFGetField(tiff, TIFFTAG_SAMPLESPERPIXEL, &spp);
  	out_spp = spp;
  	TIFFGetField(tiff, TIFFTAG_COLORMAP, colormap, colormap + 1, colormap + 2);
  	if (TIFFGetField(tiff, TIFFTAG_SAMPLEFORMAT, &sformat) &&
       sformat == SAMPLEFORMAT_IEEEFP) {
  	  is_float = true;
  	}
  	if (spp == 1) { /* modify out_spp for colormaps */
  	  if (colormap[2]) out_spp = 3;
  	  else if (colormap[1]) out_spp = 2;
  	}
    #if TIFF_DEBUG
  	  Rprintf("image %d x %d x %d, tiles %d x %d, bps = %d, spp = %d (output %d), "
              "config = %d, colormap = %s\n",
              imageWidth, imageLength, imageDepth, tileWidth, tileLength, bps, spp,
              out_spp, config, colormap[0] ? "yes" : "no");
    #endif

    if (bps == 12) {
      Rf_error("12-bit images are not supported. "
               "Try converting your image to 16-bit.");
      TIFFClose(tiff);
      return R_NilValue;
    }
  	if (bps != 8 && bps != 16 && bps != 32) {
  	    TIFFClose(tiff);
  	    Rf_error("image has %d bits/sample which is unsupported in direct mode - "
                  "use native=TRUE or convert=TRUE", bps);
  	    return R_NilValue;
  	}

  	if (sformat == SAMPLEFORMAT_INT)
  	    Rf_warning("The \'ijtiff\' package only supports unsigned "
                   "integer or float sample formats, but your image contains "
                    "the signed integer format.");

  	res = PROTECT(allocVector(REALSXP, imageWidth * imageLength * out_spp));
  	real_arr = REAL(res);

  	if (tileWidth == 0) {
  	  tstrip_t strip;
  	  tsize_t plane_offset = 0;
  	  x = 0; y = 0;
  	  buf = _TIFFmalloc(TIFFStripSize(tiff));
      #if TIFF_DEBUG
  	    Rprintf(" - %d x %d strips\n",
                TIFFNumberOfStrips(tiff), TIFFStripSize(tiff));
      #endif
    	for (strip = 0; strip < TIFFNumberOfStrips(tiff); strip++) {
    	  tsize_t n = TIFFReadEncodedStrip(tiff, strip, buf, (tsize_t) -1);
    	  if (spp == 1) { /* config doesn't matter for spp == 1 */
    	    if (colormap[0]) {
    	  	  tsize_t i, step = bps / 8;
    			  for (i = 0; i < n; i += step) {
    			    uint32_t ci = 0;
    			    const uint8_t *v = (const uint8_t*) buf + i;
    			    if (bps == 8) {
    			      ci = v[0];
    			    } else if (bps == 16) {
    			      ci = ((const uint16_t*) v)[0];
    			    } else if (bps == 32) {
    			      ci = ((const uint32_t*) v)[0];
    			    }
    			    if (is_float) {
    			      real_arr[imageLength * x + y] = (double) colormap[0][ci];
    			      /* color maps are always 16-bit */
    			      if (colormap[1]) {
    			        real_arr[(imageLength * imageWidth) + imageLength * x + y] =
    			          (double) colormap[1][ci];
    			        if (colormap[2]) {
    			          real_arr[(2 * imageLength * imageWidth) +
    			                    imageLength * x + y] = (double) colormap[2][ci];
    			        }
    			      }
    			    } else {
    				    real_arr[imageLength * x + y] = colormap[0][ci];
    			      /* color maps are always 16-bit */
    				    if (colormap[1]) {
    				      real_arr[(imageLength * imageWidth) + imageLength * x + y] =
    				        colormap[1][ci];
    				      if (colormap[2]) {
    					      real_arr[(2 * imageLength * imageWidth) + imageLength * x + y] =
    					        colormap[2][ci];
    				      }
    				    }
    			    }
    			    x++;
    			    if (x >= imageWidth) {
    				    x -= imageWidth;
    				    y++;
    			    }
    			  }
    		  } else { /* direct gray */
      			tsize_t i, step = bps / 8;
      			for (i = 0; i < n; i += step) {
      			  const uint8_t *v = (const uint8_t*) buf + i;
      			  if (is_float) {
      			    float float_val = NA_REAL;
      			    float_val = ((const float*) v)[0];
      			    real_arr[imageLength * x + y] = float_val;
      			  } else {
      			    int int_val = NA_INTEGER;
      			    if (bps == 8) {
      			      int_val = v[0];
      			    } else if (bps == 16) {
      			      int_val = ((const uint16_t*)v)[0];
      			    } else if (bps == 32) {
      			      int_val = ((const uint32_t*) v)[0];
      			    }
      			    real_arr[imageLength * x + y] = int_val;
      			  }
      				x++;
      			  if (x >= imageWidth) {
      				  x -= imageWidth;
      				  y++;
      			  }
      			}
    		  }
    		} else if (config == PLANARCONFIG_CONTIG) { /* interlaced */   //working here
    		  tsize_t i, j, step = spp * bps / 8;
    		  for (i = 0; i < n; i += step) {
    			  const uint8_t *v = (const uint8_t*) buf + i;
    			  if (bps == 8) {
    			    for (j = 0; j < spp; j++) {
       				  real_arr[(imageLength * imageWidth * j) + imageLength * x + y] =
       				    (uint8_t) v[j];
    			    }
    			  } else if (bps == 16) {
      			  for (j = 0; j < spp; j++) {
    	  			  real_arr[(imageLength * imageWidth * j) + imageLength * x + y] =
    		  		    (uint16_t) ((const uint16_t*)v)[j];
    			    }
      			} else if (bps == 32 && !is_float) {
    	  		  for (j = 0; j < spp; j++) {
    		  		  real_arr[(imageLength * imageWidth * j) + imageLength * x + y] =
    			  	    (uint32_t) ((const uint32_t*)v)[j];
    			    }
      			} else if (bps == 32 && is_float) {
    	  		  for (j = 0; j < spp; j++) {
    		  		real_arr[(imageLength * imageWidth * j) + imageLength * x + y] =
    			  	  (double) ((const float*)v)[j];
    	  		  }
      			}
    			  x++;
    			  if (x >= imageWidth) {
      			  x -= imageWidth;
    	  		  y++;
    		  	}
    			}
    		} else {  // separate
  		  tsize_t step = bps / 8, i;
    		  for (i = 0; i < n; i += step) {
    			  const unsigned char *v = (const unsigned char*) buf + i;
    			  if (bps == 8) {
    			    real_arr[plane_offset + imageLength * x + y] = (uint8_t) v[0];
    			  }	else if (bps == 16) {
    			    real_arr[plane_offset + imageLength * x + y] =
    			      (uint16_t) ((const uint16_t*)v)[0];
    			  }	else if (bps == 32 && !is_float) {
    			    real_arr[plane_offset + imageLength * x + y] =
    			      (uint32_t) ((const uint32*)v)[0];
    			  }	else if (bps == 32 && is_float) {
    			    real_arr[plane_offset + imageLength * x + y] =
    			      (double) ((const float*)v)[0];
    		    }
    		    x++;
    		    if (x >= imageWidth) {
    			    x -= imageWidth;
    			    y++;
    			    if (y >= imageLength) {
    			      y -= imageLength;
    			      plane_offset += imageWidth * imageLength;
    			    }
    		    }
    		  }
    		}
    	}
  	} else {
  	  Rf_error("tile-based images are not supported");
  	  buf = _TIFFmalloc(TIFFTileSize(tiff));

  	  for (y = 0; y < imageLength; y += tileLength) {
  		  for (x = 0; x < imageWidth; x += tileWidth) {
  		    TIFFReadTile(tiff, buf, x, y, 0 /*depth*/, 0 /*plane*/);
  		  }
  	  }
  	}

  	_TIFFfree(buf);

  	dim = allocVector(INTSXP, (out_spp > 1) ? 3 : 2);
  	INTEGER(dim)[0] = imageLength;
  	INTEGER(dim)[1] = imageWidth;
  	if (out_spp > 1) INTEGER(dim)[2] = out_spp;
  	setAttrib(res, R_DimSymbol, dim);
    TIFF_add_info(tiff, res);
  	UNPROTECT(1);
  	n_img++;
  	if (multi_res == R_NilValue) {
  	  multi_tail = multi_res = CONS(res, R_NilValue);
  	  PROTECT(multi_res);
  	} else {
  	  SEXP q = CONS(res, R_NilValue);
  	  SETCDR(multi_tail, q);
  	  multi_tail = q;
  	}
  	if (!TIFFReadDirectory(tiff)) break;
  }
  TIFFClose(tiff);
  /* convert LISTSXP into VECSXP */
  PROTECT(res = allocVector(VECSXP, n_img));
	int i = 0;
	while (multi_res != R_NilValue) {
	  SET_VECTOR_ELT(res, i, CAR(multi_res));
	  i++;
	  multi_res = CDR(multi_res);
	}
  UNPROTECT(2);
  return res;
}
