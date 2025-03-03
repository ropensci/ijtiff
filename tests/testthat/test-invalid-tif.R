test_that("TIFF tag error handling works", {
  # Create a temporary corrupt file
  tmp_corrupt <- tempfile(fileext = ".tif")
  writeLines("not a tiff file", tmp_corrupt)
  suppressWarnings(expect_error(read_tif(tmp_corrupt, msg = FALSE)))
})
