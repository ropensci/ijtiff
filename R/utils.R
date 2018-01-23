enlist_img <- function(img) {
  checkmate::assert_numeric(img)
  checkmate::assert_array(img, d = 4)
  purrr::map(seq_len(dim(img)[4]), ~ img[, , , .])
}

dims <- function(lst) {
  checkmate::assert_list(lst)
  dims_cpp(lst)
}

enlist_cols <- function(mat) {
  checkmate::assert_matrix(mat)
  purrr::map(seq_len(ncol(mat)), ~ mat[, .])
}
enlist_rows <- function(mat) {
  checkmate::assert_matrix(mat)
  purrr::map(seq_len(nrow(mat)), ~ mat[., ])
}
enlist_planes <- function(arr) {
  checkmate::assert_array(arr, d = 3)
  purrr::map(seq_len(dim(arr)[3]), ~ arr[, , .])
}

extract_desired_plane <- function(arr) {
  checkmate::assert_array(arr, min.d = 2, max.d = 3)
  d <- dim(arr)
  if (length(d) == 3) {
    nonzero_planes <- !purrr::map_lgl(seq_len(d[3]),
                                      ~ filesstrings::all_equal(arr[, , .], 0))
    if (sum(nonzero_planes) == 0) {
      arr <- arr[, , 1]
    } else if (sum(nonzero_planes) == 1) {
      arr <- arr[, , nonzero_planes]
    } else if (filesstrings::all_equal(enlist_planes(arr))) {
      arr <- arr[, , 1]
    } else {
      stop("Cannot extract the desired plane.")
    }
  }
  arr
}