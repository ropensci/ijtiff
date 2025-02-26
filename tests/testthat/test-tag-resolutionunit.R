test_that("resolutionunit can be written and read back", {
  # Test with a specific resolutionunit value (2 = inch)
  unit_value <- 2
  expected_unit_name <- "inch"

  # Write and read the image
  tags <- test_tag_write_read("resolutionunit", unit_value, expected_unit_name)

  # Check if the tag has the correct name
  expect_equal(tags[[1]]$ResolutionUnit, expected_unit_name)
})

test_that("resolutionunit accepts valid values", {
  # Test with all valid values
  valid_values <- c(1, 2, 3) # 1 = none, 2 = inch, 3 = cm
  expected_names <- c("none", "inch", "cm")

  # Test valid values with expected transformations
  test_tag_valid_values("resolutionunit", valid_values, expected_names)
})

test_that("resolutionunit rejects invalid values", {
  # Test with invalid values
  invalid_values <- list(
    4, # Out of range
    -1, # Negative
    "inch", # Non-integer
    c(1, 2) # Multiple values
  )

  test_tag_invalid_values("resolutionunit", invalid_values)
})

test_that("resolution values work together with resolutionunit", {
  # Test with all resolution parameters
  xres_value <- 300
  yres_value <- 300
  unit_value <- 2 # inch
  expected_unit_name <- "inch"

  # Create a simple test image
  img <- create_test_image()

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  on.exit(if (file.exists(temp_file)) file.remove(temp_file), add = TRUE)

  # Write the image with all resolution parameters
  write_tif(img, temp_file,
    xresolution = xres_value,
    yresolution = yres_value,
    resolutionunit = unit_value,
    msg = FALSE
  )

  # Read the image and check if all parameters are preserved
  tags <- read_tags(temp_file)

  # Check if all tags are present and have the correct values
  expect_equal(tags[[1]]$XResolution, xres_value)
  expect_equal(tags[[1]]$YResolution, yres_value)
  expect_equal(tags[[1]]$ResolutionUnit, expected_unit_name)
})
