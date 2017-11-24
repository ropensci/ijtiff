#' `ijtiff_img` class.
#'
#' A class for images which are read or to be written by the `ijtiff` package.
#'
#' @param img A 4 dimensional array representing an image, indexed by `img[y, x, channel, frame]`. This is consistent with the `EBImage` package (\url{https://bioconductor.org/packages/EBImage/}).
#' @param ... Named arguments which are set as attributes.
#'
#' @export
#'
#' @examples
#' img <- array(seq_len(2 ^ 4), dim = rep(2, 4))
#' ijtiff_img(img, bits_per_sample = 8)
ijtiff_img <- function(img, ...) {
  checkmate::check_array(img, d = 4)
  checkmate::check_numeric(img)
  dots <- list(...)
  namez <- names(dots)
  if (is.null(namez)) stop("All arguments in ... must be named.")
  attributes(img) %<>% c(dots)
  class(img) %<>% c("ijtiff_img", .)
  img
}