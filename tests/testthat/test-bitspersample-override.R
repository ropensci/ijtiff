test_that("bits_per_sample can be overridden via tags_to_write when bits_per_sample='auto'", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Write with bits_per_sample="auto" but override with 16 in tags_to_write
  write_tif(img, temp_file, bits_per_sample = "auto",
            tags_to_write = list(bitspersample = 16),
            msg = FALSE)

  # Read back and check bits per sample
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$BitsPerSample, 16)
})

test_that("bits_per_sample override works with different values", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  bps_values <- c(8, 16, 32)

  for (bps in bps_values) {
    write_tif(img, temp_file, bits_per_sample = "auto",
              tags_to_write = list(bitspersample = bps),
              overwrite = TRUE, msg = FALSE)

    tags <- read_tags(temp_file)
    expect_equal(tags[[1]]$BitsPerSample, bps,
                 info = paste("Failed for bits_per_sample:", bps))
  }
})

test_that("bits_per_sample override handles hyphens and underscores", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # Test with hyphens and underscores in tag name
  write_tif(img, temp_file, bits_per_sample = "auto",
            tags_to_write = list("bits-per-sample" = 16),
            msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$BitsPerSample, 16)

  write_tif(img, temp_file, bits_per_sample = "auto",
            tags_to_write = list("bits_per_sample" = 32),
            overwrite = TRUE, msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$BitsPerSample, 32)
})

test_that("bits_per_sample from parameter is used when not 'auto'", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")
  on.exit(unlink(temp_file), add = TRUE)

  # When bits_per_sample parameter is not "auto", it should be used
  write_tif(img, temp_file, bits_per_sample = 16, msg = FALSE)
  tags <- read_tags(temp_file)
  expect_equal(tags[[1]]$BitsPerSample, 16)
})

test_that("bits_per_sample override rejects invalid values", {
  img <- matrix(1:100, nrow = 10)
  temp_file <- tempfile(fileext = ".tif")

  expect_error(
    write_tif(img, temp_file, bits_per_sample = "auto",
              tags_to_write = list(bitspersample = 12),
              msg = FALSE),
    "must be one of 8, 16 or 32"
  )

  expect_error(
    write_tif(img, temp_file, bits_per_sample = "auto",
              tags_to_write = list(bitspersample = "invalid"),
              msg = FALSE)
  )
})
