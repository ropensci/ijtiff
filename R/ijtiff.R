#' @useDynLib ijtiff
#' @importFrom Rcpp sourceCpp
#' @importFrom magrittr '%>%' '%<>%' '%T>%'
#' @importFrom tiff readTIFF
#' @importFrom abind acorn
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("."))
}

#' `ijtiff`: TIFF I/O for _ImageJ_ users
#'
#' Correctly import TIFF files that were saved from ImageJ and write TIFF files
#' than can be correctly read by ImageJ. Full support for TIFF files with
#' float/real-numbered pixels. Also supports text image I/O.
#'
#' @docType package
#' @name ijtiff
#' @aliases ijtiff-package
NULL