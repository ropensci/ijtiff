test_that("copyright can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)
  
  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with a specific copyright value
  copyright_value <- "Copyright (c) 2025 Test User"
  
  # Write the image with copyright (suppress messages)
  write_tif(img, temp_file, copyright = copyright_value, msg = FALSE)
  
  # Read the image and check if copyright is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)
  
  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$Copyright, copyright_value)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("copyright accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with various valid values
  valid_values <- c(
    "Copyright (c) 2025",
    "© 2025 Example Organization",
    "All rights reserved",
    "Licensed under MIT",
    "Public Domain"
  )
  
  for (val in valid_values) {
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, copyright = val, overwrite = TRUE, msg = FALSE))
    
    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$Copyright, val)
  }
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("copyright rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with non-string value (should error)
  expect_error(write_tif(img, temp_file, copyright = 2025, msg = FALSE))
  
  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, copyright = c("Copyright 1", "Copyright 2"), msg = FALSE))
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
