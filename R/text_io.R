#' Read/write an image array to/from disk as text file(s).
#'
#' Write images (arrays) as tab-separated `.txt` files on disk. Each
#' channel-frame pair gets its own file.
#'
#' @param img An image, represented by a 4-dimensional array, like an
#'   [ijtiff_img].
#' @param path The name of the input/output output file(s), \emph{without} a
#'   file extension.
#' @param rds In addition to writing a text file, save the image as an RDS (a
#'   single R object) file?
#'
#' @name text-image-io
NULL

#' @rdname text-image-io
#'
#' @examples
#' setwd(tempdir())
#' img <- read_tif(system.file('img', 'Rlogo.tif', package = 'ijtiff'))
#' write_txt_img(img, 'temp')
#'
#' @export
write_txt_img <- function(img, path, rds = FALSE) {
  checkmate::assert_array(img)
  checkmate::assert_numeric(img)
  d <- dim(img)
  nd <- length(d)
  if (nd != 4) {
    stop("img should be 4-dimensional, in the mould of an ijtiff_img")
  }
  chs <- as.logical(d[3] - 1)
  frames <- as.logical(d[4] - 1)
  if (rds) saveRDS(img, file = filesstrings::give_ext(path, "rds"))
  grid <- expand.grid(seq_len(d[3]), seq_len(d[4])) %>% as.matrix()
  ch_part <- ""
  if (chs) ch_part <- paste0("_ch", grid[, 1])
  frame_part <- ""
  if (frames) frame_part <- paste0("_frame", grid[, 2])
  paths <- paste0(path, ch_part, frame_part) %>%
    purrr::map_chr(filesstrings::give_ext, "txt") %T>%
    {if (length(.) > 1) . <- filesstrings::nice_nums(.)}
  dfs <- purrr::map(enlist_rows(grid), ~ img[, , .[1], .[2]]) %>%
    purrr::map(as.data.frame)
  purrr::map2(dfs, paths, ~ readr::write_tsv(.x, .y, col_names = FALSE))
  invisible(img)
}

#' @rdname text-image-io
#'
#' @examples
#' img <- read_txt_img('temp_ch1.txt')
#' suppressWarnings(file.remove(list.files()))  # cleanup
#' @export
read_txt_img <- function(path) {
  suppressMessages(readr::read_tsv(path, col_names = FALSE,
                                   progress = FALSE)) %>%
    data.matrix() %>%
    magrittr::set_colnames(value = NULL)
}
