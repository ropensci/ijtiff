test_that("yresolution can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)
  
  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with a specific yresolution value
  yres_value <- 300
  
  # Write the image with yresolution (suppress messages)
  write_tif(img, temp_file, yresolution = yres_value, msg = FALSE)
  
  # Read the image and check if yresolution is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)
  
  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$YResolution, yres_value)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("yresolution accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with different valid values
  valid_values <- c(72, 96, 150, 300, 600, 1200)
  
  for (val in valid_values) {
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, yresolution = val, overwrite = TRUE, msg = FALSE))
    
    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$YResolution, val)
  }
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("yresolution rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with negative value (should error)
  expect_error(write_tif(img, temp_file, yresolution = -100, msg = FALSE))
  
  # Test with non-numeric value (should error)
  expect_error(write_tif(img, temp_file, yresolution = "300dpi", msg = FALSE))
  
  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, yresolution = c(300, 600), msg = FALSE))
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("x and y resolution can be set together", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with specific x and y resolution values
  xres_value <- 300
  yres_value <- 600
  
  # Write the image with both resolutions (suppress messages)
  write_tif(img, temp_file, xresolution = xres_value, yresolution = yres_value, msg = FALSE)
  
  # Read the image and check if both resolutions are preserved
  tags <- read_tags(temp_file)
  
  # Check if both tags are present and have the correct values
  expect_equal(tags[[1]]$XResolution, xres_value)
  expect_equal(tags[[1]]$YResolution, yres_value)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
