context("Graphics")

test_that("display works", {
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
  grDevices::pdf(tempfile(fileext = ".pdf"))
  expect_null(display(img[, , 1, 1]))
  expect_null(display(img[, , 2, 1]))
  expect_null(display(img[, , 3, 1]))
  grDevices::dev.off()
})
