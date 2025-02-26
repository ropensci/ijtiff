test_that("orientation can be written and read back", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")

  # Test with a specific orientation value (1 = default, top-left)
  orientation_value <- 1
  expected_orientation_name <- "top_left"

  # Write and read the image
  tags <- test_tag_write_read("orientation", orientation_value, expected_orientation_name)

  # Check if the tag has the correct name
  expect_equal(tags[[1]]$Orientation, expected_orientation_name)
})

test_that("orientation accepts valid values", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")

  # Test with all valid values
  valid_values <- 1:8
  expected_names <- c(
    "top_left", "top_right", "bottom_right", "bottom_left",
    "left_top", "right_top", "right_bottom", "left_bottom"
  )

  # Test valid values with expected transformations
  test_tag_valid_values("orientation", valid_values, expected_names)
})

test_that("orientation rejects invalid values", {
  # Create a simple test image
  img <- matrix(1:4, nrow = 2)

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")

  # Test with invalid values
  invalid_values <- list(
    9, # Out of range
    -1, # Negative
    "top_left", # Non-integer
    c(1, 2) # Multiple values
  )

  test_tag_invalid_values("orientation", invalid_values)
})
