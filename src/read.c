#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#include "common.h"

#include <Rinternals.h>

// Helper function to get tag value based on its type
static SEXP get_tag_value(TIFF *tiff, ttag_t tag, TIFFDataType type) {
    SEXP out = R_NilValue;
    
    // Special case for COLORMAP which needs 3 arrays
    if (tag == TIFFTAG_COLORMAP) {
        uint16_t bits_per_sample;
        uint16_t *red, *green, *blue;
        if (TIFFGetFieldDefaulted(tiff, TIFFTAG_BITSPERSAMPLE, &bits_per_sample) &&
            TIFFGetFieldDefaulted(tiff, tag, &red, &green, &blue)) {
            // quick way to calculate 2^bits_per_sample
            uint32_t map_size = 1 << bits_per_sample;
            SEXP colormap = PROTECT(allocMatrix(INTSXP, map_size, 3));
            int *colormap_ptr = INTEGER(colormap);
            for (uint32_t i = 0; i < map_size; i++) {
                colormap_ptr[i] = red[i];                    // red
                colormap_ptr[i + map_size] = green[i];      // green
                colormap_ptr[i + 2*map_size] = blue[i];     // blue
            }
            SEXP colnames = PROTECT(allocVector(STRSXP, 3));
            SET_STRING_ELT(colnames, 0, mkChar("red"));
            SET_STRING_ELT(colnames, 1, mkChar("green"));
            SET_STRING_ELT(colnames, 2, mkChar("blue"));
            SEXP dimnames = PROTECT(allocVector(VECSXP, 2));
            SET_VECTOR_ELT(dimnames, 0, R_NilValue);  // no row names
            SET_VECTOR_ELT(dimnames, 1, colnames);
            setAttrib(colormap, R_DimNamesSymbol, dimnames);
            out = colormap;
            UNPROTECT(3);
            return out;
        }
    }
    
    // Handle the most common TIFF tag types.
    // We only support these types because they are sufficient for basic TIFF metadata
    // and can be directly converted to R types without complex conversions:
    // - TIFF_LONG/SHORT -> R integer
    // - TIFF_FLOAT -> R double
    // - TIFF_ASCII -> R string
    // - TIFF_RATIONAL -> R double (converted by libtiff)
    switch (type) {
        case TIFF_LONG: {
            uint32_t value;
            if (TIFFGetFieldDefaulted(tiff, tag, &value)) {
                out = PROTECT(ScalarInteger(value));
                UNPROTECT(1);
            }
            break;
        }
        case TIFF_SHORT: {
            uint16_t value;
            if (TIFFGetFieldDefaulted(tiff, tag, &value)) {
                out = PROTECT(ScalarInteger(value));
                UNPROTECT(1);
            }
            break;
        }
        case TIFF_FLOAT: {
            float value;
            if (TIFFGetFieldDefaulted(tiff, tag, &value)) {
                out = PROTECT(ScalarReal(value));
                UNPROTECT(1);
            }
            break;
        }
        case TIFF_RATIONAL: {
            float value;  // libtiff converts RATIONAL to float for us
            if (TIFFGetFieldDefaulted(tiff, tag, &value)) {
                out = PROTECT(ScalarReal(value));
                UNPROTECT(1);
            }
            break;
        }
        case TIFF_ASCII: {
            const char* value;
            if (TIFFGetFieldDefaulted(tiff, tag, &value)) {
                out = PROTECT(mkString(value));
                UNPROTECT(1);
            }
            break;
        }
        default:
            // Other TIFF types are not supported as they are rarely used in basic tags
            // and would require more complex handling
            break;
    }
    return out;
}

SEXP TIFF_get_tags(TIFF *tiff) {
    SEXP out = PROTECT(allocVector(VECSXP, n_supported_tags));
    SEXP names = PROTECT(allocVector(STRSXP, n_supported_tags));
    for (int i = 0; i < n_supported_tags; i++) {
        const TIFFField *field = TIFFFieldWithTag(tiff, supported_tags[i]);
        if (field) {
            const char *name = TIFFFieldName(field);
            SEXP value = get_tag_value(tiff, supported_tags[i], TIFFFieldDataType(field));
            SET_STRING_ELT(names, i, mkChar(name));
            if (value != R_NilValue) {
                SET_VECTOR_ELT(out, i, value);
            }
        }
    }
    setAttrib(out, R_NamesSymbol, names);
    UNPROTECT(2);
    return out;
}

SEXP read_tif_C(SEXP sFn /*filename*/, SEXP sDirs) {
    check_type_sizes();
    int to_unprotect = 0;
    SEXP res = Rf_protect(R_NilValue), multi_res = Rf_protect(R_NilValue);
    to_unprotect += 2;  // res and multi_res
    SEXP multi_tail = multi_res, dim;
    const char *fn;  // file name
    tiff_job_t rj;
    TIFF *tiff;
    FILE *f;
	if (TYPEOF(sFn) != STRSXP || LENGTH(sFn) != 1) Rf_error("invalid filename");
	fn = CHAR(STRING_ELT(sFn, 0));
	f = fopen(fn, "rb");
	if (!f) Rf_error("unable to open %s", fn);
	rj.f = f;
    tiff = TIFF_Open("rmc", &rj); // no mmap, no chopping
    if (!tiff) {
        TIFFClose(tiff);
        Rf_error("Unable to open TIFF");
    }
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
            TIFFClose(tiff);
            Rf_error("12-bit images are not supported. "
                     "Try converting your image to 16-bit.");
        }
        if (bps != 8 && bps != 16 && bps != 32) {
            TIFFClose(tiff);
            Rf_error("image has %d bits/sample which is unsupported", bps);
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
                            if (is_float) {
                                float float_val = ((const float*) v)[0];
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
                } else if (config == PLANARCONFIG_CONTIG) { // interlaced
                    tsize_t i, j, step = spp * bps / 8;
                    for (i = 0; i < n; i += step) {
                        const uint8_t *v = (const uint8_t*) buf + i;
                        if (bps == 8) {
                            for (j = 0; j < spp; j++) {
                                real_arr[(imageLength * imageWidth * j) + imageLength * x + y] =
                                    (double) v[j];
                            }
                        } else if (bps == 16) {
                            for (j = 0; j < spp; j++) {
                                real_arr[(imageLength * imageWidth * j) + imageLength * x + y] =
                                    (double) ((const uint16_t*)v)[j];
                            }
                        } else if (bps == 32 && (!is_float)) {
                            for (j = 0; j < spp; j++) {
                                real_arr[(imageLength * imageWidth * j) + imageLength * x + y] =
                                    (double) ((const uint32_t*)v)[j];
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
                        } else if (bps == 16) {
                            real_arr[plane_offset + imageLength * x + y] =
                                (uint16_t) ((const uint16_t*)v)[0];
                        } else if (bps == 32 && !is_float) {
                            real_arr[plane_offset + imageLength * x + y] =
                                (uint32_t) ((const uint32_t*)v)[0];
                        } else if (bps == 32 && is_float) {
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
        } else {  // tiled image
            if (spp > 1 && config != PLANARCONFIG_CONTIG) {
                TIFFClose(tiff);
                Rf_error("Planar format tiled images are not supported");
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
                            double val = NA_REAL;
                            const unsigned char *v = (const unsigned char*) buf + i;
                            if (bps == 8) {
                                val = v[0];
                            } else if (bps == 16) {
                                val = ((const uint16_t*)v)[0];
                            } else if (bps == 32) {
                                if (is_float) {
                                    val = ((const float*)v)[0];
                                } else {
                                    val = ((const uint32_t*)v)[0];
                                }
                            }
                            if (x + xoff < imageWidth && y + yoff < imageLength)
                                real_arr[imageLength * (x + xoff) + y + yoff] = val;
                            xoff++;
                            if (xoff >= tileWidth) {
                                xoff -= tileWidth;
                                yoff++;
                            }
                        }
                    } else if (config == PLANARCONFIG_CONTIG) {  // spp > 1, interlaced
                        tsize_t i, j, step = spp * bps / 8;
                        uint32_t xoff = 0, yoff = 0;
                        for (i = 0; i < n; i += step) {
                            const unsigned char *v = (const uint8_t*) buf + i;
                            if (x + xoff < imageWidth && y + yoff < imageLength) {
                                if (bps == 8) {
                                    for (j = 0; j < spp; j++)
                                        real_arr[(imageLength * imageWidth * j) +
                                                 imageLength * (x + xoff) + y + yoff] =
                                            (double) v[j];
                                } else if (bps == 16) {
                                    for (j = 0; j < spp; j++)
                                        real_arr[(imageLength * imageWidth * j) +
                                                 imageLength * (x + xoff) + y + yoff] =
                                            (double) ((const uint16_t*)v)[j];
                                } else if (bps == 32 && (!is_float)) {
                                    for (j = 0; j < spp; j++)
                                        real_arr[(imageLength * imageWidth * j) +
                                                 imageLength * (x + xoff) + y + yoff] =
                                            (double) ((const uint32_t*)v)[j];
                                } else if (bps == 32 && is_float) {
                                    for (j = 0; j < spp; j++)
                                        real_arr[(imageLength * imageWidth * j) +
                                                  imageLength * (x + xoff) + y + yoff] =
                                            (double) ((const float*)v)[j];
                                }
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
    TIFFClose(tiff);
    res = Rf_protect(PairToVectorList(multi_res));  // convert LISTSXP into VECSXP
    to_unprotect++;
    Rf_unprotect(to_unprotect);
    return res;
}

SEXP read_tags_C(SEXP sFn /*FileName*/, SEXP sDirs) {
    check_type_sizes();
    int to_unprotect = 0;
    SEXP multi_res = Rf_protect(R_NilValue);
    to_unprotect++;
    SEXP multi_tail = multi_res;
    const char *fn;
    tiff_job_t rj;
    TIFF *tiff;
    FILE *f;
    if (TYPEOF(sFn) != STRSXP || LENGTH(sFn) < 1) Rf_error("invalid filename");
    fn = CHAR(STRING_ELT(sFn, 0));
    f = fopen(fn, "rb");
    if (!f) Rf_error("unable to open %s", fn);
    rj.f = f;
    tiff = TIFF_Open("rmc", &rj); // no mmap, no chopping
    if (!tiff)
        Rf_error("Unable to open TIFF");
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
        SEXP cur_tags = Rf_protect(TIFF_get_tags(tiff));
        to_unprotect++;
        /* Build a linked list of results */
        if (multi_res == R_NilValue) {  // first image in stack
            multi_res = multi_tail = Rf_protect(Rf_list1(cur_tags));
            to_unprotect++;  // `multi_res` needs to be UNPROTECTed later
        } else {
            SEXP q = Rf_protect(Rf_list1(cur_tags));
            to_unprotect++;
            multi_tail = SETCDR(multi_tail, q);  // `q` is now PROTECTed as part of `multi_tail`
            Rf_unprotect(2);  // removing explit PROTECTion of `q` UNPROTECTing `cur_tags`
            to_unprotect -= 2;
        }
        if (!TIFFReadDirectory(tiff))
            break;
    }
    TIFFClose(tiff);
    Rf_unprotect(to_unprotect);
    return Rf_PairToVectorList(multi_res);
}

SEXP count_directories_C(SEXP sFn /*FileName*/) {
    check_type_sizes();
    int to_unprotect = 0;
    SEXP res = Rf_protect(allocVector(REALSXP, 1));
    to_unprotect++;
    const char *fn;
    tiff_job_t rj;
    TIFF *tiff;
    FILE *f;
    if (TYPEOF(sFn) != STRSXP || LENGTH(sFn) < 1) Rf_error("invalid filename");
    fn = CHAR(STRING_ELT(sFn, 0));
    f = fopen(fn, "rb");
    if (!f) Rf_error("unable to open %s", fn);
    rj.f = f;
    tiff = TIFF_Open("rmc", &rj); // no mmap, no chopping
    if (!tiff)
        Rf_error("Unable to open TIFF");
    R_xlen_t cur_dir = 0; // 1-based image number
    while (1) {  // loop over TIFF directories
        cur_dir++;
        if (!TIFFReadDirectory(tiff)) break;
    }
    TIFFClose(tiff);
    REAL(res)[0] = cur_dir;
    Rf_unprotect(to_unprotect);
    return res;
}
