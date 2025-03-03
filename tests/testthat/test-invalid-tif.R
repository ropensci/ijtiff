test_that("TIFF tag error handling works", {
  tmp_corrupt <- tempfile(fileext = ".tif")
  writeLines("not a tiff file", tmp_corrupt)
  suppressWarnings(expect_error(read_tif(tmp_corrupt, msg = FALSE)))
  fs::file_delete(tmp_corrupt)
})
