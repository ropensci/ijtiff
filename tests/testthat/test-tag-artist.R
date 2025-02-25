test_that("artist can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)
  
  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with a specific artist value
  artist_value <- "Test User"
  
  # Write the image with artist (suppress messages)
  write_tif(img, temp_file, artist = artist_value, msg = FALSE)
  
  # Read the image and check if artist is preserved
  img_read <- read_tif(temp_file, msg = FALSE)
  tags <- read_tags(temp_file)
  
  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]]$Artist, artist_value)
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("artist accepts valid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with various valid values
  valid_values <- c(
    "John Doe",
    "Jane Smith, Ph.D.",
    "Imaging Lab Team",
    "Anonymous",
    "Organization Name"
  )
  
  for (val in valid_values) {
    # Should not error (suppress messages)
    expect_no_error(write_tif(img, temp_file, artist = val, overwrite = TRUE, msg = FALSE))
    
    # Read and verify
    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$Artist, val)
  }
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})

test_that("artist rejects invalid values", {
  img <- matrix(1:4, nrow = 2)
  temp_file <- tempfile(fileext = ".tif")
  
  # Test with non-string value (should error)
  expect_error(write_tif(img, temp_file, artist = 123, msg = FALSE))
  
  # Test with multiple values (should error)
  expect_error(write_tif(img, temp_file, artist = c("John", "Jane"), msg = FALSE))
  
  # Clean up
  if (file.exists(temp_file)) file.remove(temp_file)
})
