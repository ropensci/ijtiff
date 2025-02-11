test_that("Package 2-channel example I/O works", {
  set.seed(1)
  img0 <- read_tif(test_path("testthat-figs", "2ch_ij.tif"), msg = FALSE)
  expect_equal(dim(img0)[1:2], c(15, 6))
  img1 <- read_tif(system.file("img", "Rlogo-banana-red_green.tif",
    package = "ijtiff"
  ), msg = FALSE)
  expect_equal(dim(img1)[1:2], c(155, 200))
  img2 <- read_tif(test_path("testthat-figs", "Rlogo-banana-1-2.tif"),
    msg = FALSE
  )
  expect_equal(dim(img2)[1:2], c(155, 200))
  img3 <- read_tif(
    test_path("testthat-figs", "Rlogo-banana-red_green_blue.tif"),
    msg = FALSE
  )
  expect_equal(dim(img3)[1:2], c(155, 200))
  img4 <- read_tif(test_path("testthat-figs", "Rlogo-banana-red.tif"),
    msg = FALSE
  )
  expect_equal(dim(img4)[1:2], c(155, 200))
  expect_equal(img3[, , 1, 1], img4[, , 1, 1])
  v22 <- c(2, 2, 1, 1)
  a22 <- array(seq_len(prod(v22)), dim = v22)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a22, tmptif, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v22)
  expect_equal(as.vector(in_tif), as.vector(a22), ignore_attr = FALSE)
  v2345 <- 2:5
  a2345 <- array(seq_len(prod(v2345)), dim = v2345)
  write_tif(a2345, tmptif, overwrite = TRUE, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  expect_equal(
    as.vector(read_tif(tmptif, frames = c(3, 5), msg = FALSE)),
    as.vector(a2345[, , , c(3, 5)])
  )
  v22 <- c(2, 2, 1, 1)
  a22 <- array(sample.int(prod(v22)), dim = v22)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a22, tmptif, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v22)
  expect_equal(as.vector(in_tif), as.vector(a22), ignore_attr = FALSE)
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  write_tif(a2345, tmptif, overwrite = TRUE, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  expect_equal(
    as.vector(read_tif(tmptif, frames = c(3, 5), msg = FALSE)),
    as.vector(a2345[, , , c(3, 5)])
  )
})

test_that("Package example I/O works", {
  set.seed(1)
  img0 <- read_tif(test_path("testthat-figs", "2ch_ij.tif"), msg = FALSE)
  expect_equal(dim(img0)[1:2], c(15, 6))
  img1 <- read_tif(system.file("img", "Rlogo-banana-red_green.tif",
    package = "ijtiff"
  ), msg = FALSE)
  expect_equal(dim(img1)[1:2], c(155, 200))
  img2 <- read_tif(system.file("img", "Rlogo-banana-1-2.tif",
    package = "ijtiff"
  ), msg = FALSE)
  expect_equal(dim(img2)[1:2], c(155, 200))
  img3 <- read_tif(system.file("img", "Rlogo-banana-red.tif",
    package = "ijtiff"
  ), msg = FALSE)
  expect_equal(dim(img3)[1:2], c(155, 200))
  expect_equal(dim(attr(img3, "color_map")), c(256, 3))
  expect_equal(colnames(attr(img3, "color_map")), c("red", "green", "blue"))
})

test_that("Package RGB I/O works", {
  skip_if_not_installed("EBImage")
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"),
    msg = FALSE
  )
  expect_equal(dim(img)[1:2], c(76, 100))
  expect_equal(dim(img)[3], 4)  # Image has RGBA channels, not just RGB
})

test_that("8-bit unsigned integer TIFF I/O works", {
  set.seed(2)
  v22 <- c(2, 2, 1, 1)  
  a22 <- array(seq_len(prod(v22)), dim = v22)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  {
    write_tif(a22, tmptif, bits_per_sample = 8, msg = FALSE)  
    in_tif <- read_tif(tmptif, msg = FALSE)
  }
  expect_equal(dim(in_tif), v22)
  expect_equal(as.vector(in_tif), as.vector(a22), ignore_attr = FALSE)
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  {
    write_tif(a2345, tmptif, bits_per_sample = 8, overwrite = TRUE, msg = FALSE)  
    in_tif <- read_tif(tmptif, msg = FALSE)
  }
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  expect_equal(
    attr(in_tif, "bits_per_sample"), 8
  )
})

test_that("16-bit unsigned integer TIFF I/O works", {
  set.seed(2)
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  {
    write_tif(a2345, tmptif, msg = FALSE)
    in_tif <- read_tif(tmptif, msg = FALSE)
  }
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
})

test_that("32-bit unsigned integer TIFF I/O works", {
  set.seed(2)
  v6789 <- 6:9
  a6789 <- array(sample.int(prod(v6789)), dim = v6789)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  {
    tif_write(a6789, tmptif, msg = FALSE)
    in_tif <- read_tif(tmptif, msg = FALSE)
  }
  expect_equal(dim(in_tif), v6789)
  expect_equal(as.vector(in_tif), as.vector(a6789), ignore_attr = FALSE)
})

test_that("32-bit float TIFF I/O works", {
  set.seed(2)
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345) + 0.5
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  {
    write_tif(a2345, tmptif, msg = FALSE)
    in_tif <- read_tif(tmptif, msg = FALSE)
  }
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  a2345[9] <- NaN
  expect_error(
    write_tif(a2345, tmptif, msg = FALSE),
    "'.*' already exists\\. Use `overwrite = TRUE` to overwrite it\\."
  )
  {
    write_tif(a2345, tmptif, overwrite = TRUE, msg = FALSE)
    in_tif <- read_tif(tmptif, msg = FALSE)
  }
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
})

test_that("32-bit float TIFF I/O works with negative numbers", {
  set.seed(2)
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  a2345[1] <- -1
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  {
    write_tif(a2345, tmptif, msg = FALSE)
    in_tif <- read_tif(tmptif, msg = FALSE)
  }
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  expect_equal(attr(in_tif, "sample_format"), "float")
})

test_that("reading certain frames works", {
  `%T>%` <- magrittr::`%T>%`
  path <- test_path("testthat-figs", "2ch_ij.tif")
  img <- read_tif(path, msg = FALSE)
  img12 <- read_tif(path, frames = 1:2, msg = FALSE)
  img34 <- read_tif(path, frames = 3:4, msg = FALSE)
  img25 <- read_tif(path, frames = c(2, 5), msg = FALSE)

  # Test frame subsets
  expect_equal(
    img[, , , c(1, 2)] %>%
      {
        list(
          dim(.), as.vector(.),
          attributes(img) %T>% {
            .[["dim"]] <- c(dim(img)[1:3], 2)
          }
        )
      },
    img12 %>%
      {
        list(dim(.), as.vector(.), attributes(.))
      }
  )
  expect_equal(
    img[, , , c(3, 4)] %>%
      {
        list(
          dim(.), as.vector(.),
          attributes(img) %T>% {
            .[["dim"]] <- c(dim(img)[1:3], 2)
          }
        )
      },
    img34 %>%
      {
        list(dim(.), as.vector(.), attributes(.))
      }
  )
  expect_equal(
    img[, , , c(2, 5)] %>%
      {
        list(
          dim(.), as.vector(.),
          attributes(img) %T>% {
            .[["dim"]] <- c(dim(img)[1:3], 2)
          }
        )
      },
    img25 %>%
      {
        list(dim(.), as.vector(.), attributes(.))
      }
  )

  # Test error for non-existent frame
  expect_error(
    read_tif(path, frames = 7),
    "You have requested frame number 7 but there are only 5 frames in total"
  )
})

test_that("Reading Mathieu's file works", {
  i2 <- read_tif(test_path("testthat-figs", "image2.tif"), msg = FALSE)
  expect_equal(dim(i2)[1:2], c(200, 200))
  expect_equal(dim(attr(i2, "color_map")), c(256, 3))
  expect_equal(colnames(attr(i2, "color_map")), c("red", "green", "blue"))
})

test_that("color_map attribute works", {
  skip_if_not_installed("EBImage")
  i2 <- read_tif(test_path("testthat-figs", "image2.tif"), msg = FALSE)
  expect_equal(dim(attr(i2, "color_map")), c(256, 3))
  expect_equal(colnames(attr(i2, "color_map")), c("red", "green", "blue"))
})

test_that("reading certain frames works", {
  skip_if_not_installed("EBImage")
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"),
    frames = 1,
    msg = FALSE
  )
  expect_equal(dim(img)[1:2], c(76, 100))
})

test_that("color_space parameter works", {
  # Create test image
  img_rgb <- array(1:24, dim = c(2, 2, 3, 2))  # 2x2 RGB image with 2 frames
  img_gray <- array(1:8, dim = c(2, 2, 1, 2))   # 2x2 grayscale image with 2 frames
  
  # Test RGB color space
  tmp_rgb <- tempfile(fileext = ".tif")
  write_tif(img_rgb, tmp_rgb, color_space = "rgb", msg = FALSE)
  tags_rgb <- read_tags(tmp_rgb)
  expect_equal(tags_rgb$frame1$photometric, 2)  # RGB = 2
  
  # Test min-is-black color space
  tmp_gray <- tempfile(fileext = ".tif")
  write_tif(img_gray, tmp_gray, color_space = "min-is-black", msg = FALSE)
  tags_gray <- read_tags(tmp_gray)
  expect_equal(tags_gray$frame1$photometric, 1)  # min-is-black = 1
  
  # Test default color space
  tmp_default <- tempfile(fileext = ".tif")
  write_tif(img_gray, tmp_default, msg = FALSE)
  tags_default <- read_tags(tmp_default)
  expect_equal(tags_default$frame1$photometric, 1)  # default should be min-is-black
  
  # Test invalid color space
  expect_error(write_tif(img_gray, tempfile(), color_space = "invalid"),
              "Must be element of set \\{'min-is-black','rgb'\\}")
})
