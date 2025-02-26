test_that("artist can be written and read back", {
  artist_value <- "Test User"
  test_tag_write_read("artist", artist_value)
})

test_that("artist accepts valid values", {
  valid_values <- c(
    "John Doe",
    "Jane Smith, Ph.D.",
    "Imaging Lab Team",
    "Anonymous",
    "Organization Name"
  )
  test_tag_valid_values("artist", valid_values)
})

test_that("artist rejects invalid values", {
  invalid_values <- list(
    123,
    c("John", "Jane")
  )
  test_tag_invalid_values("artist", invalid_values)
})
