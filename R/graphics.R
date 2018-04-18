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
#' display(img)  # first channel, first frame
#' display(img[, , 1, 1])  # first (red) channel, first frame
#' display(img[, , 2, ])  # second (green) channel, first frame
#' display(img[, , 3, ])  # third (blue) channel, first frame
#'
#' @export
display <- function(img, col = grDevices::grey.colors(999, 0, 1), ...) {
  ld <- length(dim(img))
  if (ld == 4) img %<>% {.[, , 1, 1]}
  if (ld == 3) img %<>% {.[, , 1]}
  checkmate::assert_matrix(img)
  img %<>% {t(.[rev(seq_len(nrow(.))), ])}
  dots <- list(...)
  dots %<>% c(list(col = col))
  if (! "axes" %in% names(dots)) dots$axes <- FALSE
  dots %<>% c(list(img), .)
  do.call(fields::image.plot, dots)
}

