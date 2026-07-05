test_that("12-bit grayscale TIFFs read as raw 0..4095 values", {
  p <- system.file("img", "gray12.tif", package = "ijtiff")
  img <- read_tif(p, msg = FALSE)
  expect_identical(dim(img), c(32L, 32L, 1L, 1L))
  expect_gte(min(img), 0)
  expect_lte(max(img), 4095)
  expect_gt(max(img), 255)          # proves it is not being truncated to 8-bit
  # horizontal ramp: column values increase left-to-right
  expect_true(all(diff(img[1, , 1, 1]) >= 0))
  expect_equal(round(max(img)), 4095)
})

test_that("odd-width 12-bit TIFFs decode without row-padding misalignment", {
  # 33x17: rowbytes = (33*12+7)/8 = 50, odd trailing sample -> exercises padding
  p <- system.file("img", "gray12_odd.tif", package = "ijtiff")
  img <- read_tif(p, msg = FALSE)
  expect_identical(dim(img), c(17L, 33L, 1L, 1L))
  # Every row is the SAME horizontal ramp; if rows misalign, rows after the
  # first are shifted and this fails.
  for (r in seq_len(dim(img)[1])) {
    expect_true(all(diff(img[r, , 1, 1]) >= 0),
                info = paste("row", r, "not monotonic -> row-padding bug"))
  }
  expect_equal(round(max(img)), 4095)
  expect_equal(round(min(img)), 0)
})
