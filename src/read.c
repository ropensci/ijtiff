#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#include "common.h"
#include "tags.h"

#include <Rinternals.h>

// Helper function for finalizers that safely close a TIFF pointer
static void cleanup_tiff_ptr(SEXP ptr) {
    if (!ptr) return;
    TIFF *tiff = (TIFF*)R_ExternalPtrAddr(ptr);
    if (tiff) {
        // If this is the last_tiff, clear that global reference too
        if (tiff == last_tiff) {
            last_tiff = NULL;
        }
        TIFFClose(tiff);
        R_ClearExternalPtr(ptr);
    }
}

// Helper function to validate filename and open TIFF file
static TIFF* validate_and_open_tiff(SEXP sFn, tiff_job_t *rj, FILE **f, const char **fn) {
    if (TYPEOF(sFn) != STRSXP || LENGTH(sFn) < 1) Rf_error("invalid filename");
    *fn = CHAR(STRING_ELT(sFn, 0));
    memset(rj, 0, sizeof(tiff_job_t));
    return open_tiff_file(*fn, rj, f);
}

// Helper function to handle errors with proper cleanup
static void handle_error(TIFF *tiff, FILE *f, const char *message, ...) {
    va_list args;
    va_start(args, message);
    TIFFClose(tiff);
    Rf_error(message, args);
    va_end(args);
}

// Helper function to copy pixel value based on bit depth and type
static double get_pixel_value(const unsigned char *v, uint16_t bps, bool is_float) {
    if (bps == 8) {
        return (double)v[0];
    } else if (bps == 16) {
        return (double)((const uint16_t*)v)[0];
    } else if (bps == 32) {
        if (is_float) {
            return (double)((const float*)v)[0];
        } else {
            return (double)((const uint32_t*)v)[0];
        }
    }
    return NA_REAL;
}

// Helper function to set pixel values for multiple samples
static void set_pixel_values(double *real_arr, const unsigned char *v, uint16_t bps, 
                            uint16_t spp, bool is_float, uint32_t imageLength, 
                            uint32_t imageWidth, uint32_t x, uint32_t y) {
    size_t j;
    for (j = 0; j < spp; j++) {
        size_t offset = (imageLength * imageWidth * j) + imageLength * x + y;
        if (bps == 8) {
            real_arr[offset] = (double)v[j];
        } else if (bps == 16) {
            real_arr[offset] = (double)((const uint16_t*)v)[j];
        } else if (bps == 32) {
            if (is_float) {
                real_arr[offset] = (double)((const float*)v)[j];
            } else {
                real_arr[offset] = (double)((const uint32_t*)v)[j];
            }
        }
    }
}

SEXP read_tif_C(SEXP sFn /*filename*/, SEXP sDirs) {
    check_type_sizes();
    int to_unprotect = 0;
    SEXP multi_res = R_NilValue;
    SEXP multi_tail = multi_res;
    SEXP res = R_NilValue;
    SEXP dim = R_NilValue;
    const char *fn;
    TIFF *tiff = NULL;
    FILE *f = NULL;
    tiff_job_t rj;
    
    // Create a protected pointer for TIFF cleanup
    SEXP tiff_closer = PROTECT(R_MakeExternalPtr(NULL, R_NilValue, R_NilValue));
    to_unprotect++;
    
    // Set up finalizer that checks if pointer is NULL before closing
    R_RegisterCFinalizerEx(tiff_closer, (R_CFinalizer_t)cleanup_tiff_ptr, TRUE);
    
    tiff = validate_and_open_tiff(sFn, &rj, &f, &fn);
    
    if (!tiff) {
        Rf_error("Failed to open TIFF file");
    }
    
    // Store the TIFF pointer
    R_SetExternalPtrAddr(tiff_closer, tiff);
    
    int cur_dir = 0; // 1-based image number
    int *sDirs_intptr = INTEGER(sDirs), cur_sDir_index = 0;
    int sDirs_len = LENGTH(sDirs);
    while (cur_sDir_index != sDirs_len) {  // read only from images in desired directories
        ++cur_dir;
        bool is_match = cur_dir == sDirs_intptr[cur_sDir_index];
        if (is_match) {
            ++cur_sDir_index;
        } else {
            if (TIFFReadDirectory(tiff)) {
                continue;
            } else {
                break;  // safety net: I don't expect this line to ever be needed
            }
        }
        uint32_t imageWidth = 0, imageLength = 0, imageDepth;
        uint32_t tileWidth, tileLength;
        uint32_t x, y;
        uint16_t config, bps = 8, spp = 1, sformat = 1, out_spp;
        tdata_t buf;
        double *real_arr;
        uint16_t *colormap[3] = {0, 0, 0};
        bool is_float = false;
        TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &imageWidth);
        TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &imageLength);
        if (!TIFFGetField(tiff, TIFFTAG_IMAGEDEPTH, &imageDepth)) imageDepth = 0;
        if (TIFFGetField(tiff, TIFFTAG_TILEWIDTH, &tileWidth)) {
            TIFFGetField(tiff, TIFFTAG_TILELENGTH, &tileLength);
        } else {  // no tiles
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
            if (colormap[2]) {
                out_spp = 3;
            } else if (colormap[1]) {
                out_spp = 2;
            }
        }
        #if TIFF_DEBUG
            Rprintf("image %d x %d x %d, tiles %d x %d, bps = %d, spp = %d (output %d), "
                    "config = %d, colormap = %s\n",
                    imageWidth, imageLength, imageDepth, tileWidth, tileLength, bps, spp,
                    out_spp, config, colormap[0] ? "yes" : "no");
        #endif
        if (bps == 12) {
            handle_error(tiff, f, "12-bit images are not supported. "
                     "Try converting your image to 16-bit.");
        }
        if (bps != 8 && bps != 16 && bps != 32) {
            handle_error(tiff, f, "image has %d bits/sample which is unsupported", bps);
        }
        if (sformat == SAMPLEFORMAT_INT)
            Rf_warning("The \'ijtiff\' package only supports unsigned "
                       "integer or float sample formats, but your image contains "
                       "the signed integer format.");
        res = Rf_protect(allocVector(REALSXP, imageWidth * imageLength * out_spp));
        to_unprotect++;  // res needs to be UNPROTECTed later
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
                if (spp == 1) { // config doesn't matter for spp == 1
                    if (colormap[0]) {
                        tsize_t i, step = bps / 8;
                        for (i = 0; i < n; i += step) {
                            uint32_t ci = 0;
                            const uint8_t *v = (const uint8_t*) buf + i;
                            if (bps == 8) {
                                ci = v[0];
                            } else if (bps == 16) {
                                ci = ((const uint16_t*)v)[0];
                            } else if (bps == 32) {
                                ci = ((const uint32_t*)v)[0];
                            }
                            if (is_float) {
                                real_arr[imageLength * x + y] = (double) colormap[0][ci];
                                // color maps are always 16-bit
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
                                // color maps are always 16-bit
                                if (colormap[1]) {
                                    real_arr[(imageLength * imageWidth) + imageLength * x + y] =
                                        colormap[1][ci];
                                    if (colormap[2]) {
                                        real_arr[(2 * imageLength * imageWidth) +
                                                 imageLength * x + y] = colormap[2][ci];
                                    }
                                }
                            }
                            x++;
                            if (x >= imageWidth) {
                                x -= imageWidth;
                                y++;
                            }
                        }
                    } else { // direct gray
                        tsize_t i, step = bps / 8;
                        for (i = 0; i < n; i += step) {
                            const uint8_t *v = (const uint8_t*) buf + i;
                            real_arr[imageLength * x + y] = get_pixel_value(v, bps, is_float);
                            x++;
                            if (x >= imageWidth) {
                                x -= imageWidth;
                                y++;
                            }
                        }
                    }
                } else if (config == PLANARCONFIG_CONTIG) { // interlaced
                    tsize_t i, step = spp * bps / 8;
                    for (i = 0; i < n; i += step) {
                        const uint8_t *v = (const uint8_t*) buf + i;
                        set_pixel_values(real_arr, v, bps, spp, is_float, imageLength, imageWidth, x, y);
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
                        real_arr[plane_offset + imageLength * x + y] = get_pixel_value(v, bps, is_float);
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
        } else {  // tiled image
            if (spp > 1 && config != PLANARCONFIG_CONTIG) {
                handle_error(tiff, f, "Planar format tiled images are not supported");
            }

            #if TIFF_DEBUG
                Rprintf(" - %d x %d tiles\n", TIFFNumberOfTiles(tiff), TIFFTileSize(tiff));
            #endif
            x = 0; y = 0;
            buf = _TIFFmalloc(TIFFTileSize(tiff));

            for (y = 0; y < imageLength; y += tileLength) {
                for (x = 0; x < imageWidth; x += tileWidth) {
                    tsize_t n = TIFFReadTile(tiff, buf, x, y, 0 /*depth*/, 0 /*plane*/);
                    if (spp == 1) { // config doesn't matter for spp == 1
                        // direct gray */
                        tsize_t i, step = bps / 8;
                        uint32_t xoff = 0, yoff = 0;
                        for (i = 0; i < n; i += step) {
                            const unsigned char *v = (const unsigned char*) buf + i;
                            if (x + xoff < imageWidth && y + yoff < imageLength) {
                                real_arr[imageLength * (x + xoff) + y + yoff] = get_pixel_value(v, bps, is_float);
                            }
                            xoff++;
                            if (xoff >= tileWidth) {
                                xoff -= tileWidth;
                                yoff++;
                            }
                        }
                    } else if (config == PLANARCONFIG_CONTIG) {  // spp > 1, interlaced
                        tsize_t i, step = spp * bps / 8;
                        uint32_t xoff = 0, yoff = 0;
                        for (i = 0; i < n; i += step) {
                            const unsigned char *v = (const uint8_t*) buf + i;
                            if (x + xoff < imageWidth && y + yoff < imageLength) {
                                set_pixel_values(real_arr, v, bps, spp, is_float, imageLength, imageWidth, x + xoff, y + yoff);
                            }
                            xoff++;
                            if (xoff >= tileWidth) {
                                xoff -= tileWidth;
                                yoff++;
                            }
                        }
                    }
                }
            }
        }
        _TIFFfree(buf);
        dim = Rf_protect(allocVector(INTSXP, (out_spp > 1) ? 3 : 2));
        to_unprotect++;
        INTEGER(dim)[0] = imageLength;
        INTEGER(dim)[1] = imageWidth;
        if (out_spp > 1) INTEGER(dim)[2] = out_spp;
        setAttrib(res, R_DimSymbol, dim);
        Rf_unprotect(1);  // UNPROTECT `dim`
        to_unprotect--;
        if (multi_res == R_NilValue) {  // first image in stack
            multi_res = multi_tail = Rf_protect(Rf_list1(res));
            to_unprotect++;  // `multi_res` needs to be UNPROTECTed later
        } else {
            SEXP q = Rf_protect(Rf_list1(res));
            to_unprotect++;
            SETCDR(multi_tail, q);  // `q` is now PROTECTed as part of `multi_tail`
            multi_tail = q;
            Rf_unprotect(2);  // removing explit PROTECTion of `q` UNPROTECTing `res`
            to_unprotect -= 2;
        }
        if (!TIFFReadDirectory(tiff))
            break;
    }
    // Clear the external pointer to avoid double closing
    TIFFClose(tiff);
    R_ClearExternalPtr(tiff_closer);
    
    res = Rf_protect(PairToVectorList(multi_res));  // convert LISTSXP into VECSXP
    to_unprotect++;
    Rf_unprotect(to_unprotect);
    return res;
}

SEXP count_directories_C(SEXP sFn /*FileName*/) {
    check_type_sizes();
    int to_unprotect = 0;
    SEXP res = Rf_protect(allocVector(REALSXP, 1));
    to_unprotect++;
    const char *fn;
    tiff_job_t rj;
    TIFF *tiff = NULL;
    FILE *f = NULL;
    
    // Create a protected pointer for TIFF cleanup
    SEXP tiff_closer = PROTECT(R_MakeExternalPtr(NULL, R_NilValue, R_NilValue));
    to_unprotect++;
    
    // Set up finalizer that checks if pointer is NULL before closing
    R_RegisterCFinalizerEx(tiff_closer, (R_CFinalizer_t)cleanup_tiff_ptr, TRUE);
    
    tiff = validate_and_open_tiff(sFn, &rj, &f, &fn);
    
    if (!tiff) {
        Rf_error("Failed to open TIFF file");
    }
    
    // Store the TIFF pointer
    R_SetExternalPtrAddr(tiff_closer, tiff);
    
    R_xlen_t cur_dir = 0; // 1-based image number
    while (1) {  // loop over TIFF directories
        cur_dir++;
        if (!TIFFReadDirectory(tiff)) break;
    }
    
    TIFFClose(tiff);
    // Clear the external pointer to avoid double closing
    R_ClearExternalPtr(tiff_closer);
    
    REAL(res)[0] = cur_dir;
    Rf_unprotect(to_unprotect);
    return res;
}
