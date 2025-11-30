test_that("documentname can be written and read back", {
  documentname_value <- "Test Document"
  test_tag_write_read("documentname", documentname_value)
})

test_that("documentname accepts valid values", {
  valid_values <- c(
    "Sample Document",
    "Report 2025-01-01",
    "Experiment Results",
    "Microscopy Data",
    "Patient Record 12345"
  )
  test_tag_valid_values("documentname", valid_values)
})

test_that("documentname rejects invalid values", {
  invalid_values <- list(
    123,
    c("Doc1", "Doc2")
  )
  test_tag_invalid_values("documentname", invalid_values)
})
