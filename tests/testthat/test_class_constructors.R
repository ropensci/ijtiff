context("Class constructors")

test_that("ijtiff_img works", {
  img <- array(seq_len(2^4), dim = rep(2, 4))
  eq_to <- img
  attr(eq_to, "bits_per_sample") <- 8
  class(eq_to) <- c("ijtiff_img", class(eq_to))
  expect_equal(ijtiff_img(img, bits_per_sample = 8), eq_to)
  img <- img[, , 1, ]
  expect_equal(dim(ijtiff_img(img)), c(2, 2, 1, 2))
})
