#' Convert an ijtiff_img object to a raster object for plotting
#'
#' This function converts an [ijtiff_img] object to a `raster` object that can
#' be used with base R graphics functions. The function extracts the first frame
#' of the image and converts it to an RGB raster representation.
#'
#' @param ijt_img An [ijtiff_img] object. This should be a 4D array with
#'   dimensions representing (y, x, channel, frame).
#'
#' @return A `raster` object compatible with [graphics::plot.raster()]. The
#'   raster will represent the first frame of the input image.
#'
#' @details The function performs the following operations:
#' * Extracts the first frame of the image
#' * Checks for invalid values (all NA or negative values)
#' * Determines the appropriate color scaling based on the image bit depth
#' * Creates an RGB representation using the available channels
#'
#' For single-channel images, a grayscale representation is created. For RGB
#' images (3 channels), a full-color representation is created.
#'
#' @examples
#' # Read a TIFF image
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#'
#' # Convert to raster and plot
#' raster_img <- as.raster(img)
#' plot(raster_img)
#'
#' @export
as.raster.ijtiff_img <- function(ijt_img) {
  img <- ijt_img[, , , 1, drop = FALSE]
  if (all(is.na(img))) {
    rlang::abort(
      c(
        paste(
          "The `img` object you have supplied contains only NA values."
        )
      )
    )
  }
  if (any(img < 0, na.rm = TRUE)) {
    rlang::abort(
      c(
        paste(
          "The `img` object you have supplied contains values less ",
          "than 0."
        ),
        i = "Please rescale your image and try again."
      )
    )
  }
  img_max <- Inf
  for (possible_max in c(1, c(2^8, 2^16, 2^32) - 1)) {
    if (all(img <= possible_max, na.rm = TRUE)) {
      img_max <- possible_max
      break
    }
  }
  if (img_max == Inf) {
    rlang::abort(
      c(
        paste(
          "The `img` object you have supplied contains values greater ",
          "than 2^32 - 1."
        ),
        i = "Please rescale your image and try again."
      )
    )
  }
  mat <- matrix("", nrow = dim(img)[1], ncol = dim(img)[2])
  is_rgb <- dim(img)[3] == 3
  if (is_rgb) {
    for (y in seq_len(dim(img)[1])) {
      for (x in seq_len(dim(img)[2])) {
        if (any(is.na(c(img[y, x, , 1])))) {
          mat[y, x] <- rgb(img_max, img_max, img_max, maxColorValue = img_max)
        } else {
          mat[y, x] <- rgb(
            img[y, x, 1, 1],
            img[y, x, 2, 1],
            img[y, x, 3, 1],
            maxColorValue = img_max
          )
        }
      }
    }
  } else {
    for (y in seq_len(dim(img)[1])) {
      for (x in seq_len(dim(img)[2])) {
        if (is.na(img[y, x, 1, 1])) {
          mat[y, x] <- gray(1)
        } else {
          mat[y, x] <- gray(
            img[y, x, 1, 1] / img_max
          )
        }
      }
    }
  }
  as.raster(mat)
}

#' Basic image display.
#'
#' Display an image that has been read in by [read_tif()] as it would look in
#' 'ImageJ'. This function wraps [graphics::plot.raster()].
#'
#' @param img An [ijtiff_img] object.
#' @param ... Passed to [graphics::plot.raster()].
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
    as.raster()
  do.call(graphics::plot, c(list(x = img_to_plot), dots))
}
