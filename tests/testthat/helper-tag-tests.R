# Helper functions for TIFF tag tests

#' Create a test image for tag testing
#'
#' @return A simple test image matrix
create_test_image <- function() {
  matrix(1:4, nrow = 2)
}

#' Get the proper tag name for accessing in tags
#'
#' @param tag_name The name of the tag as used in write_tif
#' @return The proper tag name for accessing in tags
get_proper_tag_name <- function(tag_name) {
  switch(tag_name,
    xresolution = "XResolution",
    yresolution = "YResolution",
    resolutionunit = "ResolutionUnit",
    datetime = "DateTime",
    imagedescription = "ImageDescription",
    xposition = "XPosition",
    yposition = "YPosition",
    documentname = "DocumentName",
    # Default: capitalize first letter
    paste0(toupper(substr(tag_name, 1, 1)), substr(tag_name, 2, nchar(tag_name)))
  )
}

#' Test that a tag can be written and read back
#'
#' @param tag_name The name of the tag to test
#' @param tag_value The value to set for the tag
#' @param expected_value The expected value after reading (if different from tag_value)
#' @param write_args Additional arguments to pass to write_tif
#'
#' @return The read tags for further testing if needed
test_tag_write_read <- function(tag_name, tag_value, expected_value = NULL, write_args = list()) {
  # Create a simple test image
  img <- create_test_image()

  # Create a temporary file path
  temp_file <- tempfile(fileext = ".tif")
  on.exit(if (file.exists(temp_file)) file.remove(temp_file), add = TRUE)

  # Prepare arguments for write_tif
  args <- list(img = img, path = temp_file, msg = FALSE)
  args$tags_to_write <- list()
  args$tags_to_write[[tag_name]] <- tag_value
  args <- c(args, write_args)

  # Write the image with the tag
  do.call(write_tif, args)

  # Read the image and check if tag is preserved
  tags <- read_tags(temp_file)

  # Get the proper tag name for accessing in tags
  tag_name_proper <- get_proper_tag_name(tag_name)

  # If expected_value is not provided, use tag_value
  if (is.null(expected_value)) {
    expected_value <- tag_value
  }

  # Check if the tag is present and has the correct value
  expect_equal(tags[[1]][[tag_name_proper]], expected_value)

  # Return tags for further testing if needed
  return(tags)
}

#' Test that a tag accepts multiple valid values
#'
#' @param tag_name The name of the tag to test
#' @param valid_values Vector of valid values to test
#' @param expected_values Vector of expected values after reading (if different from valid_values)
#' @param write_args Additional arguments to pass to write_tif
test_tag_valid_values <- function(tag_name, valid_values, expected_values = NULL, write_args = list()) {
  img <- create_test_image()
  temp_file <- tempfile(fileext = ".tif")
  on.exit(if (file.exists(temp_file)) file.remove(temp_file), add = TRUE)

  # If expected_values is not provided, use valid_values
  if (is.null(expected_values)) {
    expected_values <- valid_values
  } else {
    # Ensure expected_values has the same length as valid_values
    if (length(expected_values) != length(valid_values)) {
      stop("expected_values must have the same length as valid_values")
    }
  }

  # Get the proper tag name for accessing in tags
  tag_name_proper <- get_proper_tag_name(tag_name)

  for (i in seq_along(valid_values)) {
    val <- valid_values[i]
    expected_val <- expected_values[i]

    # Prepare arguments for write_tif
    args <- list(img = img, path = temp_file, overwrite = TRUE, msg = FALSE)
    args$tags_to_write <- list()
    args$tags_to_write[[tag_name]] <- val
    args <- c(args, write_args)

    # Should not error
    expect_no_error(do.call(write_tif, args))

    # Read and verify
    tags <- read_tags(temp_file)

    expect_equal(tags[[1]][[tag_name_proper]], expected_val)
  }
}

#' Test that a tag rejects invalid values
#'
#' @param tag_name The name of the tag to test
#' @param invalid_values List of invalid values to test
#' @param write_args Additional arguments to pass to write_tif
test_tag_invalid_values <- function(tag_name, invalid_values, write_args = list()) {
  img <- create_test_image()
  temp_file <- tempfile(fileext = ".tif")
  on.exit(if (file.exists(temp_file)) file.remove(temp_file), add = TRUE)

  for (val in invalid_values) {
    # Prepare arguments for write_tif
    args <- list(img = img, path = temp_file, msg = FALSE)
    args$tags_to_write <- list()
    args$tags_to_write[[tag_name]] <- val
    args <- c(args, write_args)

    # Should error
    expect_error(do.call(write_tif, args))
  }
}
