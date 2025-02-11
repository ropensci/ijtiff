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
#'   Uses TIFFTAG_BITSPERSAMPLE (tag 258).
#' @param compression A string, the desired compression algorithm. Must be one
#'   of `"none"`, `"LZW"`, `"PackBits"`, `"RLE"`, `"JPEG"`, `"deflate"` or
#'   `"Zip"`. If you want compression but don't know which one to go for, I
#'   recommend `"Zip"`, it gives a large file size reduction and it's lossless.
#'   Note that `"deflate"` and `"Zip"` are the same thing. Avoid using `"JPEG"`
#'   compression in a TIFF file if you can; I've noticed it can be buggy. Uses 
#'   TIFFTAG_COMPRESSION (tag 259).
#' @param overwrite If writing the image would overwrite a file, do you want to
#'   proceed?
#' @param msg Print an informative message about the image being written?
#' @param description Optional string to set as the image description tag. 
#'   Uses TIFFTAG_IMAGEDESCRIPTION (tag 270).
#' @param resolution Numeric vector of length 2 specifying the x and y resolution in
#'   pixels per unit. Default is NULL (no resolution set). 
#'   Uses TIFFTAG_XRESOLUTION (tag 282) and TIFFTAG_YRESOLUTION (tag 283).
#' @param resolution_unit Character string specifying the resolution unit. Must be one
#'   of "none", "inch", or "cm". Default is "inch". Also accepts NULL, which has
#'   the same result as "inch". Uses TIFFTAG_RESOLUTIONUNIT (tag 296).
#' @param color_space Character string specifying the photometric interpretation. Must be one
#'   of "min-is-black" (1) or "RGB" (2). Default is "min-is-black". Uses TIFFTAG_PHOTOMETRIC
#'   (tag 262).
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
                      description = NULL, resolution = NULL,
                      resolution_unit = NULL, color_space = "min-is-black") {
  to_invisibly_return <- img
  c(img, path, bits_per_sample, compression, overwrite, msg, description, resolution, resolution_unit, color_space) %<-%
    argchk_write_tif(
      img = img, path = path, bits_per_sample = bits_per_sample,
      compression = compression, overwrite = overwrite, msg = msg,
      description = description, resolution = resolution, resolution_unit = resolution_unit,
      color_space = color_space
    )[c("img", "path", "bits_per_sample", "compression", "overwrite", "msg", "description", "resolution", "resolution_unit", "color_space")]

  if (stringr::str_detect(path, "/")) {
    # write_tif() sometimes fails when writing to far away directories
    tiff_dir <- strex::str_before_last(path, "/")
    if (!dir.exists(tiff_dir)) {
      dir.create(tiff_dir, recursive = TRUE)
    }
  }

  # Get dimensions and check them
  d <- dim(img)
  if (length(d) != 4L) {
    rlang::abort("`img` must have exactly 4 dimensions.")
  }

  # Determine if we need floating point
  floats <- anyNA(img) || (!can_be_intish(img))
  float_max <- .Call("float_max_C", PACKAGE = "ijtiff")

  if (msg) {
    bps <- bits_per_sample %>%
      {
        dplyr::case_when(
          . == 8 ~ "8-bit",
          . == 16 ~ "16-bit",
          . == 32 ~ "32-bit",
          TRUE ~ "0-bit"
        )
      }
    pretty_msg(
      "Writing ", path, " ... ", bps, " ", d[1], "x", d[2], " pixel image ",
      ifelse(floats, "floating point", "unsigned integer"),
      " ", d[3], " ch ", d[4], " frames"
    )
  }

  # Handle bits_per_sample
  if (bits_per_sample == "auto") {
    if (is.double(img)) {
      bits_per_sample <- 32L
    } else {
      bits_per_sample <- 16L
    }
  }

  # Validate image values
  if ((!floats) && any(img < 0)) {
    if (min(img) < -float_max) {
      rlang::abort(
        c(
          stringr::str_glue(
            "The lowest allowable negative value in `img` is ",
            "{-float_max}."
          ),
          x = stringr::str_glue(
            "The lowest value in your `img` is {min(img)}."
          ),
          i = paste(
            "The `write_txt_img()` function allows you to write images without",
            " restriction on the values therein. Maybe you should try that?"
          )
        )
      )
    } else if (max(img) > float_max) {
      rlang::abort(
        c(
          stringr::str_glue(
            "If `img` has negative values (which the input `img` does),",
            " then the maximum allowed positive value is {float_max}."
          ),
          x = stringr::str_glue(
            "The largest value in your `img` is {max(img)}."
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

  img <- as.numeric(img) # The C function needs img to be numeric
  dim(img) <- d

  if (floats) {
    checkmate::assert_numeric(img,
      lower = -float_max,
      upper = float_max
    )
    if (bits_per_sample == "auto") bits_per_sample <- 32
    if (bits_per_sample != 32) {
      rlang::abort(
        c(
          paste(
            "Your image needs to be written as floating point numbers",
            "(not integers). For this, it is necessary to have 32 bits per",
            "sample."
          ),
          x = stringr::str_glue(
            "You have selected {bits_per_sample} bits per sample."
          )
        )
      )
    }
  } else {
    ideal_bps <- 8
    mx <- floor(max(img))
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
    bits_per_sample <- ifelse(bits_per_sample == "auto",
      ideal_bps, bits_per_sample
    )
    if (bits_per_sample < ideal_bps) {
      rlang::abort(
        c(
          stringr::str_glue(
            "You are trying to write a {bits_per_sample}-bit image, ",
            "however the maximum element in `img` is {mx}, which is too big."
          ),
          x = stringr::str_glue(
            "The largest allowable value in a ",
            "{bits_per_sample}-bit image is ",
            "{2 ^ bits_per_sample -1}."
          ),
          i = stringr::str_glue(
            "To write your `img` to a TIFF file, you need ",
            "at least {ideal_bps} bits per sample."
          )
        )
      )
    }
  }

  # Convert resolution_unit to integer code
  if (!is.null(resolution_unit)) {
    resolution_unit <- switch(resolution_unit,
      "none" = 1L,
      "inch" = 2L,
      "cm" = 3L,
      stop("Unsupported resolution unit: ", resolution_unit)
    )
  } else {
    resolution_unit <- 2L  # Default to "inch" if NULL
  }

  # Convert resolution to numeric vector
  if (!is.null(resolution)) {
    if (length(resolution) != 2) {
      stop("resolution must be a numeric vector of length 2")
    }
    resolution <- as.numeric(resolution)
  }

  # Convert image to list if needed
  what <- enlist_img(img)

  # Write the TIFF file
  written <- .Call("write_tif_C", what, path, bits_per_sample, compression,
    floats, description, resolution, resolution_unit, color_space,
    PACKAGE = "ijtiff"
  )

  if (msg) pretty_msg("\b Done.")
  invisible(to_invisibly_return)
}

#' @rdname write_tif
#' @export
tif_write <- function(img, path, bits_per_sample = "auto",
                      compression = "none", overwrite = FALSE, msg = TRUE,
                      description = NULL, resolution = NULL,
                      resolution_unit = "inch", color_space = "min-is-black") {
  write_tif(
    img = img,
    path = path,
    bits_per_sample = bits_per_sample,
    compression = compression,
    overwrite = overwrite,
    msg = msg,
    description = description,
    resolution = resolution,
    resolution_unit = resolution_unit,
    color_space = color_space
  )
}
