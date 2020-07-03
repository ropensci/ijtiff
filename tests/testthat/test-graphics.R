test_that("display works", {
  skip_if(win32bit())
  skip_if_not_installed("EBImage")
  skip_if_not_installed("vdiffr")
  skip_if_not_installed("rprojroot")
  skip_if_not(
    isTRUE(
      tryCatch(fs::dir_exists(rprojroot::find_package_root_file("tests/figs")),
        error = function(cnd) FALSE
      )
    )
  )
  skip_if_not(
    isTRUE(
      tryCatch(
        fs::dir_exists(rprojroot::find_package_root_file("inst/local-only")),
        error = function(cnd) FALSE
      )
    )
  )
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
    display(img[, , 3, 1], method = "r")
  )
  img <- read_tif(
    rprojroot::find_package_root_file("inst/local-only/Rlogo-banana-red.tif")
  )
  vdiffr::expect_doppelganger("R logo banana red", display(img, method = "r"))
})
