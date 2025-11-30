test_that("imagedescription can be written and read back", {
  desc_value <- "Test image description"
  test_tag_write_read("imagedescription", desc_value)
})

test_that("imagedescription accepts valid values", {
  valid_values <- c(
    "Simple description",
    "Description with special chars: !@#$%",
    "Multi-line\ndescription",
    "Unicode: café résumé"
  )
  test_tag_valid_values("imagedescription", valid_values)
})

test_that("imagedescription rejects invalid values", {
  invalid_values <- list(
    123,
    c("multiple", "strings"),
    list("nested")
  )
  test_tag_invalid_values("imagedescription", invalid_values)
})
