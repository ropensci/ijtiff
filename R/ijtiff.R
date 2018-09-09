#' @useDynLib ijtiff
#' @importFrom Rcpp sourceCpp
#' @importFrom magrittr '%>%' '%<>%' '%T>%'
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("."))
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
#' @docType package
#' @name ijtiff
#' @aliases ijtiff-package
NULL

#' TIFF tag information.
#'
#' A dataset containing the information on all known baseline and extended TIFF
#' tags.
#'
#' @format A data frame with 96 rows and 10 variables: \describe{
#'   \item{code_dec}{decimal numeric code of the TIFF tag}
#'   \item{code_hex}{hexadecimal numeric code of the TIFF tag} \item{name}{the
#'   name of the TIFF tag} \item{short_description}{a short description of the
#'   TIFF tag} \item{tag_type}{the type of TIFF tag: either baseline or
#'   extended} \item{url}{the URL of the TIFF tag at
#'   https://www.awaresystems.be} \item{libtiff_name}{the TIFF tag name in the
#'   libtiff C library} \item{c_type}{the C type of the TIFF tag data in
#'   libtiff} \item{count}{the number of elements in the TIFF tag data}
#'   \item{default}{the default value of the data held in the TIFF tag} }
#' @source https://www.awaresystems.be
"tiff_tag_data"
