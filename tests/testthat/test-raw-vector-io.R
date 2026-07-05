test_that("read_tif reads from an in-memory raw vector identically to a file", {
  p <- system.file("img", "Rlogo.tif", package = "ijtiff")
  from_file <- read_tif(p, msg = FALSE)
  bytes <- readBin(p, "raw", n = file.info(p)$size)
  from_raw <- read_tif(bytes, msg = FALSE)
  expect_identical(as.array(from_raw), as.array(from_file))
  expect_identical(dim(from_raw), dim(from_file))
})

test_that("write_tif(img, NULL) returns bytes that read back identically", {
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"), msg = FALSE)
  bytes <- write_tif(img, NULL, msg = FALSE)
  expect_type(bytes, "raw")
  expect_gt(length(bytes), 100L)
  back <- read_tif(bytes, msg = FALSE)
  # Compare pixels + shape, not attributes: the written file gains a Software
  # tag and (pre-Task 7) a MINISBLACK photometric, so attributes legitimately
  # differ from the source. (testthat 3e's expect_equal compares attributes.)
  expect_equal(as.vector(back), as.vector(img))
  expect_identical(dim(back), dim(img))
})

test_that("a write error after the TIFF handle is open leaves the session healthy", {
  # write_tif_C opens its TIFF handle then loops over the image list, and an
  # in-loop Rf_error longjmps past the manual TIFFClose. Without cleanup that
  # leaks the handle and (for the in-memory job) the malloc'd buffer, and a
  # later gc() that closes the handle against write_tif_C's dead stack frame
  # would segfault. The external-pointer finalizer + synchronous close on the
  # error path must clean up so the session survives.
  #
  # NOTE: the public write_tif() wrapper sanitises `img`
  # (checkmate::assert_array + enlist_img) *before* any handle is opened, so it
  # cannot reach this in-loop C error. We therefore drive the C entry point
  # directly (the same idiom write_tif() itself uses) with a valid first array
  # -- which opens the handle and writes a directory -- followed by a bad
  # element that triggers the in-loop `Rf_error`.
  valid <- array(as.double(1:4), dim = c(2, 2, 1))
  bad_list <- list(valid, "not an image")

  # file-output path
  f <- tempfile(fileext = ".tif")
  expect_error(
    .Call("write_tif_C", bad_list, f, 8L, 1L, FALSE,
          NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
          PACKAGE = "ijtiff"),
    "image must be a numeric array"
  )
  # in-memory output path (where = NULL) -> exercises the malloc'd rj.data leak
  expect_error(
    .Call("write_tif_C", bad_list, NULL, 8L, 1L, FALSE,
          NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
          PACKAGE = "ijtiff"),
    "image must be a numeric array"
  )

  # gc() must not crash on the now-cleaned-up handles; reaching the round-trip
  # below (a real allocation + write + read after two full GCs) is the proof
  # the session survived the errors.
  gc()
  gc()

  img <- array(as.double(1:12), dim = c(2, 3, 2))
  p <- tempfile(fileext = ".tif")
  write_tif(img, p, msg = FALSE)
  back <- read_tif(p, msg = FALSE)
  expect_equal(as.vector(back), as.vector(img))

  # public wrapper still rejects a list up front (R-level guard, no handle open)
  expect_error(
    write_tif(list(matrix(1:4, 2), "not an image"),
              tempfile(fileext = ".tif"), msg = FALSE)
  )
})
