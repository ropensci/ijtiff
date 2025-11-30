test_that("all supported tags survive write-read roundtrip", {
  # Create test image
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Define all supported tags with test values
  all_tags <- list(
    xresolution = 300.0,
    yresolution = 300.0,
    resolutionunit = 2L,
    orientation = 1L,
    xposition = 0.5,
    yposition = 0.5,
    copyright = "(c) 2024 Test Author",
    artist = "Test Artist",
    documentname = "Test Document",
    datetime = "2024:01:15 12:30:45",
    imagedescription = "This is a test image with all tags"
  )

  # Write image with all tags
  write_tif(img, temp_file, msg = FALSE, tags_to_write = all_tags)

  # Read tags back
  tags <- read_tags(temp_file)[[1]]

  # Verify each tag (map R arg names to TIFF tag names)
  tag_name_map <- list(
    xresolution = "XResolution",
    yresolution = "YResolution",
    resolutionunit = "ResolutionUnit",
    orientation = "Orientation",
    xposition = "XPosition",
    yposition = "YPosition",
    copyright = "Copyright",
    artist = "Artist",
    documentname = "DocumentName",
    datetime = "DateTime",
    imagedescription = "ImageDescription"
  )

  for (tag_name in names(all_tags)) {
    tiff_name <- tag_name_map[[tag_name]]
    # Some tags are converted to human-readable format by read_tags
    if (tag_name == "orientation") {
      expect_equal(tags[[tiff_name]], "top_left",
        info = paste("Tag", tag_name, "failed roundtrip"))
    } else if (tag_name == "resolutionunit") {
      expect_equal(tags[[tiff_name]], "inch",
        info = paste("Tag", tag_name, "failed roundtrip"))
    } else {
      expect_equal(tags[[tiff_name]], all_tags[[tag_name]],
        info = paste("Tag", tag_name, "failed roundtrip"))
    }
  }
})

test_that("tag names are normalized correctly", {
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Test various naming formats
  write_tif(img, temp_file, msg = FALSE, tags_to_write = list(
    "X_Resolution" = 300,
    "y-resolution" = 300,
    "RESOLUTIONUNIT" = 2,
    "Image-Description" = "test"
  ))

  tags <- read_tags(temp_file)[[1]]
  expect_equal(tags$XResolution, 300)
  expect_equal(tags$YResolution, 300)
  expect_equal(tags$ResolutionUnit, "inch")  # read_tags converts to string
  expect_equal(tags$ImageDescription, "test")
})

test_that("invalid tag names are rejected", {
  img <- ijtiff::ijtiff_img(array(1:100, dim = c(10, 10, 1, 1)))
  temp_file <- tempfile(fileext = ".tif")

  expect_error(
    write_tif(img, temp_file, msg = FALSE, tags_to_write = list(
      invalid_tag = "value"
    )),
    "Invalid tag names"
  )

  expect_error(
    write_tif(img, temp_file, msg = FALSE, tags_to_write = list(
      xresolution = 300,
      unknown = "value"
    )),
    "Invalid tag names"
  )
})
