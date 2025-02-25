test_that("resolutionunit can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)
  
  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with a specific resolutionunit value (2 = inch)
  unit_value <- 2
  expected_unit_name <- "inch"
  
  # Write the image with resolutionunit (suppress messages)
  write_tif(img, temp_file, resolutionunit = unit_value, msg = FALSE)
  
  # Read the image and check if resolutionunit is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)
  
  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$ResolutionUnit, expected_unit_name)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("resolutionunit accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with all valid values
  valid_values <- c(1, 2, 3)  # 1 = none, 2 = inch, 3 = cm
  expected_names <- c("none", "inch", "cm")
  
  for (i in seq_along(valid_values)) {
    val <- valid_values[i]
    expected_name <- expected_names[i]
    
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, resolutionunit = val, overwrite = TRUE, msg = FALSE))
    
    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$ResolutionUnit, expected_name)
  }
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("resolutionunit rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with invalid value (should error)
  expect_error(write_tif(img, temp_file, resolutionunit = 4, msg = FALSE))
  
  # Test with negative value (should error)
  expect_error(write_tif(img, temp_file, resolutionunit = -1, msg = FALSE))
  
  # Test with non-integer value (should error)
  expect_error(write_tif(img, temp_file, resolutionunit = "inch", msg = FALSE))
  
  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, resolutionunit = c(1, 2), msg = FALSE))
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("resolution values work together with resolutionunit", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with all resolution parameters
  xres_value <- 300
  yres_value <- 300
  unit_value <- 2  # inch
  expected_unit_name <- "inch"
  
  # Write the image with all resolution parameters (suppress messages)
  write_tif(img, temp_file, 
            xresolution = xres_value, 
            yresolution = yres_value, 
            resolutionunit = unit_value, 
            msg = FALSE)
  
  # Read the image and check if all parameters are preserved
  tags <- read_tags(temp_file)
  
  # Check if all tags are present and have the correct values
  expect_equal(tags[[1]]$XResolution, xres_value)
  expect_equal(tags[[1]]$YResolution, yres_value)
  expect_equal(tags[[1]]$ResolutionUnit, expected_unit_name)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
