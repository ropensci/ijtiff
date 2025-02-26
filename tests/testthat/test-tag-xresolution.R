test_that("xresolution can be written and read back", {
  # Test with a specific xresolution value
  xres_value <- 300

  # Write and read the image
  tags <- test_tag_write_read("xresolution", xres_value)

  # Check if the tag has the correct value
  expect_equal(tags[[1]]$XResolution, xres_value)
})

test_that("xresolution accepts valid values", {
  # Test with different valid values
  valid_values <- c(72, 96, 150, 300, 600, 1200)

  test_tag_valid_values("xresolution", valid_values)
})

test_that("xresolution rejects invalid values", {
  # Test with invalid values
  invalid_values <- list(
    -100, # Negative
    "300dpi", # Non-numeric
    c(300, 600) # Multiple values
  )

  test_tag_invalid_values("xresolution", invalid_values)
})
