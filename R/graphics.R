#' Basic image display.
#'
#' Display an image that has been read in by [read_tif()] as it would look in
#' 'ImageJ'. This function wraps [fields::image.plot()].
#'
#' @param img A numeric matrix.
#' @param ... Arguments passed to [fields::image.plot()]. These arguments should
#'   be named.
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' display(img[, , 1, 1])  # red channel
#' display(img[, , 2, 1])  # green channel
#' display(img[, , 3, 1])  # blue channel
#'
#' @export
display <- function(img, ...) {
  checkmate::assert_matrix(img)
  img %>% {
    .[rev(seq_len(nrow(.))), ]
  } %>% t() %>%
    fields::image.plot(..., axes = FALSE,
                       col = grDevices::grey.colors(999,
                                                    start = 0, end = 1))
}
