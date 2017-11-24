context("Graphics")

test_that("display works", {
  cwd <- getwd()
  on.exit(setwd(cwd))
  setwd(tempdir())
  original_files <- dir()
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
  expect_null(display(img[, , 1, 1]))
  expect_null(display(img[, , 2, 1]))
  expect_null(display(img[, , 3, 1]))
  new_files <- setdiff(original_files, dir())
  suppressWarnings(file.remove(dir()))
})
