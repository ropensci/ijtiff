enlist_img <- function(img) {
  checkmate::assert_numeric(img)
  checkmate::assert_array(img, d = 4)
  purrr::map(seq_len(dim(img)[4]), ~ img[, , , .])
}

dims <- function(lst) {
  checkmate::assert_list(lst)
  dims_cpp(lst)
}