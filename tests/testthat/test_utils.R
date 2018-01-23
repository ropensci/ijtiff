context("Utils")

test_that("enlisting rows and cols works", {
  mm <- matrix(runif(100), nrow = 20)
  expect_equal(enlist_rows(mm), enlist_cols(t(mm)))
})

test_that("extract_desired_plane() works", {
  aaa <- array(0, dim = rep(3, 3))
  expect_equal(extract_desired_plane(aaa), aaa[, , 1])
  aaa[] <- 1
  aaa[[1]] <- 2
  expect_error(extract_desired_plane(aaa),
               "Cannot extract the desired plane.")
})
