test_that("xposition can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")

  # Test with a specific xposition value
  xposition_value <- 10.5

  # Write the image with xposition (suppress messages)
  write_tif(img, temp_file, xposition = xposition_value, msg = FALSE)

  # Read the image and check if xposition is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)

  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$XPosition, xposition_value)

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("xposition accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")

  # Test with various valid values
  valid_values <- c(0, 1.5, 10, 100.25, 1000)

  for (val in valid_values) {
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, xposition = val, overwrite = TRUE, msg = FALSE))

    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$XPosition, val)
  }

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("xposition rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")

  # Test with non-numeric value (should error)
  expect_error(write_tif(img, temp_file, xposition = "10", msg = FALSE))

  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, xposition = c(1, 2), msg = FALSE))

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
