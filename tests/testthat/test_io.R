test_that("Package 2-channel example I/O works", {
  set.seed(1)
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
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
  write_tif(a2345, "temp")
  in_tif <- read_tif("temp.tif")
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
  suppressWarnings(file.remove(dir()))
})

test_that("Package RGB I/O works", {
  set.seed(1)
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("Package RGB I/O")
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
  expect_equal(dim(img), c(76, 100, 4, 1))
  suppressWarnings(file.remove(dir()))
})

test_that("8-bit unsigned integer TIFF I/O works", {
  set.seed(2)
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("8-bit unsigned integer TIFF I/O")
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  write_tif(a2345, "temp")
  in_tif <- read_tif("temp.tif")
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
  suppressWarnings(file.remove(dir()))
})

test_that("16-bit unsigned integer TIFF I/O works", {
  set.seed(3)
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("16-bit unsigned integer TIFF I/O")
  v6789 <- 6:9
  a6789 <- array(sample.int(prod(v6789)), dim = v6789)
  dir.create("tempwithintemp")
  write_tif(a6789, "tempwithintemp/temp.tif")
  in_tif <- read_tif("tempwithintemp/temp.tif")
  expect_equal(dim(in_tif), v6789)
  expect_equal(as.vector(in_tif), as.vector(a6789), check.attributes = FALSE)
  suppressWarnings(file.remove(dir()))
})

test_that("32-bit unsigned integer TIFF I/O works", {
  set.seed(4)
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("32-bit unsigned integer TIFF I/O")
  v1m <- c(20, 50, 10, 100)
  a1m <- array(sample.int(2 ^ 32 - 1, prod(v1m)), dim = v1m)
  write_tif(a1m, "temp")
  in_tif <- read_tif("temp.tif")
  expect_equal(dim(in_tif), v1m)
  expect_equal(as.vector(in_tif), as.vector(a1m), check.attributes = FALSE)
  suppressWarnings(file.remove(dir()))
})

test_that("Float (real-numbered) TIFF I/O works", {
  set.seed(5)
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("8-bit unsigned integer TIFF I/O")
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345) + 0.5
  write_tif(a2345, "temp.tiff")
  in_tif <- read_tif("temp.tif")
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
  a2345[9] <- NA
  write_tif(a2345, "temp")
  in_tif <- read_tif("temp.tif")
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
  suppressWarnings(file.remove(dir()))
})

test_that("Negative-numbered TIFF I/O works", {
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("Negative-numbered TIFF I/O")
  v2345 <- 2:5
  a2345 <- array(sample.int(prod(v2345)), dim = v2345)
  a2345[1] <- -1
  write_tif(a2345, "temp.tiff")
  in_tif <- read_tif("temp.tif")
  expect_equal(dim(in_tif), v2345)
  expect_equal(as.vector(in_tif), as.vector(a2345), check.attributes = FALSE)
  expect_equal(attr(in_tif, "sample_format"), "float")
  suppressWarnings(file.remove(dir()))
})

test_that("List returning works", {
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("List returning")
  img1 <- matrix(0.5, nrow = 2, ncol = 2)
  img2 <- matrix(0.7, nrow = 3, ncol = 7)
  weird_list_img <- list(img1, img2)
  expect_equal(tiff::writeTIFF(weird_list_img, "weird.tif"), 2)
  expect_error(read_tif("weird.tif"), "tried to return a list")
  expect_warning(read_tif("weird.tif", list_safety = "warn"),
                 "returning a list")
  in_weird <- read_tif("weird.tif", list_safety = "n")
  expect_equal(in_weird,
               purrr::map(weird_list_img, ~ floor(. * (2 ^ 8 - 1))),
               check.attributes = FALSE)  # writing causes truncation
  suppressWarnings(file.remove(dir()))
})

test_that("TIFFErrorHandler_ works", {
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  context("TIFFErrorHandler_")
  writeLines(c("a", "b"), "t.txt")
  expect_error(suppressWarnings(read_tif("t.txt")), "Cannot read TIFF header")
  suppressWarnings(file.remove(dir()))
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
  setwd(tempdir())
  mm <- matrix(1:60, nrow = 4)
  dim(mm) %<>% c(1, 1)
  write_txt_img(mm, "mm")
  expect_equal(dir(pattern = "^mm.*txt$"), "mm.txt")
  expect_equal(as.vector(mm),
               unlist(lapply(dir(pattern = "^mm.*txt$"), read_txt_img)))
  suppressWarnings(file.remove(dir()))
  mmm <- abind::abind(mm, mm, along = 3)
  write_txt_img(mmm, "mmm")
  expect_equal(dir(pattern = "^mm.*txt$"), c("mmm_ch1.txt", "mmm_ch2.txt"))
  expect_equal(as.vector(mmm),
               unlist(lapply(dir(pattern = "^mm.*txt$"), read_txt_img)))
  suppressWarnings(file.remove(dir()))
  mmmm <- abind::abind(mmm, mmm, along = 4)
  write_txt_img(mmmm, "mmmm")
  expect_equal(dir(pattern = "^mm.*txt$"), c("mmmm_ch1_frame1.txt",
                                             "mmmm_ch1_frame2.txt",
                                             "mmmm_ch2_frame1.txt",
                                             "mmmm_ch2_frame2.txt"))
  expect_equal(as.vector(mmmm),
               unlist(lapply(dir(pattern = "^mm.*txt$"), read_txt_img)))
  mmmmm <- array(1, dim = rep(5, 5))
  expect_error(write_txt_img(mmmmm, "abc"), "dimension")

  suppressWarnings(file.remove(list.files()))
})
