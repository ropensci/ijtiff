test_that("copyright can be written and read back", {
  copyright_value <- "Copyright (c) 2025 Test User"
  test_tag_write_read("copyright", copyright_value)
})

test_that("copyright accepts valid values", {
  valid_values <- c(
    "Copyright (c) 2025",
    " 2025 Example Organization",
    "All rights reserved",
    "Licensed under MIT",
    "Public Domain"
  )
  test_tag_valid_values("copyright", valid_values)
})

test_that("copyright rejects invalid values", {
  invalid_values <- list(
    2025,
    c("Copyright 1", "Copyright 2")
  )
  test_tag_invalid_values("copyright", invalid_values)
})
