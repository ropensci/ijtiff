#' Basic image display.
#'
#' Display an image that has been read in by [read_tif()] as it would look in
#' 'ImageJ'. This function is really just `imager`'s `plot.cimg()` on the
#' inside, with some handling.
#'
#' @param img An [ijtiff_img] object.
#' @param ... Passed to `imager`'s `plot.cimg().
#'
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' display(img)
#' display(img[, , 1, 1]) # first (red) channel, first frame
#' display(img[, , 2, ]) # second (green) channel, first frame
#' display(img[, , 3, ]) # third (blue) channel, first frame
#' display(img, basic = TRUE) # displays first (red) channel, first frame
#'
#' @export
display <- function(img, ...) {
  dots <- list(...)
  img_to_plot <- img %>%
    as_ijtiff_img() %>%
    aperm(c(2, 1, 4, 3), keep.class = FALSE) %>%
    imager::cimg()
  do.call(graphics::plot, c(list(x = img_to_plot), dots))
}
