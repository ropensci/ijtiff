test_that("DateTime tag can be written and read correctly", {
  # Create a simple test image
  img <- array(1:24, dim = c(2, 3, 4))
  
  # Test with a string in correct format
  path1 <- tempfile(fileext = ".tif")
  datetime_str <- "2025:02:25 12:34:19"
  write_tif(img, path1, datetime = datetime_str, msg = FALSE)
  img1 <- read_tif(path1, msg = FALSE)
  expect_equal(attr(img1, "DateTime"), datetime_str)
  file.remove(path1)
  
  # Test with a Date object
  path2 <- tempfile(fileext = ".tif")
  date_obj <- as.Date("2025-02-25")
  expected_datetime <- format(as.POSIXct(date_obj), "%Y:%m:%d 00:00:00")
  write_tif(img, path2, datetime = date_obj, msg = FALSE)
  img2 <- read_tif(path2, msg = FALSE)
  expect_equal(attr(img2, "DateTime"), expected_datetime)
  file.remove(path2)
  
  # Test with a POSIXct object
  path3 <- tempfile(fileext = ".tif")
  datetime_obj <- as.POSIXct("2025-02-25 12:34:19")
  expected_datetime <- format(datetime_obj, "%Y:%m:%d %H:%M:%S")
  write_tif(img, path3, datetime = datetime_obj, msg = FALSE)
  img3 <- read_tif(path3, msg = FALSE)
  expect_equal(attr(img3, "DateTime"), expected_datetime)
  file.remove(path3)
})

test_that("DateTime tag validation works correctly", {
  img <- array(1:24, dim = c(2, 3, 4))
  
  # Test with invalid datetime format
  expect_error(
    suppressWarnings(
      write_tif(
        img, 
        tempfile(fileext = ".tif"), 
        datetime = "invalid-date", 
        msg = FALSE
      )
    ), 
    "datetime must be convertible to a valid date-time"
  )
  
  # Test with NULL (should not error)
  path <- tempfile(fileext = ".tif")
  expect_error(write_tif(img, path, datetime = NULL, msg = FALSE), NA)
  file.remove(path)
})
