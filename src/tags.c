#include "tags.h"
#include "common.h"
#include <Rinternals.h>
#include <tiffio.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>

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

// Helper function to create a TIFF file at the specified path
static TIFF* create_tiff_at_path(const char* temp_path) {
    TIFF* tiff = TIFFOpen(temp_path, "w");
    if (!tiff) {
        error("Could not create TIFF object at %s", temp_path);
    }
    
    return tiff;
}

SEXP get_supported_tags_C(SEXP temp_file_path) {
    if (TYPEOF(temp_file_path) != STRSXP || LENGTH(temp_file_path) < 1) {
        error("Invalid temporary file path");
    }
    
    const char* path = CHAR(STRING_ELT(temp_file_path, 0));
    
    SEXP tags_vec = PROTECT(allocVector(INTSXP, n_supported_tags));
    SEXP tags_names = PROTECT(allocVector(STRSXP, n_supported_tags));
    
    // Create a TIFF file at the specified path
    TIFF* tiff = create_tiff_at_path(path);
    
    for (size_t i = 0; i < n_supported_tags; i++) {
        INTEGER(tags_vec)[i] = supported_tags[i];
        const TIFFField* field = TIFFFieldWithTag(tiff, supported_tags[i]);
        const char* name = field ? TIFFFieldName(field) : "Unknown";
        SET_STRING_ELT(tags_names, i, mkChar(name));
    }
    
    TIFFClose(tiff);
    
    setAttrib(tags_vec, R_NamesSymbol, tags_names);
    UNPROTECT(2);
    return tags_vec;
}

SEXP read_tags_C(SEXP sFn /*FileName*/, SEXP sDirs) {
    check_type_sizes();
    int to_unprotect = 0;
    SEXP multi_res = Rf_protect(R_NilValue);
    to_unprotect++;
    SEXP multi_tail = multi_res;
    const char *fn;
    tiff_job_t rj;
    TIFF *tiff = NULL;
    FILE *f = NULL;
    
    if (TYPEOF(sFn) != STRSXP || LENGTH(sFn) < 1) {
        Rf_error("invalid filename");
    }
    fn = CHAR(STRING_ELT(sFn, 0));
    
    // Initialize rj structure properly
    memset(&rj, 0, sizeof(rj));
    
    // Create a protected pointer for TIFF cleanup
    SEXP tiff_closer = PROTECT(R_MakeExternalPtr(NULL, R_NilValue, R_NilValue));
    to_unprotect++;
    
    // Set up finalizer that checks if pointer is NULL before closing
    R_RegisterCFinalizerEx(tiff_closer, (R_CFinalizer_t)cleanup_tiff_ptr, TRUE);
    
    tiff = open_tiff_file(fn, &rj, &f);
    
    if (tiff == NULL) {
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
    
    // Clear the external pointer to avoid double closing
    TIFFClose(tiff);
    R_ClearExternalPtr(tiff_closer);
    
    Rf_unprotect(to_unprotect);
    return Rf_PairToVectorList(multi_res);
}

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
        return R_NilValue;
    }
    
    // Handle the most common TIFF tag types.
    // We only support these types because they are sufficient for basic TIFF metadata
    // and can be directly converted to R types without complex conversions
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
        case TIFF_FLOAT:
        case TIFF_RATIONAL: {
            float value;
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
