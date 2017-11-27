context("Utils")
test_that("enlisting rows and cols works", {
  mm <- matrix(runif(100), nrow = 20)
  expect_equal(enlist_rows(mm), enlist_cols(t(mm)))
})