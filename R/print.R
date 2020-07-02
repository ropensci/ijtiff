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
  d <- dim(x)
  cli::cli_text(
    "{d[1]}x{d[2]} pixel ijtiff_img ",
    "with {d[3]} channel{?s} and {d[4]} frame{?s}."
  )
  cli::cli_text("Preview (top left of first channel of first frame):")
  print(x[seq_len(min(6, d[1])), seq_len(min(6, d[2])), 1, 1])
  atts <- attributes(x)
  att_names <- names(attributes(x))
  cli::cat_line(cli::rule("TIFF tags"))
  possible_tags <- c("bits_per_sample", "samples_per_pixel", "sample_format",
                     "planar_config", "rows_per_strip", "tile_width",
                     "tile_length", "compression", "threshholding",
                     "software", "x_resolution", "y_resolution",
                     "resolution_unit", "x_position", "y_position", "indexed",
                     "orientation", "copyright", "artist",
                     "document_name", "date_time",
                     "description", "color_space", "color_map")
  for (pt in possible_tags) {
    if (pt %in% att_names) {
      if (pt == "color_map") {
        cli::cli_text(cli::symbol$bullet, " color map: ",
                      "matrix with {nrow(atts$color_map)} row{?s} ",
                      "and 3 columns (red, green, blue)")
      } else {
        cli::cli_text(cli::symbol$bullet, " {pt}: {atts[[pt]]}")
      }
    }
  }
  invisible(x)
}
