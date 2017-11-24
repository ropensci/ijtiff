#' @useDynLib ijtiff
#' @importFrom Rcpp sourceCpp
#' @importFrom magrittr '%>%' '%<>%' '%T>%'
#' @importFrom tiff readTIFF
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("."))
}