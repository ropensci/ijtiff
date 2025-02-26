test_that("yresolution can be written and read back", {
  # Test with a specific yresolution value
  yres_value <- 300

  # Write and read the image
  tags <- test_tag_write_read("yresolution", yres_value)

  # Check if the tag has the correct value
  expect_equal(tags[[1]]$YResolution, yres_value)
})

test_that("yresolution accepts valid values", {
  # Test with different valid values
  valid_values <- c(72, 96, 150, 300, 600, 1200)

  test_tag_valid_values("yresolution", valid_values)
})

test_that("yresolution rejects invalid values", {
  # Test with invalid values
  invalid_values <- list(
    -100, # Negative
    "300dpi", # Non-numeric
    c(300, 600) # Multiple values
  )

  test_tag_invalid_values("yresolution", invalid_values)
})

test_that("x and y resolution can be set together", {
  # Test with specific x and y resolution values
  xres_value <- 300
  yres_value <- 600

  # Create a simple test image
  img <- create_test_image()

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  on.exit(if (file.exists(temp_file)) file.remove(temp_file), add = TRUE)

  # Write the image with both resolutions
  write_tif(img, temp_file, xresolution = xres_value, yresolution = yres_value, msg = FALSE)

  # Read the image and check if both resolutions are preserved
  tags <- read_tags(temp_file)

  # Check if both tags are present and have the correct values
  expect_equal(tags[[1]]$XResolution, xres_value)
  expect_equal(tags[[1]]$YResolution, yres_value)
})
