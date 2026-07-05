test_that("signed-integer TIFFs read with correct negative values and no warning", {
  p <- system.file("img", "signed16.tif", package = "ijtiff")
  expect_no_warning(img <- read_tif(p, msg = FALSE))
  expect_lt(min(img), 0)                 # genuine negatives survive
  expect_gte(min(img), -32768)
  expect_lte(max(img), 32767)
  expect_match(attr(img, "SampleFormat"), "signed integer")
})
