#' Write images in TIFF format
#'
#' Write images into a TIFF file.
#'
#' @inheritParams ijtiff_img
#' @param path Path to the TIFF file to write to.
#' @param bits_per_sample Number of bits per sample (numeric scalar). Supported
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
#' @param xresolution Numeric value specifying the horizontal resolution in pixels per unit.
#'   This is typically used with `resolutionunit` to define the physical dimensions of the image.
#' @param yresolution Numeric value specifying the vertical resolution in pixels per unit.
#'   This is typically used with `resolutionunit` to define the physical dimensions of the image.
#' @param resolutionunit Integer specifying the unit of measurement for `xresolution` and `yresolution`.
#'   Valid values are: 1 (no absolute unit), 2 (inch), or 3 (centimeter). Default is 2 (inch) if not specified.
#' @param orientation Integer specifying the orientation of the image.
#'   Valid values are:
#'   * 1 = Row 0 top, column 0 left (default)
#'   * 2 = Row 0 top, column 0 right
#'   * 3 = Row 0 bottom, column 0 right
#'   * 4 = Row 0 bottom, column 0 left
#'   * 5 = Row 0 left, column 0 top
#'   * 6 = Row 0 right, column 0 top
#'   * 7 = Row 0 right, column 0 bottom
#'   * 8 = Row 0 left, column 0 bottom
#' @param xposition Numeric value specifying the x position of the image in resolution units.
#'   This is typically used with `resolutionunit` to define the horizontal position of the image.
#' @param yposition Numeric value specifying the y position of the image in resolution units.
#'   This is typically used with `resolutionunit` to define the vertical position of the image.
#' @param copyright Character string specifying the copyright notice for the image.
#' @param artist Character string specifying the name of the person who created the image.
#' @param documentname Character string specifying the name of the document from which the image was scanned.
#' @param datetime Date/time for the image. Can be provided as a character string in format "YYYY:MM:DD HH:MM:SS",
#'   a Date object, a POSIXct/POSIXlt object, or any object that can be converted to a datetime using
#'   lubridate::as_datetime(). If NULL (default), no datetime is set.
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
                      compression = "none", overwrite = FALSE, msg = TRUE,
                      xresolution = NULL, yresolution = NULL,
                      resolutionunit = NULL, orientation = NULL,
                      xposition = NULL, yposition = NULL,
                      copyright = NULL, artist = NULL, documentname = NULL,
                      datetime = NULL) {
  to_invisibly_return <- img
  if (endsWith(path, "/")) rlang::abort("`path` cannot end with '/'.")
  path <- fs::path_expand(path)
  args <- argchk_write_tif(
    img = img, path = path, bits_per_sample = bits_per_sample,
    compression = compression, overwrite = overwrite, msg = msg,
    xresolution = xresolution, yresolution = yresolution,
    resolutionunit = resolutionunit, orientation = orientation,
    xposition = xposition, yposition = yposition,
    copyright = copyright, artist = artist, documentname = documentname,
    datetime = datetime
  )
  d <- dim(args$img)
  floats <- anyNA(args$img) || (!can_be_intish(args$img))
  float_max <- .Call("float_max_C", PACKAGE = "ijtiff")
  if ((!floats) && any(args$img < 0)) {
    if (min(args$img) < -float_max) {
      rlang::abort(
        c(
          stringr::str_glue(
            "The lowest allowable negative value in `img` is ",
            "{-float_max}."
          ),
          x = stringr::str_glue(
            "The lowest value in your `img` is {min(args$img)}."
          ),
          i = paste(
            "The `write_txt_img()` function allows you to write images without",
            " restriction on the values therein. Maybe you should try that?"
          )
        )
      )
    } else if (max(args$img) > float_max) {
      rlang::abort(
        c(
          stringr::str_glue(
            "If `img` has negative values (which the input `img` does),",
            " then the maximum allowed positive value is {float_max}."
          ),
          x = stringr::str_glue(
            "The largest value in your `img` is {max(args$img)}."
          ),
          i = paste(
            "The `write_txt_img()` function allows you to write images without",
            " restriction on the values therein. Maybe you should try that?"
          )
        )
      )
    }
    floats <- TRUE
  }
  args$img <- as.numeric(args$img) # The C function needs img to be numeric
  dim(args$img) <- d
  if (floats) {
    checkmate::assert_numeric(args$img,
      lower = -float_max,
      upper = float_max
    )
    if (args$bits_per_sample == "auto") args$bits_per_sample <- 32
    if (args$bits_per_sample != 32) {
      rlang::abort(
        c(
          paste(
            "Your image needs to be written as floating point numbers",
            "(not integers). For this, it is necessary to have 32 bits per",
            "sample."
          ),
          x = stringr::str_glue(
            "You have selected {args$bits_per_sample} bits per sample."
          )
        )
      )
    }
  } else {
    ideal_bps <- 8
    mx <- floor(max(args$img))
    if (mx > 2^32 - 1) {
      rlang::abort(
        c(
          stringr::str_glue(
            "The maximum value in 'img' is {mx} which is ",
            "greater than 2^32 - 1 ",
            "and therefore too high to be written to a TIFF file."
          ),
          i = paste(
            "The `write_txt_img()` function allows you to write images without",
            " restriction on the values therein. Maybe you should try that?"
          )
        )
      )
    } else {
      ideal_bps <- dplyr::case_when(
        mx > 2^16 - 1 ~ 32,
        mx > 2^8 - 1 ~ 16,
        TRUE ~ ideal_bps
      )
    }
    args$bits_per_sample <- ifelse(args$bits_per_sample == "auto",
      ideal_bps, args$bits_per_sample
    )
    if (args$bits_per_sample < ideal_bps) {
      rlang::abort(
        c(
          stringr::str_glue(
            "You are trying to write a {args$bits_per_sample}-bit image, ",
            "however the maximum element in `img` is {mx}, which is too big."
          ),
          x = stringr::str_glue(
            "The largest allowable value in a ",
            "{args$bits_per_sample}-bit image is ",
            "{2 ^ args$bits_per_sample -1}."
          ),
          i = stringr::str_glue(
            "To write your `img` to a TIFF file, you need ",
            "at least {ideal_bps} bits per sample."
          )
        )
      )
    }
  }
  if (args$msg) {
    bps <- args$bits_per_sample %>%
      {
        dplyr::case_when(
          . == 8 ~ "an 8-bit, ",
          . == 16 ~ "a 16-bit, ",
          . == 32 ~ "a 32-bit, ",
          TRUE ~ "a 0-bit, "
        )
      }
    message(
      "Writing ", args$path, ": ", bps, d[1], "x", d[2], " pixel image of ",
      ifelse(floats, "floating point", "unsigned integer"),
      " type with ", d[3],
      " ", "channel", ifelse(d[3] > 1, "s", ""), " and ",
      d[4], " frame", ifelse(d[4] > 1, "s", ""), " . . ."
    )
  }
  what <- enlist_img(args$img)
  written <- .Call("write_tif_C", what, args$path, args$bits_per_sample, args$compression,
    floats,
    args$xresolution,
    args$yresolution,
    args$resolutionunit,
    args$orientation,
    args$xposition,
    args$yposition,
    args$copyright,
    args$artist,
    args$documentname,
    args$datetime,
    PACKAGE = "ijtiff"
  )
  if (args$msg) message("\b Done.")
  invisible(to_invisibly_return)
}

#' @rdname write_tif
#' @export
tif_write <- function(img, path, bits_per_sample = "auto",
                      compression = "none", overwrite = FALSE, msg = TRUE,
                      xresolution = NULL, yresolution = NULL,
                      resolutionunit = NULL, orientation = NULL,
                      xposition = NULL, yposition = NULL,
                      copyright = NULL, artist = NULL, documentname = NULL,
                      datetime = NULL) {
  write_tif(
    img = img,
    path = path,
    bits_per_sample = bits_per_sample,
    compression = compression,
    overwrite = overwrite,
    msg = msg,
    xresolution = xresolution,
    yresolution = yresolution,
    resolutionunit = resolutionunit,
    orientation = orientation,
    xposition = xposition,
    yposition = yposition,
    copyright = copyright,
    artist = artist,
    documentname = documentname,
    datetime = datetime
  )
}
