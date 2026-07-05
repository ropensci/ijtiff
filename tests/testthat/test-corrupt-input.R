# Regression test for the corrupt-input GC segfault (task 6b).
#
# Each C read entry point used to hand libtiff a STACK-LOCAL tiff_job_t as its
# client handle, while registering an external-pointer finalizer that closes the
# handle at GC. When a libtiff-internal error (e.g. a corrupt compressed strip)
# longjmp'd out of the entry point, the stack frame died but the finalizer still
# held the open handle; the next gc() ran TIFFClose against the dead job state
# -> use-after-free -> segfault. The fix heap-allocates the job state inside a
# tiff_ctx_t owned by the external pointer, so the finalizer always closes
# against valid memory.
#
# These loops SEGFAULT on the pre-fix code (bare Rscript exit 139) and pass
# after the fix. We must exercise a libtiff error that fires *after* a
# successful open (i.e. mid-decode): corrupt the compressed strip bytes while
# leaving the TIFF header and IFD intact. (Merely truncating a file to its first
# half instead fails at open time -- a clean NULL return, not the crash path.)

# Build a valid deflate-compressed TIFF, then garble a run of its compressed
# strip data while keeping the 8-byte header and the IFD untouched, so libtiff
# opens the file but errors while decoding the strip.
make_corrupt_tiff_bytes <- function() {
  set.seed(1)
  img <- array(sample(0:65535, 128 * 128 * 3, replace = TRUE),
               dim = c(128, 128, 3))
  f <- tempfile(fileext = ".tif")
  write_tif(img, f, bits_per_sample = 16, compression = "Zip", msg = FALSE)
  raw_all <- readBin(f, what = "raw", n = file.info(f)$size)
  n <- length(raw_all)
  # IFD offset lives in bytes 5:8, endianness per the byte-order mark (II/MM).
  endian <- if (rawToChar(raw_all[1:2]) == "II") "little" else "big"
  ifd_off <- readBin(raw_all[5:8], "integer", n = 1, size = 4, endian = endian)
  # Corrupt a block of the compressed strip data that sits after the header and
  # before the IFD, so the header + directory stay readable (open succeeds) but
  # the deflate stream is broken (decode errors mid-read).
  lo <- 9L
  hi <- min(as.integer(ifd_off) - 1L, lo + 2000L)
  stopifnot(hi > lo)
  set.seed(99)
  raw_all[lo:hi] <- as.raw(sample(0:255, hi - lo + 1L, replace = TRUE))
  raw_all
}

test_that("reading a corrupt TIFF file in a gc loop does not crash the session", {
  bytes <- make_corrupt_tiff_bytes()
  f <- tempfile(fileext = ".tif")
  writeBin(bytes, f)
  suppressWarnings(
    for (i in 1:80) {
      expect_error(read_tif(f, msg = FALSE))
      gc()
    }
  )
  # Reached only if the session survived every read + gc.
  succeed()
  expect_true(TRUE)
})

test_that("reading a corrupt TIFF raw vector in a gc loop does not crash", {
  bytes <- make_corrupt_tiff_bytes()
  suppressWarnings(
    for (i in 1:80) {
      expect_error(read_tif(bytes, msg = FALSE))
      gc()
    }
  )
  succeed()
  expect_true(TRUE)
})
