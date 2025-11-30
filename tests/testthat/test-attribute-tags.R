test_that("attribute tags are extracted and used when tags_to_write is NULL", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Add some tags as attributes
  attr(img, "xresolution") <- 300
  attr(img, "yresolution") <- 300
  attr(img, "Artist") <- "Test Artist"

  # Write without tags_to_write
  write_tif(img, temp_file, msg = FALSE)

  # Read back and verify
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$XResolution, 300)
  expect_equal(tags[[1]]$YResolution, 300)
  expect_equal(tags[[1]]$Artist, "Test Artist")
})

test_that("attribute names are normalized correctly", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Test various formats for datetime
  attr(img, "Date-Time") <- "2024-01-01 12:00:00"

  write_tif(img, temp_file, msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$DateTime, "2024:01:01 12:00:00")

  # Test with underscores
  img <- matrix(1:100, nrow = 10)
  attr(img, "X_Resolution") <- 150

  write_tif(img, temp_file, overwrite = TRUE, msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$XResolution, 150)

  # Test with uppercase
  img <- matrix(1:100, nrow = 10)
  attr(img, "YRESOLUTION") <- 200

  write_tif(img, temp_file, overwrite = TRUE, msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$YResolution, 200)
})

test_that("tags_to_write takes precedence over attributes", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set attribute
  attr(img, "xresolution") <- 72

  # Override with tags_to_write
  write_tif(img, temp_file,
            tags_to_write = list(xresolution = 300),
            msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$XResolution, 300)
})

test_that("tags_to_write and attributes can be used together", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set some attributes
  attr(img, "xresolution") <- 300
  attr(img, "Artist") <- "Attribute Artist"

  # Provide different tags via tags_to_write
  write_tif(img, temp_file,
            tags_to_write = list(yresolution = 300, copyright = "Test Copyright"),
            msg = FALSE)

  tags <- read_tags(temp_file)
  # Should have both attribute tags and tags_to_write tags
  expect_equal(tags[[1]]$XResolution, 300)  # From attribute
  expect_equal(tags[[1]]$YResolution, 300)  # From tags_to_write
  expect_equal(tags[[1]]$Artist, "Attribute Artist")  # From attribute
  expect_equal(tags[[1]]$Copyright, "Test Copyright")  # From tags_to_write
})

test_that("standard array attributes are ignored", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set a valid tag attribute and some standard attributes
  attr(img, "xresolution") <- 300
  attr(img, "custom_attribute") <- "should be ignored"
  # dim, dimnames, class, names are automatically set by R

  # Should not error despite custom_attribute
  expect_no_error(write_tif(img, temp_file, msg = FALSE))

  # Verify only valid tag was written
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$XResolution, 300)
  expect_null(tags[[1]]$custom_attribute)
})

test_that("multiple attribute tags work together", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set multiple attributes
  attr(img, "xresolution") <- 300
  attr(img, "yresolution") <- 300
  attr(img, "resolutionunit") <- 2
  attr(img, "Artist") <- "Test Artist"
  attr(img, "Copyright") <- "Test Copyright"
  attr(img, "DocumentName") <- "Test Document"

  write_tif(img, temp_file, msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$XResolution, 300)
  expect_equal(tags[[1]]$YResolution, 300)
  expect_equal(tags[[1]]$ResolutionUnit, "inch")
  expect_equal(tags[[1]]$Artist, "Test Artist")
  expect_equal(tags[[1]]$Copyright, "Test Copyright")
  expect_equal(tags[[1]]$DocumentName, "Test Document")
})

test_that("all supported tags work via attributes", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set all supported tags as attributes
  attr(img, "xresolution") <- 300
  attr(img, "yresolution") <- 300
  attr(img, "resolutionunit") <- 2
  attr(img, "orientation") <- 1
  attr(img, "xposition") <- 0.5
  attr(img, "yposition") <- 0.5
  attr(img, "copyright") <- "Test Copyright"
  attr(img, "artist") <- "Test Artist"
  attr(img, "documentname") <- "Test Document"
  attr(img, "datetime") <- "2024-01-01 12:00:00"
  attr(img, "imagedescription") <- "Test Description"

  write_tif(img, temp_file, msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$XResolution, 300)
  expect_equal(tags[[1]]$YResolution, 300)
  expect_equal(tags[[1]]$ResolutionUnit, "inch")
  expect_equal(tags[[1]]$Orientation, "top_left")
  expect_equal(tags[[1]]$XPosition, 0.5)
  expect_equal(tags[[1]]$YPosition, 0.5)
  expect_equal(tags[[1]]$Copyright, "Test Copyright")
  expect_equal(tags[[1]]$Artist, "Test Artist")
  expect_equal(tags[[1]]$DocumentName, "Test Document")
  expect_equal(tags[[1]]$DateTime, "2024:01:01 12:00:00")
  expect_equal(tags[[1]]$ImageDescription, "Test Description")
})

test_that("compression can be specified via attribute", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set compression as attribute
  attr(img, "compression") <- "LZW"

  write_tif(img, temp_file, compression = "none", msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "LZW")
})

test_that("bitspersample can be specified via attribute", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set bitspersample as attribute
  attr(img, "bitspersample") <- 16

  write_tif(img, temp_file, bits_per_sample = "auto", msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$BitsPerSample, 16)
})

test_that("attribute compression with non-normalized name works", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set compression as attribute with hyphens
  attr(img, "Com-pression") <- "LZW"

  write_tif(img, temp_file, compression = "none", msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "LZW")
})

test_that("attribute bitspersample with non-normalized name works", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set bitspersample as attribute with underscores
  attr(img, "bits_per_sample") <- 32

  write_tif(img, temp_file, bits_per_sample = "auto", msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$BitsPerSample, 32)
})

test_that("tags_to_write overrides attribute compression", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set compression as attribute
  attr(img, "compression") <- "LZW"

  # Override with tags_to_write
  write_tif(img, temp_file, compression = "none",
            tags_to_write = list(compression = "Zip"),
            msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "Deflate")  # Zip appears as Deflate
})

test_that("tags_to_write overrides attribute bitspersample", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set bitspersample as attribute
  attr(img, "bitspersample") <- 16

  # Override with tags_to_write
  write_tif(img, temp_file, bits_per_sample = "auto",
            tags_to_write = list(bitspersample = 32),
            msg = FALSE)

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$BitsPerSample, 32)
})

test_that("invalid tag attributes are ignored", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Set invalid tag as attribute
  attr(img, "invalidtag") <- "value"
  attr(img, "xresolution") <- 300

  # Should not error and should write valid tag
  expect_no_error(write_tif(img, temp_file, msg = FALSE))

  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$XResolution, 300)
})
