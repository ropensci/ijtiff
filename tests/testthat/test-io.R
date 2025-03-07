test_that("Package 2-channel example I/O works", {
  set.seed(1)
  img0 <- read_tif(test_path("testthat-figs", "2ch_ij.tif"), msg = FALSE)
  expect_equal(dim(img0), c(15, 6, 2, 5))
  img1 <- read_tif(system.file("img", "Rlogo-banana-red_green.tif",
    package = "ijtiff"
  ), msg = FALSE)
  expect_equal(dim(img1), c(155, 200, 2, 2))
  img2 <- read_tif(test_path("testthat-figs", "Rlogo-banana-1-2.tif"),
    msg = FALSE
  )
  expect_equal(dim(img2), c(155, 200, 3, 2))
  img3 <- read_tif(
    test_path("testthat-figs", "Rlogo-banana-red_green_blue.tif"),
    msg = FALSE
  )
  expect_equal(dim(img3), c(155, 200, 3, 2))
  img4 <- read_tif(test_path("testthat-figs", "Rlogo-banana-red.tif"),
    msg = FALSE
  )
  expect_equal(dim(img4), c(155, 200, 1, 2))
  expect_in( # allow for img4 going 16-bit during editing :-(
    list(img3[, , 1, 1]),
    list(img4[, , 1, 1], img4[, , 1, 1] / 2^8)
  )
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
  # Capture the actual message
  suppressMessages(
    expect_message(
      write_tif(a2345, tmptif, overwrite = TRUE),
      paste(
        "Writing.+.tif: an 8-bit, 2x3 pixel image of.+unsigned integer",
        "type with 4 channels and 5 frames"
      )
    )
  )
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
  # Test writing with message
  suppressMessages(
    expect_message(
      write_tif(a2345, tmptif, overwrite = TRUE),
      paste(
        "Writing.+.tif: an 8-bit, 2x3 pixel image of.+unsigned integer type",
        "with 4 channels and 5 frames"
      )
    )
  )
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
})

test_that("Package RGB I/O works", {
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"),
    msg = FALSE
  )
  expect_equal(dim(img), c(76, 100, 4, 1))
  # Test that photometric interpretation is correctly mapped from JSON
  expect_equal(attr(img, "PhotometricInterpretation"), "RGB")
  # Test that sample format is correctly mapped from JSON
  expect_equal(attr(img, "SampleFormat"), "unsigned integer data")
})

test_that("8-bit unsigned integer TIFF I/O works", {
  set.seed(2)
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a2345, tmptif, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  expect_equal(attr(in_tif, "SampleFormat"), "unsigned integer data")
})

test_that("16-bit unsigned integer TIFF I/O works", {
  set.seed(3)
  v6789 <- 6:9
  a6789 <- array(sample.int(prod(v6789)), dim = v6789)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  tif_write(a6789, tmptif, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v6789)
  expect_equal(as.vector(in_tif), as.vector(a6789), ignore_attr = FALSE)
})

test_that("32-bit unsigned integer TIFF I/O works", {
  set.seed(4)
  v1m <- c(20, 50, 10, 100)
  a1m <- array(sample.int(2^32 - 1, prod(v1m)), dim = v1m)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a1m, tmptif, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v1m)
  expect_equal(as.vector(in_tif), as.vector(a1m), ignore_attr = FALSE)
})

test_that("Float (real-numbered) TIFF I/O works", {
  set.seed(5)
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345) + 0.5
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a2345, paste0(tmptif, "f"), msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  a2345[9] <- NaN
  expect_error(
    write_tif(a2345, tmptif, msg = FALSE),
    "To enable overwriting, use `overwrite = TRUE`"
  )
  write_tif(a2345, tmptif, overwrite = TRUE, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  # Test that sample format is correctly mapped from JSON
  expect_equal(attr(in_tif, "SampleFormat"), "IEEE floating point data [IEEE]")
})

test_that("Negative-numbered TIFF I/O works", {
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  a2345[1] <- -1
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a2345, tmptif, msg = FALSE)
  in_tif <- read_tif(tmptif, msg = FALSE)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), ignore_attr = FALSE)
  expect_equal(attr(in_tif, "SampleFormat"), "IEEE floating point data [IEEE]")
})

test_that("List returning works", {
  skip_if_not_installed("tiff")
  img1 <- matrix(0.5, nrow = 2, ncol = 2)
  img2 <- matrix(0.7, nrow = 3, ncol = 7)
  weird_list_img <- list(img1, img2)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  expect_equal(tiff::writeTIFF(weird_list_img, tmptif), 2)
  expect_error(read_tif(tmptif, msg = FALSE), "tried to return a list")
  expect_warning(
    read_tif(tmptif, list_safety = "warn", msg = FALSE),
    "returning a list"
  )
  suppressMessages(
    expect_message(
      in_weird <- read_tif(tmptif, list_safety = "n"),
      "Reading a list of images with differing dimensions"
    )
  )
  purrr::map2(
    in_weird,
    purrr::map(weird_list_img, ~ floor(. * (2^8 - 1))),
    expect_equal,
    ignore_attr = TRUE
  )
})

test_that("text-image-io works", {
  mm <- matrix(1:60, nrow = 4)
  dim(mm) <- c(dim(mm), 1, 1)
  tmpfl <- tempfile() %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  txt_img_write(mm, tmpfl, msg = FALSE)
  tmpfl_txt <- strex::str_give_ext(tmpfl, "txt")
  expect_true(file.exists(tmpfl_txt))
  expect_equal(as.vector(mm),
    as.vector(txt_img_read(tmpfl_txt, msg = FALSE)),
    ignore_attr = FALSE
  )
  suppressMessages(
    expect_message(
      txt_img_read(tmpfl_txt, msg = TRUE),
      "Reading 4x15 pixel text image"
    )
  )
  file.remove(tmpfl_txt)
  skip_if_not_installed("abind")
  mmm <- abind::abind(mm, mm, along = 3)
  suppressMessages(
    expect_message(
      write_txt_img(mmm, tmpfl, rds = TRUE),
      "_ch1.txt and .+_ch2.txt"
    )
  )
  expect_equal(readRDS(strex::str_give_ext(tmpfl, "rds")), ijtiff_img(mmm))
  tmpfl_txts <- paste0(tmpfl, "_ch", 1:2, ".txt")
  expect_equal(
    dir(strex::str_before_last(tmpfl, "/"),
      pattern = paste0(
        strex::str_after_last(tmpfl, "/"),
        ".+txt$"
      )
    ),
    strex::str_after_last(tmpfl_txts, "/"),
    ignore_attr = FALSE
  )
  expect_equal(unlist(lapply(tmpfl_txts, read_txt_img, msg = FALSE)),
    as.vector(mmm),
    ignore_attr = FALSE
  )
  file.remove(tmpfl_txts)
  mmmm <- abind::abind(mmm, mmm, along = 4)
  write_txt_img(mmmm, tmpfl, msg = FALSE)
  tmpfl_txts <- paste0(tmpfl, c(
    "_ch1_frame1",
    "_ch1_frame2",
    "_ch2_frame1",
    "_ch2_frame2"
  ), ".txt")
  expect_equal(
    dir(strex::str_before_last(tmpfl, "/"),
      pattern = paste0(
        strex::str_after_last(tmpfl, "/"),
        ".+txt$"
      )
    ),
    strex::str_after_last(tmpfl_txts, "/"),
    ignore_attr = FALSE
  )
  expect_equal(unlist(lapply(tmpfl_txts, read_txt_img, msg = FALSE)),
    as.vector(mmmm),
    ignore_attr = FALSE
  )
  bad_txt_img <- dplyr::tribble(
    ~col1, ~col2,
    1, "5",
    8, "y"
  )
  tmpfl <- tempfile(fileext = ".txt")
  readr::write_tsv(bad_txt_img, tmpfl, col_names = FALSE)
  expect_error(
    read_txt_img(tmpfl),
    paste0(
      "`path` must be the path to a text file which is.+",
      "an array of.+numbers.",
      "* Column 2 of the text file at your `path`.+",
      "is not numeric."
    )
  )
})

test_that("reading certain frames works", {
  `%T>%` <- magrittr::`%T>%`
  path <- test_path("testthat-figs", "2ch_ij.tif")
  img <- read_tif(path, "A", msg = FALSE)
  img12 <- read_tif(path, frames = 1:2, msg = FALSE)
  img25 <- read_tif(path, frames = c(2, 5), msg = FALSE)
  img12_alt <- img[, , , c(1, 2)]
  expect_equal(dim(img12), dim(img12_alt))
  expect_equal(as.vector(img12), as.vector(img12_alt))
  img12_attrs <- purrr::list_modify(
    attributes(img12),
    tags_by_frame = purrr::zap(), dim = purrr::zap()
  )
  img_attrs <- purrr::list_modify(
    attributes(img),
    tags_by_frame = purrr::zap(), dim = purrr::zap()
  )
  expect_equal(img12_attrs, img_attrs)
  img25_alt <- img[, , , c(2, 5)]
  expect_equal(dim(img25), dim(img25_alt))
  expect_equal(as.vector(img25), as.vector(img25_alt))
  img25_attrs <- purrr::list_modify(
    attributes(img25),
    tags_by_frame = purrr::zap(), dim = purrr::zap()
  )
  expect_equal(img25_attrs, img_attrs)
  expect_error(
    read_tif(path, frames = 7, msg = FALSE),
    "requested.+7.+only.+5"
  )
})

test_that("Reading Mathieu's file works", {
  i2 <- read_tif(test_path("testthat-figs", "image2.tif"), msg = FALSE)
  expect_equal(dim(i2), c(200, 200, 6, 1))
  expect_equal(dim(attr(i2, "ColorMap")), c(256, 3))
  expect_equal(colnames(attr(i2, "ColorMap")), c("red", "green", "blue"))
})
