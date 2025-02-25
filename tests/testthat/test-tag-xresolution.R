test_that("xresolution can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)
  
  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with a specific xresolution value
  xres_value <- 300
  
  # Write the image with xresolution (suppress messages)
  write_tif(img, temp_file, xresolution = xres_value, msg = FALSE)
  
  # Read the image and check if xresolution is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)
  
  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$XResolution, xres_value)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("xresolution accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with different valid values
  valid_values <- c(72, 96, 150, 300, 600, 1200)
  
  for (val in valid_values) {
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, xresolution = val, overwrite = TRUE, msg = FALSE))
    
    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$XResolution, val)
  }
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("xresolution rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with negative value (should error)
  expect_error(write_tif(img, temp_file, xresolution = -100, msg = FALSE))
  
  # Test with non-numeric value (should error)
  expect_error(write_tif(img, temp_file, xresolution = "300dpi", msg = FALSE))
  
  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, xresolution = c(300, 600), msg = FALSE))
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
