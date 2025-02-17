test_that("TIFF tag handling works correctly", {
  path <- system.file("img", "Rlogo.tif", package = "ijtiff")
  img <- read_tif(path, msg = FALSE)
  # Test that basic tags are present and have correct values
  expect_equal(attr(img, "ImageWidth"), 100L)
  expect_equal(attr(img, "ImageLength"), 76L)
  expect_equal(attr(img, "BitsPerSample"), 8L)
  expect_equal(attr(img, "SamplesPerPixel"), 4L)
  # Test that photometric interpretation is correctly mapped from JSON
  expect_equal(attr(img, "PhotometricInterpretation"), "RGB")
  # Test that sample format is correctly mapped from JSON
  expect_equal(attr(img, "SampleFormat"), "unsigned integer data")
  # Test that all required tags are present
  required_tags <- c(
    "ImageWidth", "ImageLength", "BitsPerSample", "SamplesPerPixel",
    "SampleFormat", "PlanarConfiguration", "PhotometricInterpretation"
  )
  for (tag in required_tags) {
    expect_true(!is.null(attr(img, tag)))
  }
  # Test that tag values are consistent with image dimensions
  dims <- dim(img)
  expect_equal(dims[1], attr(img, "ImageLength"))
  expect_equal(dims[2], attr(img, "ImageWidth"))
  expect_equal(dims[3], attr(img, "SamplesPerPixel"))
  # Test that image data is preserved correctly
  img_data <- as.array(img)
  expect_true(all(img_data >= 0))
  expect_true(all(img_data <= 255))  # For 8-bit images
  # Test that tag values are consistent with image data type
  if (attr(img, "SampleFormat") == "uint8") {
    expect_true(all(as.integer(img_data) == img_data))
  }
})

test_that("TIFF tag error handling works", {
  # Create a temporary corrupt file
  tmp_corrupt <- tempfile(fileext = ".tif")
  writeLines("not a tiff file", tmp_corrupt)
  suppressWarnings(expect_error(read_tif(tmp_corrupt, msg = FALSE)))
})

test_that("TIFF tag reading works", {
  # Test reading a simple TIFF file
  path <- system.file("img", "Rlogo.tif", package = "ijtiff")
  img <- read_tif(path, msg = FALSE)
  # Check basic attributes
  expect_equal(attr(img, "BitsPerSample"), 8)
  expect_equal(attr(img, "SamplesPerPixel"), 4)
  expect_equal(attr(img, "SampleFormat"), "unsigned integer data")
  expect_equal(attr(img, "PlanarConfiguration"), "contiguous")
  expect_equal(attr(img, "Compression"), "LZW")
  expect_equal(attr(img, "PhotometricInterpretation"), "RGB")
  # Test that required attributes are present
  required_attrs <- c("BitsPerSample", "SamplesPerPixel",
    "SampleFormat", "PlanarConfiguration", "PhotometricInterpretation"
  )
  for (attr_name in required_attrs) {
    expect_true(!is.null(attr(img, attr_name)),
      info = paste("Missing attribute:", attr_name)
    )
  }
})

test_that("TIFF tag values are valid", {
  path <- system.file("img", "Rlogo.tif", package = "ijtiff")
  img <- read_tif(path, msg = FALSE)
  # Test that numeric attributes have valid values
  expect_true(attr(img, "BitsPerSample") > 0)
  expect_true(attr(img, "SamplesPerPixel") > 0)
  # Test that string attributes have valid values
  expect_match(attr(img, "SampleFormat"), "^(unsigned integer data|two's complement signed integer data|IEEE floating point data \\[IEEE\\]|undefined data format)$")
  expect_match(attr(img, "PlanarConfiguration"), "^(contiguous|separate)$")
  expect_match(attr(img, "Compression"), "^(none|LZW|JPEG|PackBits|CCITT1D|Group3Fax|Group4Fax|Deflate)$")
  expect_match(attr(img, "PhotometricInterpretation"), "^(WhiteIsZero|BlackIsZero|RGB|Palette|TransparencyMask|CMYK|YCbCr|CIELab)$")
})
