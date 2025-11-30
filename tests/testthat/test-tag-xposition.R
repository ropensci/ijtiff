test_that("xposition can be written and read back", {
  xposition_value <- 10.5
  test_tag_write_read("xposition", xposition_value)
})

test_that("xposition accepts valid values", {
  valid_values <- c(0, 1.5, 10, 100.25, 1000)
  test_tag_valid_values("xposition", valid_values)
})

test_that("xposition rejects invalid values", {
  invalid_values <- list(
    "10",
    c(1, 2)
  )
  test_tag_invalid_values("xposition", invalid_values)
})
