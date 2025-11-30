test_that("compression can be overridden via tags_to_write when compression='none'", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Write with compression="none" but override with LZW in tags_to_write
  write_tif(img, temp_file, compression = "none",
            tags_to_write = list(compression = "LZW"),
            msg = FALSE)

  # Read back and check compression
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "LZW")
})

test_that("compression override works with different compression types", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Note: RLE requires 1 bit per sample, so we exclude it from this test
  compression_types <- c("LZW", "Zip", "deflate", "PackBits")

  for (comp_type in compression_types) {
    write_tif(img, temp_file, compression = "none",
              tags_to_write = list(compression = comp_type),
              overwrite = TRUE, msg = FALSE)

    tags <- read_tags(temp_file)
    # Note: deflate and Zip both appear as "Deflate" in read_tags
    expected <- if (comp_type %in% c("deflate", "Zip")) "Deflate" else comp_type
    expect_equal(tags[[1]]$Compression, expected,
                 info = paste("Failed for compression type:", comp_type))
  }
})

test_that("compression override is case-insensitive", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Test with various case variations
  write_tif(img, temp_file, compression = "none",
            tags_to_write = list(compression = "lzw"),
            msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "LZW")

  write_tif(img, temp_file, compression = "none",
            tags_to_write = list(compression = "PACKBITS"),
            overwrite = TRUE, msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "PackBits")
})

test_that("compression override handles hyphens and underscores", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Test with hyphens and underscores in tag name
  write_tif(img, temp_file, compression = "none",
            tags_to_write = list("com-pression" = "LZW"),
            msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "LZW")

  write_tif(img, temp_file, compression = "none",
            tags_to_write = list("com_pres_sion" = "Zip"),
            overwrite = TRUE, msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "Deflate")  # Zip appears as Deflate
})

test_that("compression from parameter is used when not 'none'", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # When compression parameter is not "none", tags_to_write should be ignored
  # Actually, for now compression in tags_to_write is just silently ignored
  # if compression != "none"
  write_tif(img, temp_file, compression = "LZW", msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$Compression, "LZW")
})

test_that("compression override rejects invalid values", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")

  expect_error(
    write_tif(img, temp_file, compression = "none",
              tags_to_write = list(compression = "invalid"),
              msg = FALSE)
  )
})
