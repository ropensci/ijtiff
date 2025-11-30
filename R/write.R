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
#' @param tags_to_write A named list of TIFF tags to write. Tag names are
#'   case-insensitive and hyphens/underscores are ignored (e.g., "X_Resolution",
#'   "x-resolution", and "xresolution" are all equivalent). Supported tags are:
#'   * `xresolution` - Numeric value for horizontal resolution in pixels per
#'     unit
#'   * `yresolution` - Numeric value for vertical resolution in pixels per unit
#'   * `resolutionunit` - Integer: 1 (none), 2 (inch), or 3 (centimeter)
#'   * `orientation` - Integer 1-8 for image orientation
#'   * `xposition` - Numeric value for horizontal position in resolution units
#'   * `yposition` - Numeric value for vertical position in resolution units
#'   * `copyright` - Character string for copyright notice
#'   * `artist` - Character string for creator name
#'   * `documentname` - Character string for document name
#'   * `datetime` - Date/time (character, Date, or POSIXct)
#'   * `imagedescription` - Character string for image description
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
#'
#' # Basic write
#' write_tif(img, paste0(temp_dir, "/", "Rlogo"))
#'
#' # Write with tags
#' write_tif(img, paste0(temp_dir, "/", "Rlogo_with_tags"),
#'           tags_to_write = list(
#'             artist = "R Core Team",
#'             copyright = "(c) 2024",
#'             imagedescription = "The R logo"
#'           ))
#'
#' img <- matrix(1:4, nrow = 2)
#' write_tif(img, paste0(temp_dir, "/", "tiny2x2"))
#' list.files(temp_dir, pattern = "tif$")
#' @export
write_tif <- function(img, path, bits_per_sample = "auto",
                      compression = "none", overwrite = FALSE, msg = TRUE,
                      tags_to_write = NULL) {
  to_invisibly_return <- img
  if (endsWith(path, "/")) rlang::abort("`path` cannot end with '/'.")
  path <- fs::path_expand(path)
  args <- argchk_write_tif(
    img = img, path = path, bits_per_sample = bits_per_sample,
    compression = compression, overwrite = overwrite, msg = msg,
    tags_to_write = tags_to_write
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
    bps <- format_bps_message(args$bits_per_sample)
    message(
      "Writing ", args$path, ": ", bps, d[1], "x", d[2], " pixel image of ",
      ifelse(floats, "floating point", "unsigned integer"),
      " type with ", format_dims_message(d[3], d[4]), " . . ."
    )
  }
  what <- enlist_img(args$img)
  tags <- args$tags_to_write
  written <- .Call("write_tif_C", what, args$path, args$bits_per_sample, args$compression,
    floats,
    tags$xresolution,
    tags$yresolution,
    tags$resolutionunit,
    tags$orientation,
    tags$xposition,
    tags$yposition,
    tags$copyright,
    tags$artist,
    tags$documentname,
    tags$datetime,
    tags$imagedescription,
    PACKAGE = "ijtiff"
  )
  if (args$msg) message("\b Done.")
  invisible(to_invisibly_return)
}

#' @rdname write_tif
#' @export
tif_write <- function(img, path, bits_per_sample = "auto",
                      compression = "none", overwrite = FALSE, msg = TRUE,
                      tags_to_write = NULL) {
  write_tif(
    img = img,
    path = path,
    bits_per_sample = bits_per_sample,
    compression = compression,
    overwrite = overwrite,
    msg = msg,
    tags_to_write = tags_to_write
  )
}
