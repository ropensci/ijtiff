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
                             overwrite, msg) {
  checkmate::assert_string(path)
  path %<>% stringr::str_replace_all(stringr::coll("\\"), "/") # windows safe
  if (endsWith(path, "/")) custom_stop("`path` cannot end with '/'.")
  checkmate::assert_scalar(bits_per_sample)
  checkmate::assert(
    checkmate::check_string(bits_per_sample),
    checkmate::check_int(bits_per_sample)
  )
  if (isTRUE(checkmate::check_string(bits_per_sample))) {
    if (startsWith("auto", tolower(bits_per_sample))) {
      bits_per_sample <- "auto"
    } else {
      custom_stop(
        "
         If `bits_per_sample` is a string, then 'auto' is the only
         allowable value.
        ",
        "You have used '{bits_per_sample}'."
      )
    }
  } else {
    if (!bits_per_sample %in% c(8, 16, 32)) {
      custom_stop(
        "If specifying `bits_per_sample`, it must be one of 8, 16 or 32.",
        "You have used `bits_per_sample = {bits_per_sample}`."
      )
    }
  }
  checkmate::assert_string(compression)
  if (endsWith(tolower(path), ".tiff") || endsWith(tolower(path), ".tif")) {
    path <- paste0(strex::str_before_last_dot(path), ".tif")
  }
  path %<>% strex::str_give_ext("tif")
  checkmate::assert_flag(overwrite)
  if (file.exists(path) && (!overwrite)) {
    custom_stop(
      "The file {path}, already exists and `overwrite` is set to `FALSE`.",
      "To enable overwriting, use `overwrite = TRUE`."
    )
  }
  checkmate::assert_array(img)
  checkmate::assert_array(img, min.d = 2, max.d = 4)
  checkmate::assert_numeric(img)
  img %<>% ijtiff_img()
  compressions <- c(
    none = 1L, RLE = 2L, LZW = 5L, PackBits = 32773L, JPEG = 7L,
    deflate = 8L, Zip = 8L
  )
  compression %<>% strex::match_arg(names(compressions),
    ignore_case = TRUE
  ) %>% {
    compressions[match(., names(compressions))]
  }
  checkmate::assert_flag(msg)
  list(
    img = img, path = path, bits_per_sample = bits_per_sample,
    compression = compression, overwrite = overwrite, msg = msg
  )
}
