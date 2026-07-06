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

# Regression for the residual last_tiff double-close use-after-free.
#
# After the heap-ctx fix (above), the per-ctx external-pointer finalizer
# (cleanup_tiff_ptr) is the SOLE owner of each TIFF* and closes it exactly once.
# But two spots still eagerly TIFFClose(last_tiff): TIFF_Open (on the *next*
# open) and cleanup_tiff (at exit). When a corrupt read errored mid-decode, the
# handle was left open and owned by a still-pending finalizer; a subsequent
# TIFF_Open (any later read/write) would TIFFClose it via last_tiff, and then the
# original ctx's finalizer would TIFFClose the same handle AGAIN at gc() ->
# double-close / use-after-free -> nondeterministic SIGBUS/SIGABRT. The fix
# removes both eager closes; the finalizer alone reclaims each handle.
#
# The interleaved "corrupt read -> good read -> gc()" pattern below is what
# triggers it (the good read's TIFF_Open double-closes the corrupt read's
# leaked-but-finalizer-owned handle). NOTE: testthat runs everything in one
# process and can MASK a fatal double-close (an abort inside the loop may still
# be reported as passing depending on the handler); the authoritative check is
# the bare-Rscript harness (crashtest.R patterns 1 & 2, exit code 0 across
# repeats), which crashes (exit 134/138) on the pre-fix code.
# Regression for a 32-bit integer-overflow in the direct-decode allocation.
#
# read_tif_C sizes its output buffer with allocVector(REALSXP, W*L*spp). W and
# L are uint32_t and spp uint16_t, so the product is computed in 32-bit
# arithmetic and would WRAP before being widened to allocVector's 64-bit
# argument. A forged TIFF declaring e.g. 65536x65536 (W*L == 2^32 -> 0) could
# under-allocate the buffer and let the strip/tile decode write out of bounds.
# The fix computes the count in size_t with an overflow guard (mirroring the
# RGBA path). We forge such dimensions on an otherwise valid file and require a
# clean R error rather than a crash or silent under-allocation.
forge_huge_dims_tiff <- function() {
  img <- array(0L, dim = c(64, 64, 1))
  f <- tempfile(fileext = ".tif")
  write_tif(img, f, bits_per_sample = 8, compression = "none", msg = FALSE)
  raw_all <- readBin(f, what = "raw", n = file.info(f)$size)
  endian <- if (rawToChar(raw_all[1:2]) == "II") "little" else "big"
  ifd_off <- readBin(raw_all[5:8], "integer", n = 1, size = 4, endian = endian)
  n_entries <- readBin(raw_all[ifd_off + 1:2], "integer",
    n = 1, size = 2, endian = endian
  )
  int_bytes <- function(x, size) {
    writeBin(as.integer(x), raw(), size = size, endian = endian)
  }
  for (i in seq_len(n_entries) - 1L) {
    entry_off <- ifd_off + 2L + 12L * i
    tag <- readBin(raw_all[entry_off + 1:2], "integer",
      n = 1, size = 2, signed = FALSE, endian = endian
    )
    if (tag %in% c(256L, 257L)) { # ImageWidth, ImageLength -> 65536 (LONG)
      raw_all[entry_off + 3:4] <- int_bytes(4L, 2)
      raw_all[entry_off + 9:12] <- int_bytes(65536L, 4)
    }
  }
  raw_all
}

test_that("a forged huge-dimension TIFF errors cleanly instead of overflowing", {
  bytes <- forge_huge_dims_tiff()
  f <- tempfile(fileext = ".tif")
  writeBin(bytes, f)
  suppressWarnings(
    for (i in 1:20) {
      expect_error(read_tif(f, convert = "never", msg = FALSE))
      gc()
    }
  )
  succeed()
  expect_true(TRUE)
})

test_that("corrupt read followed by good reads in a gc loop does not crash", {
  bytes <- make_corrupt_tiff_bytes()
  f <- tempfile(fileext = ".tif")
  writeBin(bytes, f)
  good <- system.file("img", "Rlogo.tif", package = "ijtiff")
  expect_true(file.exists(good))
  suppressWarnings(
    for (i in 1:80) {
      expect_error(read_tif(f, msg = FALSE))    # corrupt: errors mid-decode
      x <- read_tif(good, msg = FALSE)          # good: its TIFF_Open used to
      expect_true(is.array(x))                  #       double-close the above
      if (i %% 5L == 0L) gc()                   # sparse gc to vary finalizer timing
    }
  )
  gc()
  # Reached only if the session survived every corrupt+good read + gc.
  succeed()
  expect_true(TRUE)
})
