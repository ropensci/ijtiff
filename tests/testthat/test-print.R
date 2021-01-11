test_that("print method works", {
  expect_snapshot(read_tif(test_path("testthat-figs", "Rlogo-banana-red.tif")))
})
