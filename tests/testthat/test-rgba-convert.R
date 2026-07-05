# Skip a fixture only if the linked libtiff lacks the codec to RGBA-decode it
# (e.g. no JPEG codec for YCbCr). Match the capability error specifically so a
# genuine logic bug in our branch does NOT get silently skipped.
can_convert <- function(path) {
  tryCatch({ read_tif(path, convert = "force", msg = FALSE); TRUE },
           error = function(e) {
             if (grepl("JPEG|codec|compress|RGBA", conditionMessage(e),
                       ignore.case = TRUE)) FALSE else stop(e)
           })
}

test_that("convert='force' converts CMYK to raw 0..255 RGB and reshapes correctly", {
  cm <- system.file("img", "cmyk.tif", package = "ijtiff")   # source spp=4
  skip_if_not(can_convert(cm), "libtiff lacks CMYK->RGBA support")
  cmimg <- read_tif(cm, convert = "force", msg = FALSE)
  expect_identical(dim(cmimg)[1:2], c(40L, 48L))
  expect_gte(dim(cmimg)[3], 3L)              # 3 (RGB) — would error pre-fix (n_ch=4)
  expect_equal(dim(cmimg)[4], 1L)
  expect_lte(max(cmimg), 255); expect_gte(min(cmimg), 0)
  expect_equal(attr(cmimg, "BitsPerSample"), 8L)               # reconciled
  expect_equal(attr(cmimg, "SamplesPerPixel"), dim(cmimg)[3])  # reconciled
  expect_equal(attr(cmimg, "PhotometricInterpretation"), "RGB")
  expect_null(attr(cmimg, "converted"))       # internal marker, not leaked
})

test_that("convert='force' converts YCbCr to RGB (needs JPEG codec)", {
  yc <- system.file("img", "ycbcr.tif", package = "ijtiff")
  skip_if_not(can_convert(yc), "libtiff lacks JPEG/YCbCr RGBA support")
  ycimg <- read_tif(yc, convert = "force", msg = FALSE)
  expect_identical(dim(ycimg)[1:2], c(40L, 48L))
  expect_gte(dim(ycimg)[3], 3L)
  expect_lte(max(ycimg), 255); expect_gte(min(ycimg), 0)
  expect_equal(attr(ycimg, "BitsPerSample"), 8L)
})

test_that("convert='auto' (default) leaves currently-readable images UNCHANGED", {
  # CMYK reads today as native 4-channel; auto must NOT convert it (compat).
  cm <- system.file("img", "cmyk.tif", package = "ijtiff")
  auto <- read_tif(cm, msg = FALSE)                 # default convert = "auto"
  expect_equal(dim(auto)[3], 4L)                    # still 4-channel C,M,Y,K
  expect_null(attr(auto, "converted"))
  # A plain contiguous tiled RGB image also stays on the direct path.
  tr <- read_tif(system.file("img", "tiled_rgb.tif", package = "ijtiff"), msg = FALSE)
  expect_equal(dim(tr)[3], 3L)
  expect_null(attr(tr, "converted"))
})

test_that("convert='auto' RGBA-rescues a structurally-undecodable image", {
  # tiled + planar (spp>1, non-contig) errors on the direct path today.
  tp <- system.file("img", "tiled_planar.tif", package = "ijtiff")
  skip_if_not(can_convert(tp), "libtiff cannot RGBA-decode tiled-planar")
  img <- read_tif(tp, msg = FALSE)                  # auto falls back
  expect_gte(dim(img)[3], 3L)
  expect_equal(attr(img, "BitsPerSample"), 8L)
})

test_that("convert='never' does NOT error on a currently-readable image", {
  cm <- system.file("img", "cmyk.tif", package = "ijtiff")
  expect_no_error(read_tif(cm, convert = "never", msg = FALSE))   # reads today
  # but 'never' still errors on the structurally-undecodable case
  tp <- system.file("img", "tiled_planar.tif", package = "ijtiff")
  expect_error(read_tif(tp, convert = "never", msg = FALSE))
})

test_that("forced conversion prints a message", {
  cm <- system.file("img", "cmyk.tif", package = "ijtiff")
  skip_if_not(can_convert(cm), "libtiff lacks CMYK->RGBA support")
  expect_message(read_tif(cm, convert = "force", msg = TRUE), "RGBA")
})
