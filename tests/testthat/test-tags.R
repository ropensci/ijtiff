test_that("Image tags are correctly written and read", {
  # Create a simple test image
  img <- array(1:4, dim = c(2, 2))
  test_desc <- "Test image description"
  tmp_tif <- tempfile(fileext = ".tif") %>% 
    stringr::str_replace_all(stringr::coll("\\"), "/")

  # Test case 1: Description
  write_tif(img, tmp_tif, description = test_desc, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, test_desc)
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 2: Resolution in inches (default)
  write_tif(img, tmp_tif, resolution = c(300, 300), overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 300)
  expect_equal(tags$y_resolution, 300)
  expect_equal(tags$resolution_unit, "inch")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 3: Resolution in centimeters
  write_tif(img, tmp_tif, resolution = c(72, 72), resolution_unit = "cm", 
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 72)
  expect_equal(tags$y_resolution, 72)
  expect_equal(tags$resolution_unit, "cm")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 4: Resolution with no unit
  write_tif(img, tmp_tif, resolution = c(150, 150), resolution_unit = "none", 
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 150)
  expect_equal(tags$y_resolution, 150)
  expect_equal(tags$resolution_unit, "none")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 5: Different X and Y resolutions
  write_tif(img, tmp_tif, resolution = c(300, 600), resolution_unit = "inch", 
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 300)
  expect_equal(tags$y_resolution, 600)
  expect_equal(tags$resolution_unit, "inch")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 6: Combined description and resolution
  write_tif(img, tmp_tif, 
           description = test_desc,
           resolution = c(300, 300),
           resolution_unit = "inch",
           overwrite = TRUE,
           msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, test_desc)
  expect_equal(tags$x_resolution, 300)
  expect_equal(tags$y_resolution, 300)
  expect_equal(tags$resolution_unit, "inch")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 7: NULL values (should not set tags)
  write_tif(img, tmp_tif, 
           description = NULL,
           resolution = NULL,
           resolution_unit = NULL,
           overwrite = TRUE,
           msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_null(tags$description)
  expect_null(tags$x_resolution)
  expect_null(tags$y_resolution)
  expect_null(tags$resolution_unit)
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 8: Empty string description
  write_tif(img, tmp_tif, description = "", overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, "")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 9: Special characters in description
  special_desc <- "Test with special chars: !@#$%^&*()_+-=[]{}|;:'\",.<>?/\\"
  write_tif(img, tmp_tif, description = special_desc, overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, special_desc)
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 10: Resolution in cm
  write_tif(img, tmp_tif, resolution = c(72, 72), resolution_unit = "cm",
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 72)
  expect_equal(tags$y_resolution, 72)
  expect_equal(tags$resolution_unit, "cm")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 11: No resolution units
  write_tif(img, tmp_tif, resolution = c(1, 1), resolution_unit = "none",
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 1)
  expect_equal(tags$y_resolution, 1)
  expect_equal(tags$resolution_unit, "none")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))
})

test_that("Image tags are correctly written and read", {
  # Create a simple test image
  img <- array(1:4, dim = c(2, 2))
  test_desc <- "Test image description"
  tmp_tif <- tempfile(fileext = ".tif") %>% 
    stringr::str_replace_all(stringr::coll("\\"), "/")

  # Test case 1: Description
  write_tif(img, tmp_tif, description = test_desc, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, test_desc)
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 2: Resolution in inches (default)
  write_tif(img, tmp_tif, resolution = c(300, 300), overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 300)
  expect_equal(tags$y_resolution, 300)
  expect_equal(tags$resolution_unit, "inch")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 3: Resolution in centimeters
  write_tif(img, tmp_tif, resolution = c(72, 72), resolution_unit = "cm", 
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 72)
  expect_equal(tags$y_resolution, 72)
  expect_equal(tags$resolution_unit, "cm")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 4: Resolution with no unit
  write_tif(img, tmp_tif, resolution = c(150, 150), resolution_unit = "none", 
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 150)
  expect_equal(tags$y_resolution, 150)
  expect_equal(tags$resolution_unit, "none")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 5: Different X and Y resolutions
  write_tif(img, tmp_tif, resolution = c(300, 600), resolution_unit = "inch", 
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 300)
  expect_equal(tags$y_resolution, 600)
  expect_equal(tags$resolution_unit, "inch")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 6: Combined description and resolution
  write_tif(img, tmp_tif, 
           description = test_desc,
           resolution = c(300, 300),
           resolution_unit = "inch",
           overwrite = TRUE,
           msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, test_desc)
  expect_equal(tags$x_resolution, 300)
  expect_equal(tags$y_resolution, 300)
  expect_equal(tags$resolution_unit, "inch")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 7: NULL values (should not set tags)
  write_tif(img, tmp_tif, 
           description = NULL,
           resolution = NULL,
           resolution_unit = NULL,
           overwrite = TRUE,
           msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_null(tags$description)
  expect_null(tags$x_resolution)
  expect_null(tags$y_resolution)
  expect_null(tags$resolution_unit)
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 8: Empty string description
  write_tif(img, tmp_tif, description = "", overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, "")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 9: Special characters in description
  special_desc <- "Test with special chars: !@#$%^&*()_+-=[]{}|;:'\",.<>?/\\"
  write_tif(img, tmp_tif, description = special_desc, overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$description, special_desc)
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 10: Resolution in cm
  write_tif(img, tmp_tif, resolution = c(72, 72), resolution_unit = "cm",
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 72)
  expect_equal(tags$y_resolution, 72)
  expect_equal(tags$resolution_unit, "cm")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))

  # Test case 11: No resolution units
  write_tif(img, tmp_tif, resolution = c(1, 1), resolution_unit = "none",
           overwrite = TRUE, msg = FALSE)
  read_img <- read_tif(tmp_tif, msg = FALSE)
  tags <- read_tags(tmp_tif)$frame1
  expect_equal(tags$x_resolution, 1)
  expect_equal(tags$y_resolution, 1)
  expect_equal(tags$resolution_unit, "none")
  expect_equal(dim(read_img)[1:2], dim(img))
  expect_equal(as.vector(read_img), as.vector(img))
})

test_that("TIFFErrorHandler_ works", {
  tmptxt <- tempfile(fileext = ".txt") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  writeLines(c("a", "b"), tmptxt)
  expect_error(suppressWarnings(tif_read(tmptxt)), "Cannot read TIFF header")
})

test_that("write_tif() errors correctly", {
  aaaa <- array(0, dim = rep(4, 4))
  expect_error(
    tif_write(aaaa, "path/", msg = FALSE),
    "path.+cannot end with.+/"
  )
  expect_snapshot_error(
    write_tif(aaaa, "a", bits_per_sample = "abc", msg = FALSE)
  )
  expect_snapshot_error(write_tif(aaaa, "a", bits_per_sample = 12, msg = FALSE))
  aaaa[1] <- -2 * .Call("float_max_C", PACKAGE = "ijtiff")
  expect_snapshot_error(write_tif(aaaa, "a", msg = FALSE))
  aaaa[1] <- -1
  aaaa[2] <- 2 * .Call("float_max_C", PACKAGE = "ijtiff")
  expect_snapshot_error(write_tif(aaaa, "a", msg = FALSE))
  aaaa[2] <- 1
  aaaa[1] <- 0.5
  expect_snapshot_error(write_tif(aaaa, "a", bits_per_sample = 16, msg = FALSE))
  aaaa[1] <- 2^33
  expect_snapshot_error(write_tif(aaaa, "a", bits_per_sample = 16, msg = FALSE))
  aaaa[1] <- 2^20
  expect_snapshot_error(write_tif(aaaa, "a", bits_per_sample = 16, msg = FALSE))
  expect_snapshot_error(
    suppressWarnings(read_tif(test_path("testthat-figs", "bad_ij1.tif")))
  )
  expect_snapshot_error(
    suppressWarnings(read_tif(test_path("testthat-figs", "bad_ij2.tif")))
  )
})
