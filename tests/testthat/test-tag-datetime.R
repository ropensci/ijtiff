test_that("DateTime tag can be written and read correctly", {
  # Create a simple test image
  img <- array(1:24, dim = c(2, 3, 4))

  # Test with a string in correct format
  datetime_str <- "2025:02:25 12:34:19"
  test_tag_write_read("datetime", datetime_str)

  # Test with a Date object
  date_obj <- as.Date("2025-02-25")
  expected_datetime <- format(as.POSIXct(date_obj), "%Y:%m:%d 00:00:00")
  test_tag_write_read("datetime", date_obj, expected_value = expected_datetime)

  # Test with a POSIXct object
  datetime_obj <- as.POSIXct("2025-02-25 12:34:19")
  expected_datetime <- format(datetime_obj, "%Y:%m:%d %H:%M:%S")
  test_tag_write_read("datetime", datetime_obj, expected_value = expected_datetime)
})

test_that("DateTime tag validation works correctly", {
  img <- array(1:24, dim = c(2, 3, 4))
  
  # Test with invalid datetime format directly, using suppressWarnings to avoid the warning
  expect_error(
    suppressWarnings(
      write_tif(img, tempfile(fileext = ".tif"), datetime = "invalid-date")
    ),
    "datetime must be convertible to a valid date-time using lubridate::as_datetime\\(\\). The final format should be 'YYYY:MM:DD HH:MM:SS'."
  )
  
  # Test with NULL (should not error)
  test_tag_write_read("datetime", NULL)
})
