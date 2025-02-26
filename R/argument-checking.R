#' Perform argument checking for [write_tif()].
#'
#' This functions checks whether the arguments to [write_tif()] are OK. Then
#' it modifies them a bit to prepare them for the rest of the [write_tif()]
#' function, returning them as a named list.
#'
#' @inheritParams write_tif
#'
#' @return A named list.
#'
#' @noRd
argchk_write_tif <- function(img, path, bits_per_sample, compression,
                             overwrite, msg, xresolution, yresolution,
                             resolutionunit, orientation, xposition, yposition,
                             copyright, artist, documentname, datetime) {
  checkmate::assert_string(path)
  path <- stringr::str_replace_all(path, stringr::coll("\\"), "/") # windows
  checkmate::assert_scalar(bits_per_sample)
  checkmate::assert(
    checkmate::check_string(bits_per_sample),
    checkmate::check_int(bits_per_sample)
  )
  if (isTRUE(checkmate::check_string(bits_per_sample))) {
    if (startsWith("auto", tolower(bits_per_sample))) {
      bits_per_sample <- "auto"
    } else {
      rlang::abort(
        c(
          paste(
            "If `bits_per_sample` is a string, then 'auto' is the only",
            "allowable value."
          ),
          x = stringr::str_glue(
            "You have ",
            "`bits_per_sample = '{bits_per_sample}'`."
          )
        )
      )
    }
  } else {
    if (!bits_per_sample %in% c(8, 16, 32)) {
      rlang::abort(
        c("If specifying `bits_per_sample`, it must be one of 8, 16 or 32.",
          x = stringr::str_glue("You have used '{bits_per_sample}'.")
        )
      )
    }
  }
  checkmate::assert_string(compression)
  if (endsWith(tolower(path), ".tiff") || endsWith(tolower(path), ".tif")) {
    path <- paste0(strex::str_before_last_dot(path), ".tif")
  }
  path <- strex::str_give_ext(path, "tif")
  checkmate::assert_flag(overwrite)
  if (file.exists(path) && (!overwrite)) {
    rlang::abort(
      c(
        stringr::str_glue(
          "The file {path}, already exists and `overwrite` ",
          "is set to `FALSE`."
        ),
        x = "To enable overwriting, use `overwrite = TRUE`."
      )
    )
  }
  checkmate::assert_array(img)
  checkmate::assert_array(img, min.d = 2, max.d = 4)
  checkmate::assert_numeric(img)
  img <- ijtiff_img(img)
  compressions <- c(
    none = 1L, RLE = 2L, LZW = 5L, PackBits = 32773L, JPEG = 7L,
    deflate = 8L, Zip = 8L
  )
  compression <- strex::match_arg(compression, names(compressions),
    ignore_case = TRUE
  )
  compression <- compressions[compression]
  checkmate::assert_flag(msg)

  # Check xresolution if provided
  if (!is.null(xresolution)) {
    checkmate::assert_numeric(xresolution, len = 1, lower = 0, null.ok = FALSE)
  }

  # Check yresolution if provided
  if (!is.null(yresolution)) {
    checkmate::assert_numeric(yresolution, len = 1, lower = 0, null.ok = FALSE)
  }

  # Check resolutionunit if provided
  if (!is.null(resolutionunit)) {
    checkmate::assert_integerish(resolutionunit, len = 1, null.ok = FALSE)
    if (!resolutionunit %in% c(1, 2, 3)) {
      rlang::abort(
        c("If specifying `resolutionunit`, it must be one of 1, 2, or 3.",
          x = stringr::str_glue("You have used '{resolutionunit}'.")
        )
      )
    }
  }

  # Check orientation if provided
  if (!is.null(orientation)) {
    checkmate::assert_integerish(orientation, len = 1, null.ok = FALSE)
    if (!orientation %in% 1:8) {
      rlang::abort(
        c("If specifying `orientation`, it must be an integer between 1 and 8.",
          x = stringr::str_glue("You have used '{orientation}'.")
        )
      )
    }
  }

  # Check xposition if provided
  if (!is.null(xposition)) {
    checkmate::assert_numeric(xposition, len = 1, null.ok = FALSE)
  }

  # Check yposition if provided
  if (!is.null(yposition)) {
    checkmate::assert_numeric(yposition, len = 1, null.ok = FALSE)
  }

  # Check copyright if provided
  if (!is.null(copyright)) {
    checkmate::assert_string(copyright, null.ok = FALSE)
  }

  # Check artist if provided
  if (!is.null(artist)) {
    checkmate::assert_string(artist, null.ok = FALSE)
  }

  # Check documentname if provided
  if (!is.null(documentname)) {
    checkmate::assert_string(documentname, null.ok = FALSE)
  }

  # Check and format datetime if provided
  if (!is.null(datetime)) {
    # Try to convert to datetime using lubridate
    dt <- tryCatch(
      {
        lubridate::as_datetime(datetime)
      },
      error = function(e) {
        stop("datetime must be convertible to a valid date-time using lubridate::as_datetime(). ",
          "The final format should be 'YYYY:MM:DD HH:MM:SS'.",
          call. = FALSE
        )
      }
    )

    if (is.na(dt)) {
      stop("datetime must be convertible to a valid date-time using lubridate::as_datetime(). ",
        "The final format should be 'YYYY:MM:DD HH:MM:SS'.",
        call. = FALSE
      )
    }

    # Format to TIFF datetime format "YYYY:MM:DD HH:MM:SS"
    datetime <- format(dt, "%Y:%m:%d %H:%M:%S")
  }

  list(
    img = img, path = path, bits_per_sample = bits_per_sample,
    compression = compression, overwrite = overwrite, msg = msg,
    xresolution = xresolution, yresolution = yresolution,
    resolutionunit = resolutionunit, orientation = orientation,
    xposition = xposition, yposition = yposition,
    copyright = copyright, artist = artist, documentname = documentname,
    datetime = datetime
  )
}
