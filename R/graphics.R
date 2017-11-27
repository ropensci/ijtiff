#' Basic image display.
#'
#' Display an image that has been read in by [read_tif()] as it would look in
#' 'ImageJ'. This function wraps [fields::image.plot()].
#'
#' @param img A numeric matrix.
#' @param ... Arguments passed to [fields::image.plot()]. These arguments should
#'   be fully named.
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' display(img[, , 1, 1])  # red channel
#' display(img[, , 2, 1])  # green channel
#' display(img[, , 3, 1])  # blue channel
#'
#' @export
display <- function(img, ...) {
  checkmate::assert_matrix(img)
  img %<>% {t(.[rev(seq_len(nrow(.))), ])}
  dots <- list(...)
  dots[[1]] <- img
  if (! "axes" %in% names(dots)) dots$axes <- FALSE
  if (! "col" %in% names(dots)) {
    dots$col <- grDevices::grey.colors(999, start = 0, end = 1)
  }
  do.call(fields::image.plot, dots)
}

