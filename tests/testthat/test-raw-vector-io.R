test_that("read_tif reads from an in-memory raw vector identically to a file", {
  p <- system.file("img", "Rlogo.tif", package = "ijtiff")
  from_file <- read_tif(p, msg = FALSE)
  bytes <- readBin(p, "raw", n = file.info(p)$size)
  from_raw <- read_tif(bytes, msg = FALSE)
  expect_identical(as.array(from_raw), as.array(from_file))
  expect_identical(dim(from_raw), dim(from_file))
})

test_that("write_tif(img, NULL) returns bytes that read back identically", {
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"), msg = FALSE)
  bytes <- write_tif(img, NULL, msg = FALSE)
  expect_type(bytes, "raw")
  expect_gt(length(bytes), 100L)
  back <- read_tif(bytes, msg = FALSE)
  # Compare pixels + shape, not attributes: the written file gains a Software
  # tag and (pre-Task 7) a MINISBLACK photometric, so attributes legitimately
  # differ from the source. (testthat 3e's expect_equal compares attributes.)
  expect_equal(as.vector(back), as.vector(img))
  expect_identical(dim(back), dim(img))
})
