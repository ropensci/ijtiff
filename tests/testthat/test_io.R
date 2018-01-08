test_that("Package 2-channel example I/O works", {
  set.seed(1)
  context("Package 2-channel example I/O")
  img <- read_tif(system.file("img", "2ch_ij.tif", package = "ijtiff"))
  expect_equal(dim(img), c(15, 6, 2, 5))
  img <- read_tif(system.file("img", "Rlogo-banana-red_green.tif",
                              package = "ijtiff"))
  expect_equal(dim(img), c(155, 200, 2, 3))
  img <- read_tif(system.file("img", "Rlogo-banana-1-2.tif",
                              package = "ijtiff"))
  expect_equal(dim(img), c(155, 200, 3, 2))
  img <- read_tif(system.file("img", "Rlogo-banana-red_green_blue.tif",
                              package = "ijtiff"))
  expect_equal(dim(img), c(155, 200, 3, 2))
  img <- read_tif(system.file("img", "Rlogo-banana-red.tif",
                              package = "ijtiff"))
  expect_equal(dim(img), c(155, 200, 1, 2))
  context("8-bit unsigned integer TIFF I/O")
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a2345, tmptif)
  in_tif <- read_tif(tmptif)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
})

test_that("Package RGB I/O works", {
  context("Package RGB I/O")
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
  expect_equal(dim(img), c(76, 100, 4, 1))
})

test_that("8-bit unsigned integer TIFF I/O works", {
  set.seed(2)
  context("8-bit unsigned integer TIFF I/O")
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a2345, tmptif)
  in_tif <- read_tif(tmptif)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
})

test_that("16-bit unsigned integer TIFF I/O works", {
  set.seed(3)
  context("16-bit unsigned integer TIFF I/O")
  v6789 <- 6:9
  a6789 <- array(sample.int(prod(v6789)), dim = v6789)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a6789, tmptif)
  in_tif <- read_tif(tmptif)
  expect_equal(dim(in_tif), v6789)
  expect_equal(as.vector(in_tif), as.vector(a6789), check.attributes = FALSE)
})

test_that("32-bit unsigned integer TIFF I/O works", {
  set.seed(4)
  context("32-bit unsigned integer TIFF I/O")
  v1m <- c(20, 50, 10, 100)
  a1m <- array(sample.int(2 ^ 32 - 1, prod(v1m)), dim = v1m)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a1m, tmptif)
  in_tif <- read_tif(tmptif)
  expect_equal(dim(in_tif), v1m)
  expect_equal(as.vector(in_tif), as.vector(a1m), check.attributes = FALSE)
})

test_that("Float (real-numbered) TIFF I/O works", {
  set.seed(5)
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("8-bit unsigned integer TIFF I/O")
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345) + 0.5
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a2345, paste0(tmptif, "f"))
  in_tif <- read_tif(tmptif)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
  a2345[9] <- NA
  write_tif(a2345, tmptif)
  in_tif <- read_tif(tmptif)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
})

test_that("Negative-numbered TIFF I/O works", {
  context("Negative-numbered TIFF I/O")
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  a2345[1] <- -1
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_tif(a2345, tmptif)
  in_tif <- read_tif(tmptif)
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
  expect_equal(attr(in_tif, "sample_format"), "float")
})

test_that("List returning works", {
  context("List returning")
  img1 <- matrix(0.5, nrow = 2, ncol = 2)
  img2 <- matrix(0.7, nrow = 3, ncol = 7)
  weird_list_img <- list(img1, img2)
  tmptif <- tempfile(fileext = ".tif") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  expect_equal(tiff::writeTIFF(weird_list_img, tmptif), 2)
  expect_error(read_tif(tmptif), "tried to return a list")
  expect_warning(read_tif(tmptif, list_safety = "warn"),
                 "returning a list")
  in_weird <- read_tif(tmptif, list_safety = "n")
  expect_equal(in_weird,
               purrr::map(weird_list_img, ~ floor(. * (2 ^ 8 - 1))),
               check.attributes = FALSE)  # writing causes truncation
})

test_that("TIFFErrorHandler_ works", {
  context("TIFFErrorHandler_")
  tmptxt <- tempfile(fileext = ".txt") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  writeLines(c("a", "b"), tmptxt)
  expect_error(suppressWarnings(read_tif(tmptxt)), "Cannot read TIFF header")
})

test_that("write_tif() errors correctly", {
  context("write_tif() exceptions")
  aaaa <- array(0, dim = rep(4, 4))
  expect_error(write_tif(aaaa, "a", bits_per_sample = "abc"),
               "If .* is a string")
  expect_error(write_tif(aaaa, "a", bits_per_sample = 12),
               "one of 8, 16 or 32")
  aaaa[1] <- - 2 * float_max()
  expect_error(write_tif(aaaa, "a"), "lowest allowable negative")
  aaaa[1] <- -1
  aaaa[2] <- 2 * float_max()
  expect_error(write_tif(aaaa, "a"),
               "If .* has negative .* maximum allowed positive")
  aaaa[2] <- 1
  aaaa[1] <- 0.5
  expect_error(write_tif(aaaa, "a", bits_per_sample = 16),
               "needs .* floating point .* necessary to have 32 bits")
  aaaa[1] <- 2 ^ 33
  expect_error(write_tif(aaaa, "a", bits_per_sample = 16),
               "maximum .* greater than 2 \\^ 32 - 1")
  aaaa[1] <-  2 ^ 20
  expect_error(write_tif(aaaa, "a", bits_per_sample = 16),
               "TIFF file needs to be at least .*-bit")
  expect_error(read_tif(system.file("img", "bad_ij1.tif", package = "ijtiff")),
               "The ImageJ.* image .* has 13 images of 5 slices of 2 channels")
  expect_error(read_tif(system.file("img", "bad_ij2.tif", package = "ijtiff")),
               "The ImageJ.* image .* has 13 images of 5 slices of 2 channels")
  expect_error(read_tif(system.file("img", "bad_ij3.tif", package = "ijtiff")),
               "The ImageJ.* image .* has 8 frames AND 5 slices")
})

context("Text I/O")
test_that("text-image-io works", {
  mm <- matrix(1:60, nrow = 4)
  dim(mm) %<>% c(1, 1)
  tmpfl <- tempfile() %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  write_txt_img(mm, tmpfl)
  tmpfl_txt <- filesstrings::give_ext(tmpfl, "txt")
  expect_true(file.exists(tmpfl_txt))
  expect_equal(as.vector(mm), unlist(read_txt_img(tmpfl_txt)),
               check.attributes = FALSE)
  file.remove(tmpfl_txt)
  mmm <- abind::abind(mm, mm, along = 3)
  write_txt_img(mmm, tmpfl)
  tmpfl_txts <- paste0(tmpfl, "_ch", 1:2, ".txt")
  expect_equal(dir(filesstrings::str_before_last(tmpfl, "/"),
                   pattern = filesstrings::str_after_last(tmpfl, "/")),
               filesstrings::str_after_last(tmpfl_txts, "/"),
               check.names = FALSE, check.attributes = FALSE)
  expect_equal(unlist(lapply(tmpfl_txts, read_txt_img)), as.vector(mmm),
               check.attributes = FALSE)
  file.remove(tmpfl_txts)
  mmmm <- abind::abind(mmm, mmm, along = 4)
  write_txt_img(mmmm, tmpfl)
  tmpfl_txts <- paste0(tmpfl, c("_ch1_frame1",
                                "_ch1_frame2",
                                "_ch2_frame1",
                                "_ch2_frame2"), ".txt")
  expect_equal(dir(filesstrings::str_before_last(tmpfl, "/"),
                   pattern = filesstrings::str_after_last(tmpfl, "/")),
               filesstrings::str_after_last(tmpfl_txts, "/"),
               check.names = FALSE, check.attributes = FALSE)
  expect_equal(unlist(lapply(tmpfl_txts, read_txt_img)), as.vector(mmmm),
               check.attributes = FALSE)
  mmmmm <- array(1, dim = rep(5, 5))
  expect_error(write_txt_img(mmmmm, "abc"), "dimension")
})
