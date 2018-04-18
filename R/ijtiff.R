#' @useDynLib ijtiff
#' @importFrom Rcpp sourceCpp
#' @importFrom magrittr '%>%' '%<>%' '%T>%'
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("."))
}

.onUnload <- function (libpath) {
  library.dynam.unload("ijtiff", libpath)
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

#' TIFF tag information.
#'
#' A dataset containing the information on all known baseline and extended TIFF
#' tags.
#'
#' @format A data frame with 96 rows and 10 variables: \describe{
#'   \item{code_dec}{decimal numeric code of the TIFF tag}
#'   \item{code_hex}{hexadecimal numeric code of the TIFF tag} \item{name}{the name
#'   of the TIFF tag} \item{short_description}{a short description of the TIFF
#'   tag} \item{tag_type}{the type of TIFF tag: either baseline or extended}
#'   \item{url}{the URL of the TIFF tag at \url{https://www.awaresystems.be}}
#'   \item{libtiff_name}{the TIFF tag name in the libtiff C library}
#'   \item{c_type}{the C type of the TIFF tag data in libtiff} \item{count}{the
#'   number of elements in the TIFF tag data} \item{default}{the default value
#'   of the data held in the TIFF tag} }
#' @source \url{https://www.awaresystems.be}
"tiff_tag_data"