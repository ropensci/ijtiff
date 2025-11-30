test_that("yposition can be written and read back", {
  yposition_value <- 15.75
  test_tag_write_read("yposition", yposition_value)
})

test_that("yposition accepts valid values", {
  valid_values <- c(0, 2.5, 20, 200.25, 2000)
  test_tag_valid_values("yposition", valid_values)
})

test_that("yposition rejects invalid values", {
  invalid_values <- list(
    "20",
    c(1, 2)
  )
  test_tag_invalid_values("yposition", invalid_values)
})
