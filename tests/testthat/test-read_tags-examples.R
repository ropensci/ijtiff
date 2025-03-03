test_that("`read_tags()` works", {
  path <- system.file("img", "Rlogo.tif", package = "ijtiff")
  tags <- read_tags(path)
  # Test that the first frame has the expected tags
  expect_equal(tags$frame1$ImageWidth, 100)
  expect_equal(tags$frame1$ImageLength, 76)
  expect_equal(tags$frame1$BitsPerSample, 8)
  expect_equal(tags$frame1$SamplesPerPixel, 4)
  expect_equal(tags$frame1$SampleFormat, "unsigned integer data")
  expect_equal(tags$frame1$PlanarConfiguration, "contiguous")
  expect_equal(tags$frame1$RowsPerStrip, 76)
  expect_equal(tags$frame1$Compression, "LZW")
  expect_equal(tags$frame1$XResolution, 299.99, tolerance = 0.001)
  expect_equal(tags$frame1$YResolution, 299.99, tolerance = 0.001)
  expect_equal(tags$frame1$ResolutionUnit, "inch")
  expect_equal(tags$frame1$PhotometricInterpretation, "RGB")
  # Test reading multiple frames
  path <- system.file("img", "2ch_ij.tif", package = "ijtiff")
  multi_frame_tags <- read_tags(path, "all")
  # Test that frames 2 and 4 have consistent tags
  expect_equal(multi_frame_tags[c(2, 4)], tags_read(path, frames = c(2, 4)))
  # Test error on non-existent frames
  expect_error(
    read_tags(path, frames = c(11, 12)),
    "requested.+frame.+12.+only 5"
  )
  # Test that all frames have consistent tags
  expect_equal(dplyr::n_distinct(multi_frame_tags), 1)
  # Test reading first frame with JSON-mapped tags
  first_frame_tags <- read_tags(path)$frame1
  expect_equal(first_frame_tags$ImageWidth, 6L)
  expect_equal(first_frame_tags$ImageLength, 15L)
  expect_equal(first_frame_tags$BitsPerSample, 8L)
  expect_equal(first_frame_tags$SamplesPerPixel, 1L)
  expect_equal(first_frame_tags$SampleFormat, "unsigned integer data")
  expect_equal(first_frame_tags$PlanarConfiguration, "contiguous")
  expect_equal(first_frame_tags$RowsPerStrip, 15L)
  expect_equal(first_frame_tags$Compression, "none")
  expect_equal(first_frame_tags$ResolutionUnit, "inch")
  expect_equal(first_frame_tags$ImageDescription, paste0(
    "ImageJ=1.51s\nimages=10\n",
    "channels=2\nframes=5\n",
    "hyperstack=true\nmode=composite\n",
    "loop=false\n"
  ))
  expect_equal(first_frame_tags$PhotometricInterpretation, "BlackIsZero")
  # Test that all frames have consistent tags with first frame
  for (i in seq_along(multi_frame_tags)) {
    expect_equal(multi_frame_tags[[i]], first_frame_tags)
  }
})

test_that("read_tags handles JSON mapping correctly", {
  # Test that JSON file is loaded correctly
  json_path <- system.file("extdata", "tiff-tag-conversions.json", package = "ijtiff")
  expect_true(file.exists(json_path))
  # Test that PhotometricInterpretation is mapped correctly for various values
  test_files <- list(
    rgb = list(
      path = system.file("img", "Rlogo.tif", package = "ijtiff"),
      expected_photometric = "RGB",
      expected_compression = "LZW"
    ),
    blackiszero = list(
      path = system.file("img", "2ch_ij.tif", package = "ijtiff"),
      expected_photometric = "BlackIsZero",
      expected_compression = "none"
    )
  )
  for (test in test_files) {
    tags <- read_tags(test$path)
    expect_equal(tags$frame1$PhotometricInterpretation, test$expected_photometric)
    expect_equal(tags$frame1$Compression, test$expected_compression)
  }
})
