test_that("as.raster works with grayscale images", {
  img <- array(seq(0, 255, length.out = 100), dim = c(10, 10, 1, 1))
  class(img) <- "ijtiff_img"
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_s3_class(raster_img, "raster")
  raster_colors <- unique(as.vector(raster_img))
  expect_true(all(grepl("^#[0-9A-F]{6}$", raster_colors, ignore.case = TRUE)))
})

test_that("as.raster works with RGB images", {
  img <- array(
    c(
      # Red channel
      seq(0, 255, length.out = 100),
      # Green channel
      seq(0, 255, length.out = 100),
      # Blue channel
      seq(0, 255, length.out = 100)
    ),
    dim = c(10, 10, 3, 1)
  )
  class(img) <- "ijtiff_img"
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_s3_class(raster_img, "raster")
  raster_colors <- unique(as.vector(raster_img))
  expect_true(all(grepl("^#[0-9A-F]{6}$", raster_colors, ignore.case = TRUE)))
})

test_that("as.raster correctly handles NA values in grayscale images", {
  img <- array(seq(0, 255, length.out = 100), dim = c(10, 10, 1, 1))
  img[3, 3, 1, 1] <- NA
  class(img) <- "ijtiff_img"
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_s3_class(raster_img, "raster")
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_match(raster_img[3, 3], "^#[A-F0-9]{6}$", ignore.case = TRUE)
})

test_that("as.raster correctly handles NA values in RGB images", {
  img <- array(
    c(
      seq(0, 255, length.out = 100),
      seq(0, 255, length.out = 100),
      seq(0, 255, length.out = 100)
    ),
    dim = c(10, 10, 3, 1)
  )
  img[3, 3, 1, 1] <- NA # Set one channel of one pixel to NA
  class(img) <- "ijtiff_img"
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_match(raster_img[3, 3], "^#[A-F0-9]{6}$", ignore.case = TRUE)
})

test_that("as.raster works with example TIFF files", {
  img_gray <- read_tif(
    system.file("img", "Rlogo-grey.tif", package = "ijtiff"),
    msg = FALSE
  )
  img_rgb <- read_tif(
    system.file("img", "Rlogo.tif", package = "ijtiff"),
    msg = FALSE
  )
  raster_gray <- as.raster(img_gray)
  raster_rgb <- as.raster(img_rgb)
  expect_s3_class(raster_gray, "raster")
  expect_s3_class(raster_rgb, "raster")
  expect_equal(dim(raster_gray)[1:2], dim(img_gray)[1:2])
  expect_equal(dim(raster_rgb)[1:2], dim(img_rgb)[1:2])
})

test_that("as.raster works with 16-bit images", {
  img <- array(seq(0, 65535, length.out = 100), dim = c(10, 10, 1, 1))
  class(img) <- "ijtiff_img"
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_s3_class(raster_img, "raster")
})

test_that("as.raster works with 32-bit images", {
  img <- array(seq(0, 4294967295 - 1, length.out = 100), dim = c(10, 10, 1, 1))
  class(img) <- "ijtiff_img"
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_s3_class(raster_img, "raster")
})

test_that("as.raster errors with all NA images", {
  img <- array(NA_real_, dim = c(10, 10, 1, 1))
  class(img) <- "ijtiff_img"
  expect_error(
    as.raster(img),
    "The `img` object you have supplied contains only NA values"
  )
})

test_that("as.raster errors with negative values", {
  img <- array(seq(-10, 245, length.out = 100), dim = c(10, 10, 1, 1))
  class(img) <- "ijtiff_img"
  expect_error(
    as.raster(img),
    "The `img` object you have supplied contains values less  than 0."
  )
})

test_that("as.raster errors with values greater than 2^32-1", {
  img <- array(seq(0, 4294967297, length.out = 100), dim = c(10, 10, 1, 1))
  class(img) <- "ijtiff_img"
  expect_error(
    as.raster(img),
    "The `img` object you have supplied contains values greater  than 2\\^32 - 1."
  )
})

test_that("as.raster handles multi-frame images by using first frame", {
  img <- array(
    c(
      seq(0, 255, length.out = 100),
      seq(255, 0, length.out = 100)
    ),
    dim = c(10, 10, 1, 2)
  )
  class(img) <- "ijtiff_img"
  raster_img <- as.raster(img)
  expect_equal(dim(raster_img), c(10, 10))
  expect_s3_class(raster_img, "raster")
  first_frame_values <- img[, , 1, 1]
  max_val <- 255 # Since we know the values range from 0 to 255
  expected_colors <- matrix("", nrow = 10, ncol = 10)
  for (y in 1:10) {
    for (x in 1:10) {
      if (is.na(first_frame_values[y, x])) {
        expected_colors[y, x] <- grDevices::gray(1)
      } else {
        expected_colors[y, x] <- grDevices::gray(
          first_frame_values[y, x] / max_val
        )
      }
    }
  }
  expected_raster <- as.raster(expected_colors)
  expect_equal(dim(raster_img), dim(expected_raster))
})
