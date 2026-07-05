# Skip a fixture only if the linked libtiff genuinely lacks the codec to decode
# it (e.g. no JPEG codec for YCbCr). Match ONLY codec-absence messages, so a
# real logic bug in the RGBA branch surfaces as an error rather than a silent
# skip. Do NOT match "RGBA" here -- that is the branch's own failure message.
can_convert <- function(path) {
  tryCatch({ read_tif(path, convert = "force", msg = FALSE); TRUE },
           error = function(e) {
             if (grepl("JPEG|codec|compress", conditionMessage(e),
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

test_that("convert='auto' RGBA-rescues a direct-undecodable image (bilevel 1-bit)", {
  # bilevel1.tif is 1-bit (bps=1): the direct decoder cannot parse it, so the
  # DEFAULT convert="auto" must transparently RGBA-rescue it. This is the
  # marquee auto-rescue capability -- it must PASS, not skip.
  bl <- system.file("img", "bilevel1.tif", package = "ijtiff")
  img <- read_tif(bl, msg = FALSE)                  # default convert = "auto"
  expect_gte(dim(img)[3], 3L)                       # RGB(A) output
  expect_lte(max(img), 255); expect_gte(min(img), 0)
  expect_equal(attr(img, "BitsPerSample"), 8L)
  expect_equal(attr(img, "SamplesPerPixel"), dim(img)[3])
  expect_equal(attr(img, "PhotometricInterpretation"), "RGB")
  expect_null(attr(img, "converted"))              # internal marker, not leaked
})

test_that("tiled separate-planar images cannot be read (auto or never)", {
  # libtiff's non-mmap TIFFReadRGBAImage mishandles tiled + PLANARCONFIG_SEPARATE
  # and ijtiff always disables mmap, so RGBA cannot rescue these; the direct path
  # cannot parse them either. They therefore error under BOTH auto and never.
  tp <- system.file("img", "tiled_planar.tif", package = "ijtiff")
  expect_error(read_tif(tp, convert = "auto", msg = FALSE))
  expect_error(read_tif(tp, convert = "never", msg = FALSE))
})

test_that("convert='never' does NOT error on a currently-readable image", {
  cm <- system.file("img", "cmyk.tif", package = "ijtiff")
  expect_no_error(read_tif(cm, convert = "never", msg = FALSE))   # reads today
})

test_that("forced conversion prints a message", {
  cm <- system.file("img", "cmyk.tif", package = "ijtiff")
  skip_if_not(can_convert(cm), "libtiff lacks CMYK->RGBA support")
  expect_message(read_tif(cm, convert = "force", msg = TRUE), "RGBA")
})
