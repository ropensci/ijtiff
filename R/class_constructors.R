#' `ijtiff_img` class.
#'
#' A class for images which are read or to be written by the `ijtiff` package.
#'
#' @param img An array representing the image. \itemize{\item For a
#'   single-plane, grayscale image, use a matrix `img[y, x]`. \item For a
#'   multi-plane, grayscale image, use a 3-dimensional array `img[y, x, plane]`.
#'   \item For a multi-channel, single-plane image, use a 4-dimensional array
#'   with a redundant 4th slot `img[y, x, channel, ]` (see [ijtiff_img]
#'   'Examples' for an example). \item For a multi-channel, multi-plane image,
#'   use a 4-dimensional array `img[y, x, channel, plane]`.}
#' @param ... Named arguments which are set as attributes.
#'
#' @return A 4 dimensional array representing an image, indexed by `img[y, x,
#'   channel, frame]`, with selected attributes.
#'
#' @export
#'
#' @examples
#' img <- matrix(1:4, nrow = 2) # to be a single-channel, grayscale image
#' ijtiff_img(img, description = "single-channel, grayscale")
#' img <- array(seq_len(2^3), dim = rep(2, 3)) # 1 channel, 2 frame
#' ijtiff_img(img, description = "blah blah blah")
#' img <- array(seq_len(2^3), dim = c(2, 2, 2, 1)) #  2 channel, 1 frame
#' ijtiff_img(img, description = "blah blah")
#' img <- array(seq_len(2^4), dim = rep(2, 4)) # 2 channel, 2 frame
#' ijtiff_img(img, software = "R")
ijtiff_img <- function(img, ...) {
  checkmate::assert_array(img, min.d = 2, max.d = 4)
  if (is.logical(img)) {
    atts <- attributes(img)
    img %<>% as.numeric()
    attributes(img) <- atts
  }
  checkmate::assert_numeric(img)
  if (length(dim(img)) == 2) dim(img) %<>% c(1, 1)
  if (length(dim(img)) == 3) {
    dim(img) %<>% {
      c(.[1:2], 1, .[3])
    }
  }
  dots <- list(...)
  if (length(dots)) {
    namez <- names(dots)
    if (is.null(namez) || any(namez == "")) {
      custom_stop(
        "All arguments in ... must be named.",
        "Your argument {dots[[1]]} is not named."
      )
    }
    do_call_args <- c(list(img), dots)
    img <- do.call(structure, do_call_args)
  }
  cls <- class(img)
  if (is_EBImage(img)) img <- aperm(img, c(2, 1, 3, 4))
  suppressWarnings(
    class(img) <- unique(c("ijtiff_img", dplyr::setdiff(cls, "Image")))
  )
  img
}

#' @rdname ijtiff_img
#' @export
as_ijtiff_img <- ijtiff_img

#' Convert an [ijtiff_img] to an [EBImage::Image].
#'
#' This is for interoperability with the the `EBImage` package.
#'
#' The guess for the `colormode` is made as follows: * If `img` has an attribute
#' `color_space` with value `"RGB"`, then `colormode` is set to `"Color"`. *
#' Else if `img` has 3 or 4 channels, then `colormode` is set to `"Color"`. *
#' Else `colormode` is set to "Grayscale".
#'
#' @param img An [ijtiff_img] object (or something coercible to one).
#' @param colormode A numeric or a character string containing the color mode
#'   which can be either `"Grayscale"` or `"Color"`. If not specified, a guess
#'   is made. See 'Details'.
#' @param scale Scale values in an integer image to the range `[0, 1]`? Has no
#'   effect on floating-point images.
#' @param force This function is designed to take [ijtiff_img]s as input. To
#'   force any old array through this function, use `force = TRUE`, but take
#'   care to check that the result is what you'd like it to be.
#'
#' @return An [EBImage::Image].
#'
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' str(img)
#' str(as_EBImage(img))
#' @export
as_EBImage <- function(img, colormode = NULL, scale = TRUE, force = TRUE) {
  ebimg_check()
  checkmate::assert_flag(scale)
  checkmate::assert_flag(force)
  if (!methods::is(img, "ijtiff_img")) {
    if (methods::is(img, "Image")) {
      return(img)
    } else {
      if (force) {
        img %<>% ijtiff_img()
      } else {
        custom_stop("
          This function expects the input `img` to be of class 'ijtiff_img',
          however the `img` you have supplied is not.
         ", "
          To force your array through this function, use `force = TRUE`, but
          take care to check that the result is what you'd like it to be.
         ")
      }
    }
  }
  if (is.null(colormode)) {
    if (isTRUE(attr(img, "color_space") == "RGB")) {
      colormode <- "color"
    } else {
      colormode <- dplyr::if_else(dim(img)[3] %in% 3:4, "color", "gray")
    }
  }
  checkmate::assert_string(colormode)
  colormode <- dplyr::if_else(
    startsWith("colo", tolower(colormode)),
    "Color", colormode
  )
  colormode <- dplyr::if_else(
    startsWith("gr", tolower(colormode)),
    "Gray", colormode
  )
  colormode %<>% strex::match_arg(c(
    "Color", "Colour",
    "Grayscale", "Greyscale"
  ),
  ignore_case = TRUE
  )
  colormode <- dplyr::if_else(colormode == "Colour", "Color", colormode)
  colormode <- dplyr::if_else(colormode == "Greyscale", "Grayscale", colormode)
  if (scale && can_be_intish(img)) {
    lub <- max(lowest_upper_bound(img, c(2^c(8, 16, 32) - 1)), max(img),
      na.rm = TRUE
    )
    if (!is.na(lub)) img <- img / lub
  }
  img %<>% aperm(c(2, 1, 3, 4))
  if (length(dim(img)) == 4 && dim(img)[3] == 1) dim(img) <- dim(img)[-3]
  EBImage::Image(img, colormode = colormode)
}
