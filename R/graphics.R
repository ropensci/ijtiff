#' Basic image display.
#'
#' Display an image that has been read in by [read_tif()] as it would look in
#' 'ImageJ'. This function wraps [fields::image.plot()].
#'
#' @param img A numeric matrix.
#' @param col Colour lookup table to use for display.
#' @param ... Arguments passed to [fields::image.plot()]. These arguments should
#'   be fully named.
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' display(img[, , 1, 1])  # red channel
#' display(img[, , 2, 1])  # green channel
#' display(img[, , 3, 1])  # blue channel
#'
#' @export
display <- function(img, col = grDevices::grey.colors(999, 0, 1), ...) {
  checkmate::assert_matrix(img)
  img %<>% {t(.[rev(seq_len(nrow(.))), ])}
  dots <- list(...)
  dots %<>% c(list(col = col))
  if (! "axes" %in% names(dots)) dots$axes <- FALSE
  dots %<>% c(list(img), .)
  do.call(fields::image.plot, dots)
}

