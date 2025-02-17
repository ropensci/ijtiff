#' Print method for an `ijtiff_img`.
#'
#' @param x An object of class [ijtiff_img].
#' @param ... Not currently used.
#'
#' @return The input (invisibly).
#'
#' @export
print.ijtiff_img <- function(x, ...) {
  checkmate::assert_class(x, "ijtiff_img")
  checkmate::assert(length(dim(x)) == 4)
  d <- dim(x)
  cli::cli_text(
    "{d[1]}x{d[2]} pixel ijtiff_img ",
    "with {d[3]} channel{?s} and {d[4]} frame{?s}."
  )
  cli::cli_text("Preview (top left of first channel of first frame):")
  print(x[seq_len(min(6, d[1])), seq_len(min(6, d[2])), 1, 1])
  att_names <- names(attributes(x))
  cli::cat_line(cli::rule("TIFF tags"))
  possible_tags <- c(
    "BitsPerSample", "SamplesPerPixel", "SampleFormat",
    "PlanarConfig", "RowsPerStrip", "TileWidth",
    "TileLength", "Compression", "Threshholding",
    "Software", "XResolution", "YResolution",
    "ResolutionUnit", "XPosition", "YPosition",
    "Orientation", "Copyright", "Artist",
    "DocumentName", "DateTime", "ImageDescription",
    "Photometric", "ColorMap"
  )
  for (pt in possible_tags) {
    if (pt %in% att_names) {
      if (pt == "ColorMap") {
        cli::cli_text(
          cli::symbol$bullet, " color map: ",
          "matrix with {nrow(attr(x, 'ColorMap'))} row{?s} ",
          "and 3 columns (red, green, blue)"
        )
      } else {
        cli::cli_text(cli::symbol$bullet, " {pt}: {attr(x, pt)}")
      }
    }
  }
  invisible(x)
}
