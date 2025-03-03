test_that("TIFFErrorHandler_ works", {
  tmptxt <- tempfile(fileext = ".txt") %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  writeLines(c("a", "b"), tmptxt)
  expect_error(
    suppressWarnings(tif_read(tmptxt, msg = FALSE)),
    "does not appear to be a valid TIFF file"
  )
})

test_that("write_tif() errors correctly", {
  aaaa <- array(0, dim = rep(4, 4))
  expect_error(
    tif_write(aaaa, "path/", msg = FALSE),
    "path.+cannot end with.+/"
  )
  expect_error(
    write_tif(aaaa, "a", bits_per_sample = "abc", msg = FALSE),
    "bits_per_sample.+string.+auto.+only"
  )
  expect_error(
    write_tif(aaaa, "a", bits_per_sample = 12, msg = FALSE),
    "bits_per_sample.+12"
  )
  aaaa[1] <- -2 * .Call("float_max_C", PACKAGE = "ijtiff")
  expect_error(
    write_tif(aaaa, "a", msg = FALSE),
    "lowest allowable negative value"
  )
  aaaa[1] <- -1
  aaaa[2] <- 2 * .Call("float_max_C", PACKAGE = "ijtiff")
  expect_error(
    write_tif(aaaa, "a", msg = FALSE),
    "max.+value"
  )
  aaaa[2] <- 1
  aaaa[1] <- 0.5
  expect_error(
    write_tif(aaaa, "a", bits_per_sample = 16, msg = FALSE),
    "necessary.+32 bit"
  )
  aaaa[1] <- 2^33
  expect_error(
    write_tif(aaaa, "a", bits_per_sample = 16, msg = FALSE),
    "max.+value"
  )
  aaaa[1] <- 2^20
  expect_error(
    write_tif(aaaa, "a", bits_per_sample = 16, msg = FALSE),
    "16.+max.+need.+32"
  )
  expect_error(
    suppressWarnings(
      read_tif(test_path("testthat-figs", "bad_ij1.tif"), msg = FALSE)
    ),
    "ImageJ.+13 images of 5 slices of 2 channels"
  )
  expect_error(
    suppressWarnings(
      read_tif(test_path("testthat-figs", "bad_ij2.tif"), msg = FALSE)
    ),
    "ImageJ.+8 frames AND 5 slices.+does not make sense"
  )
})
