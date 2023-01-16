test_that("extract_desired_plane() works", {
  aaa <- array(0, dim = rep(3, 3))
  expect_equal(extract_desired_plane(aaa), aaa[, , 1])
  aaa[] <- 1
  aaa[[1]] <- 2
  expect_error(
    extract_desired_plane(aaa),
    paste0(
      "Cannot extract the desired plane.+",
      "There are 2 unique nonzero planes, so it is impossible.+",
      "to decipher which is the correct one to extract."
    )
  )
  aaa[, , 1] <- 1
  aaa[, , -1] <- 0
  expect_equal(extract_desired_plane(aaa), aaa[, , 1])
})

test_that("tif_tags_reference() works", {
  expect_equal(
    tif_tags_reference(),
    readr::read_csv(system.file("extdata",
      "TIFF_tags.csv",
      package = "ijtiff"
    ), col_types = readr::cols())
  )
  expect_s3_class(tif_tags_reference(), "tbl_df")
})

test_that("prep_frames() errors correctly", {
  expect_error(
    prep_frames("xyz"),
    paste0("If.+frames.+is a string.+must be.+all.+You have.+frames.+xyz")
  )
})

test_that("ebimg_check() works correctly", {
  if (rlang::is_installed("EBImage")) expect_true(ebimg_check())
  skip_if_not_installed("mockery")
  mockery::stub(ebimg_check, "rlang::is_installed", FALSE)
  expect_error(ebimg_check(), "need.+EBImage.+installed")
})

test_that("lowest_upper_bound() edge cases work correctly", {
  expect_equal(lowest_upper_bound(NA_integer_, 1:5, na_rm = FALSE), NA_real_)
  expect_equal(lowest_upper_bound(NA_integer_, 1:5, na_rm = TRUE), NA_real_)
})

test_that("prep_read() errors correctly in unusual circumstances", {
  expect_error(
    read_tif(test_path("testthat-figs", "image2.tif"), frames = 999),
    "You.+requested.+frame.+999 but.+only 6 frames"
  )
  skip_if_not_installed("mockery")
  mockery::stub(
    prep_read, "translate_ij_description",
    list(n_imgs = 99, n_slices = 1, ij_n_ch = TRUE, n_ch = 6)
  )
  expect_error(
    prep_read(test_path("testthat-figs", "image2.tif"), "all", NA, FALSE),
    "6 directories.+99 images"
  )
})
