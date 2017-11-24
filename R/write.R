#' Write images in TIFF format
#'
#' Writes images into a TIFF file.
#'
#' \itemize{\item For a single-plane, grayscale image, use a matrix `img[y, x]`.
#' \item For a multi-plane, grayscale image, use a 3-dimensional array `img[y,
#' x, plane]`. \item For a multi-channel, single-plane image, use a
#' 4-dimensional array with a redundant 4th slot `img[y, x, channel, ]` (see
#' 'Examples' for an example of how to do this). \item For a multi-channel,
#' multi-plane image, use a 4-dimensional array `img[y, x, channel, plane]`.}
#'
#' @param img A numeric array, the image to write. It's possible to write
#'   single- and multi-plane, images with 1 (grayscale) or more channels.
#' @param path file name or a raw vector
#' @param bits_per_sample number of bits per sample (numeric scalar). Supported
#'   values are 8, 16, and 32. The default `"auto"` automatically picks the
#'   smallest workable value based on the maximum element in `img`. For example,
#'   if the maximum element in `img` is 789, then 16-bit will be chosen because
#'   789 is greater than 2 ^ 8 - 1 but less than or equal to 2 ^ 16 - 1.
#' @param compression A string, the desired compression algorithm. Must be one
#'   of `"LZW"`, `"none"`, `PackBits`", `"RLE"`, `"JPEG"`, or `"deflate"`.
#'
#' @return The input `img` (invisibly).
#'
#' @author Simon Urbanek wrote most of this code for the 'tiff' package. Rory
#'   Nolan lifted it from there and changed it around a bit for this 'ijtiff'
#'   package. Credit should be directed towards Lord Urbanek.
#' @seealso \code{\link{read_tif}}
#' @examples
#'
#' img <- read_tif(system.file("img", "Rlogo.tif", package="ijtiff"))
#' temp_dir <- tempdir()
#' write_tif(img, paste0(temp_dir, "/", "Rlogo"))
#' list.files(temp_dir)
#'
#' @export
write_tif <- function(img, path, bits_per_sample = "auto",
                      compression = "none") {
  to_invisibly_return <- img
  checkmate::assert_scalar(bits_per_sample)
  checkmate::assert(checkmate::check_string(bits_per_sample),
                    checkmate::check_int(bits_per_sample))
  if (isTRUE(checkmate::check_string(bits_per_sample))) {
    if (startsWith("auto", tolower(bits_per_sample))) {
      bits_per_sample <- "auto"
    } else {
      stop("If `bits_per_sample` is a string, then 'auto' is the only ",
           "allowable value, whereas you have used '", bits_per_sample, "'.")
    }
  } else {
    if (! bits_per_sample %in% c(8, 16, 32)) {
      stop("If specifying `bits_per_sample`, it must be one of 8, 16 or 32.")
    }
  }
  checkmate::assert_string(compression)
  if (endsWith(tolower(path), ".tiff") || endsWith(tolower(path), ".tif"))
    path <- paste0(filesstrings::before_last_dot(path), ".tif")
  path %<>% filesstrings::give_ext("tif")
  checkmate::assert_array(img, d = 4)
  compressions <- c(none = 1L, rle = 2L, packbits = 32773L, jpeg = 7L,
                    deflate = 8L)
  compression %<>% RSAGA::match.arg.ext(names(compressions),
                                        ignore.case = TRUE) %>% {
    compressions[match(., names(compressions))]
  }
  floats <- FALSE
  if (anyNA(img)) floats <- TRUE
  if (!floats) if (!filesstrings::all_equal(img, floor(img))) floats <- TRUE
  if (!floats) {
    if (any(img < 0)) {
      if (min(img) < - float_max()) {
        stop("The lowest allowable negative value in 'img' is ",
             -float_max(), ".")
      }
      if (max(img) > float_max()) {
        stop("If 'img' has negative values (which the input 'img' does), ",
             "then the maximum allowed positive value is ",
             float_max(), ".")
      }
      floats <- TRUE
    }
  }
  if (is.integer(img)) {
    d <- dim(img)
    img %<>% as.numeric()  # The C function needs img to be numeric
    dim(img) <- d
  }
  if (floats) {
    checkmate::assert_numeric(img, lower = -float_max(),
                              upper = float_max())
    if (bits_per_sample == "auto") bits_per_sample <- 32
    if (bits_per_sample != 32) {
      stop("Your image needs to be written as floating point numbers ",
           "(not integers). For this, it is necessary to have 32 bits per",
           "sample, but you have selected", bits_per_sample,
           "bits per sample.")
    }
  } else {
    ideal_bps <- 8
    mx <- floor(max(img))
    if (mx > 2 ^ 32 - 1) {
      stop("The maximum value in 'img' is greater than 2 ^ 32 - 1 and ",
           "therefore too high to be written to a TIFF file.")
    } else if (mx > 2 ^ 16 - 1) {
      ideal_bps <- 32
    } else if (mx > 2 ^ 8 - 1) {
      ideal_bps <- 16
    }
    if (bits_per_sample == "auto") bits_per_sample <- ideal_bps
    if (bits_per_sample < ideal_bps) {
      stop("You are trying to write an ", bits_per_sample, "-bit image, ",
           "however the maximum element in 'img' is ", mx, ", so to write ",
           "correctly, the TIFF file needs to be at least ", ideal_bps, "-bit.")
    }
  }
  n_ch <- dim(img)[3]
  what <- enlist_img(img)
  written <- .Call("write_tif_c", what, path, bits_per_sample, compression,
                   floats, PACKAGE="ijtiff")
  invisible(to_invisibly_return)
}
