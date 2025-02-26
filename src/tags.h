#ifndef IJTIFF_TAGS_H
#define IJTIFF_TAGS_H

#include <Rinternals.h>
#include "common.h"

// Function to get all supported tags from a TIFF file
SEXP TIFF_get_tags(TIFF *tiff);

// Function to read tags from a TIFF file
SEXP read_tags_C(SEXP sFn, SEXP sDirs);

// Function to get supported tag names
SEXP get_supported_tags_C(SEXP temp_file_path);

#endif // IJTIFF_TAGS_H
