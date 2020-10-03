#' Write images in TIFF format
#'
#' Write images into a TIFF file.
#'
#' @inheritParams ijtiff_img
#' @param path file name or a raw vector
#' @param bits_per_sample number of bits per sample (numeric scalar). Supported
#'   values are 8, 16, and 32. The default `"auto"` automatically picks the
#'   smallest workable value based on the maximum element in `img`. For example,
#'   if the maximum element in `img` is 789, then 16-bit will be chosen because
#'   789 is greater than 2 ^ 8 - 1 but less than or equal to 2 ^ 16 - 1.
#' @param compression A string, the desired compression algorithm. Must be one
#'   of `"none"`, `"LZW"`, `"PackBits"`, `"RLE"`, `"JPEG"`, `"deflate"` or
#'   `"Zip"`. If you want compression but don't know which one to go for, I
#'   recommend `"Zip"`, it gives a large file size reduction and it's lossless.
#'   Note that `"deflate"` and `"Zip"` are the same thing. Avoid using `"JPEG"`
#'   compression in a TIFF file if you can; I've noticed it can be buggy.
#' @param overwrite If writing the image would overwrite a file, do you want to
#'   proceed?
#' @param msg Print an informative message about the image being written?
#'
#' @return The input `img` (invisibly).
#'
#' @author Simon Urbanek wrote most of this code for the 'tiff' package. Rory
#'   Nolan lifted it from there and changed it around a bit for this 'ijtiff'
#'   package. Credit should be directed towards Lord Urbanek.
#' @seealso [read_tif()]
#'
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' temp_dir <- tempdir()
#' write_tif(img, paste0(temp_dir, "/", "Rlogo"))
#' img <- matrix(1:4, nrow = 2)
#' write_tif(img, paste0(temp_dir, "/", "tiny2x2"))
#' list.files(temp_dir, pattern = "tif$")
#' @export
write_tif <- function(img, path, bits_per_sample = "auto",
                      compression = "none", overwrite = FALSE, msg = TRUE) {
  to_invisibly_return <- img
  c(img, path, bits_per_sample, compression, overwrite, msg) %<-%
    argchk_write_tif(
      img = img, path = path, bits_per_sample = bits_per_sample,
      compression = compression, overwrite = overwrite, msg = msg
    )[c("img", "path", "bits_per_sample", "compression", "overwrite", "msg")]
  if (stringr::str_detect(path, "/")) {
    # write_tif() sometimes fails when writing to far away directories
    tiff_dir <- strex::str_before_last(path, "/")
    checkmate::assert_directory_exists(tiff_dir)
    path %<>% strex::str_after_last("/")
    withr::local_dir(tiff_dir)
  }
  d <- dim(img)
  floats <- anyNA(img) || (!can_be_intish(img))
  float_max <- .Call("float_max_C", PACKAGE = "ijtiff")
  if ((!floats) && any(img < 0)) {
    if (min(img) < -float_max) {
      custom_stop(
        "The lowest allowable negative value in `img` is {-float_max}.",
        "The lowest value in your `img` is {min(img)}.",
        "
         The `write_txt_img()` function allows you to write images without
         restriction on the values therein. Maybe you should try that?
        "
      )
    } else if (max(img) > float_max) {
      custom_stop(
        "
         If `img` has negative values (which the input `img` does),
         then the maximum allowed positive value is {float_max}.
        ",
        "The largest value in your `img` is {max(img)}.",
        "
         The `write_txt_img()` function allows you to write images without
         restriction on the values therein. Maybe you should try that?
        "
      )
    }
    floats <- TRUE
  }
  img %<>% as.numeric() # The C function needs img to be numeric
  dim(img) <- d
  if (floats) {
    checkmate::assert_numeric(img,
      lower = -float_max,
      upper = float_max
    )
    if (bits_per_sample == "auto") bits_per_sample <- 32
    if (bits_per_sample != 32) {
      custom_stop(
        "
         Your image needs to be written as floating point numbers
         (not integers). For this, it is necessary to have 32 bits per
         sample.
        ",
        "You have selected {bits_per_sample} bits per sample."
      )
    }
  } else {
    ideal_bps <- 8
    mx <- floor(max(img))
    if (mx > 2^32 - 1) {
      custom_stop(
        "
         The maximum value in 'img' is {mx} which is greater than 2 ^ 32 - 1 and
         therefore too high to be written to a TIFF file.
        ",
        "The `write_txt_img()` function allows you to write images without
         restriction on the values therein. Maybe you should try that?
        "
      )
    } else {
      ideal_bps <- dplyr::case_when(
        mx > 2^16 - 1 ~ 32,
        mx > 2^8 - 1 ~ 16,
        TRUE ~ ideal_bps
      )
    }
    bits_per_sample <- ifelse(bits_per_sample == "auto",
      ideal_bps, bits_per_sample
    )
    if (bits_per_sample < ideal_bps) {
      custom_stop("
         You are trying to write a {bits_per_sample}-bit image,
         however the maximum element in `img` is {mx}, which is too big.
        ", "
         The largest allowable value in a {bits_per_sample}-bit image is
         {2 ^ bits_per_sample -1}.
        ", "
         To write your `img` to a TIFF file, you need at least {ideal_bps}
         bits per sample.
        ")
    }
  }
  if (msg) {
    bps <- bits_per_sample %>% {
      dplyr::case_when(
        . == 8 ~ "an 8-bit, ",
        . == 16 ~ "a 16-bit, ",
        . == 32 ~ "a 32-bit, ",
        TRUE ~ "a 0-bit, "
      )
    }
    pretty_msg(
      "Writing ", path, ": ", bps, d[1], "x", d[2], " pixel image of ",
      ifelse(floats, "floating point", "unsigned integer"),
      " type with ", d[3],
      " ", "channel", ifelse(d[3] > 1, "s", ""), " and ",
      d[4], " frame", ifelse(d[4] > 1, "s", ""), " . . ."
    )
  }
  what <- enlist_img(img)
  written <- .Call("write_tif_C", what, path, bits_per_sample, compression,
    floats,
    PACKAGE = "ijtiff"
  )
  if (msg) pretty_msg("\b Done.")
  invisible(to_invisibly_return)
}

#' @rdname write_tif
#' @export
tif_write <- function(img, path, bits_per_sample = "auto",
                      compression = "none", overwrite = FALSE, msg = TRUE) {
  write_tif(
    img = img,
    path = path,
    bits_per_sample = bits_per_sample,
    compression = compression,
    overwrite = overwrite,
    msg = msg
  )
}
