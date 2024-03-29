#' Read/write an image array to/from disk as text file(s).
#'
#' Write images (arrays) as tab-separated `.txt` files on disk. Each
#' channel-frame pair gets its own file.
#'
#' @param img An image, represented by a 4-dimensional array, like an
#'   [ijtiff_img].
#' @param path The name of the input/output output file(s), *without* a
#'   file extension.
#' @param rds In addition to writing a text file, save the image as an RDS (a
#'   single R object) file?
#' @inheritParams read_tif
#'
#' @name text-image-io
NULL

#' @rdname text-image-io
#'
#' @examples
#' img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
#' tmptxt <- tempfile(pattern = "img", fileext = ".txt")
#' write_txt_img(img, tmptxt)
#' tmptxt_ch1_path <- paste0(strex::str_before_last_dot(tmptxt), "_ch1.txt")
#' print(tmptxt_ch1_path)
#' txt_img <- read_txt_img(tmptxt_ch1_path)
#' @export
write_txt_img <- function(img, path, rds = FALSE, msg = TRUE) {
  checkmate::assert_array(img, min.d = 2, max.d = 4)
  checkmate::assert_numeric(img)
  img <- ijtiff_img(img)
  d <- dim(img)
  chs <- as.logical(d[3] - 1)
  frames <- as.logical(d[4] - 1)
  if (rds) saveRDS(img, file = strex::str_give_ext(path, "rds"))
  grid <- expand.grid(seq_len(d[3]), seq_len(d[4])) %>% as.matrix()
  ch_part <- ""
  if (chs) ch_part <- paste0("_ch", grid[, 1])
  frame_part <- ""
  if (frames) frame_part <- paste0("_frame", grid[, 2])
  paths <- paste0(strex::str_before_last_dot(path), ch_part, frame_part) %>%
    purrr::map_chr(strex::str_give_ext, "txt")
  if (length(paths) > 1) paths <- strex::str_alphord_nums(paths)
  msg_paths <- paths
  for (i in seq_along(msg_paths)) {
    if (stringr::str_detect(msg_paths[i], stringr::coll("/"))) {
      msg_paths[i] <- strex::str_after_last(msg_paths[i], stringr::coll("/"))
    }
  }
  if (length(msg_paths) > 1) {
    msg_paths <- stringr::str_c(
      stringr::str_c(msg_paths[-length(msg_paths)], collapse = ", "),
      " and ",
      msg_paths[length(msg_paths)]
    )
  }
  if (msg) {
    message(
      "Writing ", msg_paths, ": a ", d[1], "x", d[2],
      " pixel text image with ", d[3],
      " ", "channel", ifelse(d[3] > 1, "s", ""), " and ",
      d[4], " frame", ifelse(d[4] > 1, "s", ""), " . . ."
    )
  }
  dfs <- purrr::map(
    purrr::map(seq_len(nrow(grid)), ~ grid[., ]),
    ~ img[, , .[1], .[2]]
  ) %>%
    purrr::map(as.data.frame)
  for (i in seq_along(dfs)) {
    dfs[[i]] <- dplyr::mutate_if(dfs[[i]], can_be_intish, as.integer)
  }
  purrr::map2(dfs, paths, ~ readr::write_tsv(.x, .y, col_names = FALSE))
  if (msg) message("\b Done.")
  invisible(img)
}

#' @rdname text-image-io
#'
#' @export
read_txt_img <- function(path, msg = TRUE) {
  out <- suppressMessages(readr::read_tsv(path,
    col_names = FALSE,
    progress = FALSE
  ))
  for (i in seq_len(ncol(out))) {
    if (all(strex::str_can_be_numeric(out[[i]]))) {
      out[[i]] <- as.numeric(out[[i]])
    } else {
      rlang::abort(
        c(
          paste(
            "`path` must be the path to a text file which is an array",
            "of numbers."
          ),
          x = stringr::str_glue(
            "Column {i} of the text file at your ",
            "`path` {path} is not numeric."
          )
        )
      )
    }
  }
  if (msg) {
    if (stringr::str_detect(path, stringr::coll("/"))) {
      path <- strex::str_after_last(path, stringr::coll("/"))
    }
    d <- dim(out)
    message("Reading ", d[1], "x", d[2], " pixel text image '", path, "' . . .")
  }
  out <- out %>%
    data.matrix() %>%
    magrittr::set_colnames(value = NULL)
  if (msg) message("\b Done.")
  out
}

#' @rdname text-image-io
#' @export
txt_img_write <- write_txt_img

#' @rdname text-image-io
#' @export
txt_img_read <- read_txt_img
