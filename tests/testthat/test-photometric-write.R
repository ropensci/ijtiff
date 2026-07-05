test_that("explicit photometric = 'RGB' writes PHOTOMETRIC_RGB", {
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"), msg = FALSE)
  tf <- tempfile(fileext = ".tif")
  write_tif(img, tf, tags_to_write = list(photometric = "RGB"), msg = FALSE)
  expect_equal(read_tags(tf)[[1]]$PhotometricInterpretation, "RGB")
})

test_that("default photometric is MinIsBlack for a fresh (attribute-free) array", {
  img <- array(1:24, dim = c(2, 3, 4))   # no PhotometricInterpretation attribute
  tf <- tempfile(fileext = ".tif")
  write_tif(img, tf, msg = FALSE)
  expect_equal(read_tags(tf)[[1]]$PhotometricInterpretation, "BlackIsZero")
})

test_that("WhiteIsZero source round-trips to WhiteIsZero (3.3.0 behaviour change)", {
  # Before 3.3.0, photometric was not auto-extracted, so this wrote MinIsBlack.
  img <- array(as.double(1:6), dim = c(2, 3))
  attr(img, "PhotometricInterpretation") <- "WhiteIsZero"
  tf <- tempfile(fileext = ".tif")
  write_tif(img, tf, msg = FALSE)
  expect_equal(read_tags(tf)[[1]]$PhotometricInterpretation, "WhiteIsZero")
})

test_that("reading an RGB TIFF then writing round-trips the RGB photometric", {
  # Only meaningful if Rlogo.tif is actually RGB; assert on what it reports.
  p <- system.file("img", "Rlogo.tif", package = "ijtiff")
  img <- read_tif(p, msg = FALSE)
  pmi <- attr(img, "PhotometricInterpretation")
  tf <- tempfile(fileext = ".tif")
  write_tif(img, tf, msg = FALSE)
  if (identical(pmi, "RGB")) {
    expect_equal(read_tags(tf)[[1]]$PhotometricInterpretation, "RGB")
  } else {
    succeed("Rlogo.tif is not RGB; round-trip covered by the explicit test")
  }
})

test_that("writing an image with an un-writable source photometric does NOT error", {
  # Simulate a palette/CMYK read: attribute present but not writable.
  img <- array(as.double(1:24), dim = c(2, 3, 4))
  attr(img, "PhotometricInterpretation") <- "Palette"
  tf <- tempfile(fileext = ".tif")
  expect_no_error(write_tif(img, tf, msg = FALSE))          # auto-extract drops it
  expect_equal(read_tags(tf)[[1]]$PhotometricInterpretation, "BlackIsZero")
})

test_that("an EXPLICIT un-writable photometric errors clearly", {
  img <- array(as.double(1:24), dim = c(2, 3, 4))
  tf <- tempfile(fileext = ".tif")
  expect_error(
    write_tif(img, tf, tags_to_write = list(photometric = "Palette"), msg = FALSE)
  )
})
