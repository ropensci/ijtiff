test_that("print method works", {
  skip_if(.Platform$OS.type != "unix")
  suppressMessages(
    expect_snapshot(read_tif(test_path("testthat-figs", "Rlogo-banana-red.tif")))
  )
})
