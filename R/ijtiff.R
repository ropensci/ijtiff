#' @useDynLib ijtiff
#' @importFrom magrittr '%>%'
#' @importFrom rlang '%||%'
#' @useDynLib ijtiff, .registration = TRUE
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(".", "n_slices", "n_ch", "ij_n_ch", "n_imgs"))
}

.onUnload <- function(libpath) {
  library.dynam.unload("ijtiff", libpath)
}

#' `ijtiff`: TIFF I/O for _ImageJ_ users
#'
#' This is a general purpose TIFF I/O utility for R. The [`tiff`
#' package](https://cran.r-project.org/package=tiff) already exists for this
#' purpose but `ijtiff` adds some functionality and overcomes some bugs therein.
#'
#' * `ijtiff` can write TIFF files whose pixel values are real (floating-point)
#' numbers; `tiff` cannot.
#'
#' * `ijtiff` can read and write _text images_; `tiff`
#' cannot.
#'
#' * `tiff` struggles to interpret channel information and gives cryptic
#' errors when reading TIFF files written by the _ImageJ_ software; `ijtiff`
#' works smoothly with these images.
#'
#' @name ijtiff
#' @aliases ijtiff-package
"_PACKAGE"
