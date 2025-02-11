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
argchk_write_tif <- function(img, path, bits_per_sample, compression, overwrite, msg,
                             description, resolution, resolution_unit, color_space) {
  checkmate::assert_array(img, min.d = 2, max.d = 4)
  checkmate::assert_string(path)
  path <- stringr::str_replace_all(path, stringr::coll("\\"), "/") # windows
  if (endsWith(path, "/")) rlang::abort("`path` cannot end with '/'.")

  # Handle bits_per_sample
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

  # Handle compression
  checkmate::assert_string(compression)
  if (endsWith(tolower(path), ".tiff") || endsWith(tolower(path), ".tif")) {
    path <- paste0(strex::str_before_last_dot(path), ".tif")
  }
  if (!endsWith(tolower(path), ".tif")) {
    path <- paste0(path, ".tif")
  }

  # Handle description
  checkmate::assert_string(description, null.ok = TRUE)

  # Handle resolution
  checkmate::assert_numeric(resolution, len = 2, null.ok = TRUE)
  if (!is.null(resolution)) {
    if (any(resolution <= 0)) {
      rlang::abort("Resolution values must be positive.")
    }
    if (is.null(resolution_unit)) {
      resolution_unit <- "inch"  # Default to inch if resolution is set but unit is not
    }
  }
  checkmate::assert_choice(resolution_unit, choices = c("none", "inch", "cm"), null.ok = TRUE)

  # Handle color_space
  checkmate::assert_choice(color_space, choices = c("min-is-black", "rgb"), null.ok = TRUE)
  if (is.null(color_space)) {
    color_space <- "min-is-black"  # Default to min-is-black
  }
  color_space_codes <- c("min-is-black" = 1L, "rgb" = 2L)
  color_space <- color_space_codes[color_space]

  # Handle overwrite and msg
  checkmate::assert_flag(overwrite)
  if (file.exists(path) && (!overwrite)) {
    rlang::abort(
      stringr::str_glue(
        "'{path}' already exists. Use `overwrite = TRUE` to overwrite it."
      )
    )
  }
  checkmate::assert_flag(msg)

  # Convert compression string to integer code
  compressions <- c(
    none = 1L, RLE = 2L, LZW = 5L, PackBits = 32773L, JPEG = 7L,
    deflate = 8L, Zip = 8L
  )
  compression <- match.arg(
    tolower(compression),
    tolower(names(compressions))
  )
  compression <- compressions[compression]

  img <- ijtiff_img(img)

  list(
    img = img, path = path, bits_per_sample = bits_per_sample,
    compression = compression, overwrite = overwrite, msg = msg,
    description = description, resolution = resolution, resolution_unit = resolution_unit,
    color_space = color_space
  )
}
