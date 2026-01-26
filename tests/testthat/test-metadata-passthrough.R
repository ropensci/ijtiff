test_that("metadata is automatically preserved on write without tags_to_write", {
  # Create test image with metadata tags
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file_1 <- tempfile(fileext = ".tif")
  temp_file_2 <- tempfile(fileext = ".tif")
  on.exit(unlink(c(temp_file_1, temp_file_2)), add = TRUE)

  # Write image with metadata
  metadata <- list(
    xresolution = 300.0,
    yresolution = 300.0,
    resolutionunit = 2L,
    artist = "Test Artist",
    copyright = "(c) 2024 Test",
    imagedescription = "Test description"
  )
  write_tif(img, temp_file_1, msg = FALSE, tags_to_write = metadata)

  # Read image with metadata
  img_read <- read_tif(temp_file_1, msg = FALSE)

  # Write without specifying tags_to_write - metadata should be auto-preserved
  write_tif(img_read, temp_file_2, msg = FALSE)

  # Read back tags and verify they match original metadata
  tags_original <- read_tags(temp_file_1)[[1]]
  tags_roundtrip <- read_tags(temp_file_2)[[1]]

  expect_equal(tags_roundtrip$XResolution, tags_original$XResolution)
  expect_equal(tags_roundtrip$YResolution, tags_original$YResolution)
  expect_equal(tags_roundtrip$ResolutionUnit, tags_original$ResolutionUnit)
  expect_equal(tags_roundtrip$Artist, tags_original$Artist)
  expect_equal(tags_roundtrip$Copyright, tags_original$Copyright)
  expect_equal(tags_roundtrip$ImageDescription, tags_original$ImageDescription)
})

test_that("explicit tags_to_write overrides auto-detected metadata", {
  # Create test image with metadata tags
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file_1 <- tempfile(fileext = ".tif")
  temp_file_2 <- tempfile(fileext = ".tif")
  on.exit(unlink(c(temp_file_1, temp_file_2)), add = TRUE)

  # Write image with initial metadata
  initial_metadata <- list(
    xresolution = 300.0,
    yresolution = 300.0,
    artist = "Original Artist",
    copyright = "(c) 2024 Original"
  )
  write_tif(img, temp_file_1, msg = FALSE, tags_to_write = initial_metadata)

  # Read image
  img_read <- read_tif(temp_file_1, msg = FALSE)

  # Write with some tags overridden
  override_metadata <- list(
    artist = "New Artist",
    imagedescription = "New description"
  )
  write_tif(img_read, temp_file_2, msg = FALSE, tags_to_write = override_metadata)

  # Read back tags
  tags <- read_tags(temp_file_2)[[1]]

  # Overridden tag should have new value
  expect_equal(tags$Artist, "New Artist")
  # New tag should be added
  expect_equal(tags$ImageDescription, "New description")
  # Non-overridden tags should be preserved from auto-detection
  expect_equal(tags$XResolution, 300.0)
  expect_equal(tags$YResolution, 300.0)
  expect_equal(tags$Copyright, "(c) 2024 Original")
})

test_that("write without tags_to_write works for image without attributes", {
  # Create plain image without reading from file
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Should not error when writing image without attributes
  expect_no_error(write_tif(img, temp_file, msg = FALSE))

  # Image should be written successfully
  expect_true(file.exists(temp_file))

  # Should be readable
  img_read <- read_tif(temp_file, msg = FALSE)
  expect_equal(dim(img_read), c(2, 2, 1, 1))
})

test_that("only valid TIFF tags are preserved from attributes", {
  # Create test image with metadata
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file_1 <- tempfile(fileext = ".tif")
  temp_file_2 <- tempfile(fileext = ".tif")
  on.exit(unlink(c(temp_file_1, temp_file_2)), add = TRUE)

  # Write with valid metadata
  write_tif(img, temp_file_1, msg = FALSE, tags_to_write = list(
    artist = "Test Artist",
    copyright = "(c) 2024"
  ))

  # Read and manually add invalid attribute
  img_read <- read_tif(temp_file_1, msg = FALSE)
  attr(img_read, "InvalidTag") <- "should be ignored"
  attr(img_read, "SomeOtherAttr") <- "also ignored"

  # Write without error
  expect_no_error(write_tif(img_read, temp_file_2, msg = FALSE))

  # Read back - should have valid tags
  tags <- read_tags(temp_file_2)[[1]]
  expect_equal(tags$Artist, "Test Artist")
  expect_equal(tags$Copyright, "(c) 2024")
})

test_that("explicit tags_to_write = NULL still triggers auto-detection", {
  # Create test image with metadata
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file_1 <- tempfile(fileext = ".tif")
  temp_file_2 <- tempfile(fileext = ".tif")
  on.exit(unlink(c(temp_file_1, temp_file_2)), add = TRUE)

  # Write image with metadata
  write_tif(img, temp_file_1, msg = FALSE, tags_to_write = list(
    artist = "Test Artist",
    imagedescription = "Test description"
  ))

  # Read image
  img_read <- read_tif(temp_file_1, msg = FALSE)

  # Explicitly pass NULL for tags_to_write - should still auto-preserve
  write_tif(img_read, temp_file_2, msg = FALSE, tags_to_write = NULL)

  # Read back tags and verify
  tags <- read_tags(temp_file_2)[[1]]
  expect_equal(tags$Artist, "Test Artist")
  expect_equal(tags$ImageDescription, "Test description")
})

test_that("partial metadata override merges tags correctly", {
  # Create test image
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file_1 <- tempfile(fileext = ".tif")
  temp_file_2 <- tempfile(fileext = ".tif")
  on.exit(unlink(c(temp_file_1, temp_file_2)), add = TRUE)

  # Write with multiple metadata tags
  write_tif(img, temp_file_1, msg = FALSE, tags_to_write = list(
    xresolution = 300.0,
    yresolution = 300.0,
    artist = "Artist 1",
    copyright = "Copyright 1",
    documentname = "Doc 1"
  ))

  # Read image
  img_read <- read_tif(temp_file_1, msg = FALSE)

  # Override only some tags
  write_tif(img_read, temp_file_2, msg = FALSE, tags_to_write = list(
    artist = "Artist 2",
    imagedescription = "New description"
  ))

  # Verify result
  tags <- read_tags(temp_file_2)[[1]]

  # Overridden tag
  expect_equal(tags$Artist, "Artist 2")
  # New tag
  expect_equal(tags$ImageDescription, "New description")
  # Preserved tags
  expect_equal(tags$XResolution, 300.0)
  expect_equal(tags$YResolution, 300.0)
  expect_equal(tags$Copyright, "Copyright 1")
  expect_equal(tags$DocumentName, "Doc 1")
})
