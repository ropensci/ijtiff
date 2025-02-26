test_that("documentname can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")

  # Test with a specific documentname value
  documentname_value <- "Test Document"

  # Write the image with documentname (suppress messages)
  write_tif(img, temp_file, documentname = documentname_value, msg = FALSE)

  # Read the image and check if documentname is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)

  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$DocumentName, documentname_value)

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("documentname accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")

  # Test with various valid values
  valid_values <- c(
    "Sample Document",
    "Report 2025-01-01",
    "Experiment Results",
    "Microscopy Data",
    "Patient Record 12345"
  )

  for (val in valid_values) {
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, documentname = val, overwrite = TRUE, msg = FALSE))

    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$DocumentName, val)
  }

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("documentname rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")

  # Test with non-string value (should error)
  expect_error(write_tif(img, temp_file, documentname = 123, msg = FALSE))

  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, documentname = c("Doc1", "Doc2"), msg = FALSE))

  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
