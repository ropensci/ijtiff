test_that("display works", {
  skip_if(win32bit())
  skip_if_not_installed("vdiffr")
  img <- read_tif(system.file("img", "Rlogo.tif", package = "ijtiff"))
  vdiffr::expect_doppelganger("raster R logo", display(img, method = "r"))
  vdiffr::expect_doppelganger("basic R logo", display(img, basic = TRUE))
  vdiffr::expect_doppelganger(
    "raster grey R logo",
    display(img[, , , ], method = "r")
  )
  vdiffr::expect_doppelganger(
    "raster grey r logo (blue channel)",
    display(img[, , 2, ], method = "r")
  )
  vdiffr::expect_doppelganger(
    "basic R logo (again)",
    display(img[, , , 1], basic = TRUE)
  )
  vdiffr::expect_doppelganger(
    "raster R logo (green channel)",
    display(img[, , 3, 1])
  )
  img <- read_tif(test_path("testthat-figs", "Rlogo-banana-red.tif"))
  vdiffr::expect_doppelganger("R logo banana red", display(img, method = "r"))
})
