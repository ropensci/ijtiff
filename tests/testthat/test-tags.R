test_that("get_supported_tags returns correct tags", {
  tags <- get_supported_tags()
  expect_true(is.integer(tags))
  expect_true(!is.null(names(tags)))
  expect_equal(length(tags), 26)
  expect_true(all(nchar(names(tags)) > 1))
  expect_equal(length(unique(tags)), length(tags))
  expect_false(any(names(tags) == "Unknown"))
  expect_true( # CamelCase tags
    all(stringr::str_detect(names(tags), "^([A-Z][a-z]*)+[a-z]$"))
  )
})
