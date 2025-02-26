#' Get supported TIFF tags
#'
#' Returns a named integer vector of supported TIFF tags. The names are the
#' human-readable tag names, and the values are the corresponding tag codes.
#'
#' @return A named integer vector of supported TIFF tags
#'
#' @export
get_supported_tags <- function() {
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)
  .Call("get_supported_tags_C", temp_file, PACKAGE = "ijtiff")
}
