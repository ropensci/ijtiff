test_that("orientation can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)
  
  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with a specific orientation value (1 = default, top-left)
  orientation_value <- 1
  expected_orientation_name <- "top_left"
  
  # Write the image with orientation (suppress messages)
  write_tif(img, temp_file, orientation = orientation_value, msg = FALSE)
  
  # Read the image and check if orientation is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)
  
  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$Orientation, expected_orientation_name)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("orientation accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with all valid values
  valid_values <- 1:8
  expected_names <- c(
    "top_left", "top_right", "bottom_right", "bottom_left",
    "left_top", "right_top", "right_bottom", "left_bottom"
  )
  
  for (i in seq_along(valid_values)) {
    val <- valid_values[i]
    expected_name <- expected_names[i]
    
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, orientation = val, overwrite = TRUE, msg = FALSE))
    
    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$Orientation, expected_name)
  }
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("orientation rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with invalid value (should error)
  expect_error(write_tif(img, temp_file, orientation = 9, msg = FALSE))
  
  # Test with negative value (should error)
  expect_error(write_tif(img, temp_file, orientation = -1, msg = FALSE))
  
  # Test with non-integer value (should error)
  expect_error(write_tif(img, temp_file, orientation = "top_left", msg = FALSE))
  
  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, orientation = c(1, 2), msg = FALSE))
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
