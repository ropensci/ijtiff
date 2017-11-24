#' Read an image stored in the TIFF format
#'
#' Reads an image from a TIFF file/content into a numeric array or list.
#'
#' TIFF files have the capability to store multiple images, each having multiple
#' channels. Typically, these multiple images represent the sequential frames in
#' a time-stack or z-stack of images and hence each of these images has the same
#' dimension. If this is the case, they are all read into a single 4-dimensional
#' array `img` where `img` is indexed as `img[y, x, channel, frame]` (where we
#' have `y, x` to comply with the conventional `row, col` indexing of a matrix -
#' it means that images displayed as arrays of numbers in the R console will
#' have the correct orientation). However, it is possible that the images in the
#' TIFF file have varying dimensions (most people have never seen this), in
#' which case they are read in as a list of images, where again each element of
#' the list is a 4-dimensional array `img`, indexed as `img[y, x, channel,
#' frame]`.
#'
#' A (somewhat random) set of TIFF tags are attributed to the read image. These
#' are IMAGEDEPTH, BITSPERSAMPLE, SAMPLESPERPIXEL, SAMPLEFORMAT, PLANARCONFIG,
#' COMPRESSION, THRESHHOLDING, XRESOLUTION, YRESOLUTION, RESOLUTIONUNIT, INDEXED
#' and ORIENTATION. More tags should be added in a subsequent version of this
#' package. You can read about TIFF tags at
#' \url{https://www.awaresystems.be/imaging/tiff/tifftags.html}.
#'
#' TIFF images can have a wide range of internal representations, but only the
#' most common in image processing are supported (8-bit, 16-bit and 32-bit
#' integer and 32-bit float samples).
#'
#' @param path A string. The path to the tiff file to read.
#' @param list_safety A string. This is for type safety of this function. Since
#'   returning a list is unlikely and probably unexpected, the default is to
#'   error. You can instead opt to throw a warning (`list_safety = "warning"`)
#'   or to just return the list quietly (`list_safety = "none"`).
#'
#' @return An object of class [ijtiff_img] or a list of [ijtiff_img]s.
#'
#' @note \itemize{ \item 12-bit TIFFs are not supported. \item There is no
#'   standard for packing order for TIFFs beyond 8-bit so we assume big-endian
#'   packing}.
#'
#' @author Simon Urbanek wrote most of this code for the 'tiff' package. Rory
#'   Nolan lifted it from there and changed it around a bit for this 'ijtiff'
#'   package. Credit should be directed towards Lord Urbanek.
#'
#' @seealso \code{\link{write_tif}}
#' @examples
#'
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' img <- read_tif(system.file("img", "2ch_ij.tif", package = "ijtiff"))
#' str(img)  # we see that `ijtiff` correctly recognises this image's 2 channels
#'
#' @export
read_tif <- function(path, list_safety = "error") {
  checkmate::assert_file_exists(path)
  list_safety %<>% RSAGA::match.arg.ext(c("error", "warning", "none"))
  out <- .Call("read_tif_c", path.expand(path), PACKAGE = "ijtiff")
  checkmate::assert_list(out)
  ds <- dims(out)
  if (filesstrings::all_equal(ds)) {
    attrs1 <- attributes(out[[1]])
    n_ch <- 1
    if ("samples_per_pixel" %in% names(attrs1)) n_ch <- attrs1$samples_per_pixel
    if ("description" %in% names(attrs1)) {
      description <- attrs1$description
      if (startsWith(description, "ImageJ")) {
        if (stringr::str_detect(description, "channels=")) {
          n_ch <- description %>%
            filesstrings::str_after_first("channels=") %>%
            filesstrings::first_number()
        }
      }
    }
    out %<>% unlist()
    dim(out) <- c(ds[[1]][1:2], n_ch, length(out) / prod(c(ds[[1]][1:2], n_ch)))
    if ("dim" %in% names(attrs1)) attrs1$dim <- NULL
    do_call_list <- c(list(img = out), attrs1)
    out <- do.call(ijtiff_img, do_call_list)
  }
  if (is.list(out)) {
    if (list_safety == "error") stop("`read_tif()` tried to return a list.")
    if (list_safety == "warning") warning("`read_tif()` is returning a list.")
  }
  out
}
