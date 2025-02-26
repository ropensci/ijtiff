test_that("yposition can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")

  # Test with a specific yposition value
  yposition_value <- 15.75

  # Write the image with yposition (suppress messages)
  write_tif(img, temp_file, yposition = yposition_value, msg = FALSE)

  # Read the image and check if yposition is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)

  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$YPosition, yposition_value)

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("yposition accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")

  # Test with various valid values
  valid_values <- c(0, 2.5, 20, 200.25, 2000)

  for (val in valid_values) {
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, yposition = val, overwrite = TRUE, msg = FALSE))

    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$YPosition, val)
  }

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("yposition rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")

  # Test with non-numeric value (should error)
  expect_error(write_tif(img, temp_file, yposition = "20", msg = FALSE))

  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, yposition = c(1, 2), msg = FALSE))

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
