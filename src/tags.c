#include "common.h"
#include <Rinternals.h>
#include <tiffio.h>
#include <unistd.h>

SEXP get_supported_tags_C(void) {
    SEXP tags_vec = PROTECT(allocVector(INTSXP, n_supported_tags));
    SEXP tags_names = PROTECT(allocVector(STRSXP, n_supported_tags));
    
    // Create a temporary file for TIFF object
    char temp_path[] = "/tmp/ijtiff_XXXXXX";
    int fd = mkstemp(temp_path);
    if (fd == -1) {
        error("Could not create temporary file");
    }
    close(fd);
    
    TIFF* tiff = TIFFOpen(temp_path, "w");
    if (!tiff) {
        unlink(temp_path);
        error("Could not create TIFF object");
    }
    
    for (size_t i = 0; i < n_supported_tags; i++) {
        INTEGER(tags_vec)[i] = supported_tags[i];
        const TIFFField* field = TIFFFieldWithTag(tiff, supported_tags[i]);
        const char* name = field ? TIFFFieldName(field) : "Unknown";
        SET_STRING_ELT(tags_names, i, mkChar(name));
    }
    
    TIFFClose(tiff);
    unlink(temp_path);
    
    setAttrib(tags_vec, R_NamesSymbol, tags_names);
    UNPROTECT(2);
    return tags_vec;
}
