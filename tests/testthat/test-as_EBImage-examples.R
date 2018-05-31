context("`as_EBImage()`")

test_that("`as_EBImage()` works", {
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
  expect_equal(dim(img), c(76, 100, 4, 1))
  ebimg <- as_EBImage(img)
  expect_equal(dim(ebimg), c(100, 76, 4, 1))
  expect_is(ebimg, "Image")
  img <- read_tif(system.file("img", "2ch_ij.tif", package = "ijtiff"))
  expect_equal(dim(img), c(15, 6, 2, 5))
  ebimg <- as_EBImage(img)
  expect_equal(dim(ebimg), c(6, 15, 2, 5))
})
