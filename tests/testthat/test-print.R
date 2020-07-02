test_that("print method works", {
  verify_output(
    test_path("printing_of_Rlogo-banana-red.txt"),
    print(
      read_tif(system.file("img", "Rlogo-banana-red.tif",
                           package = "ijtiff"))
    )
  )
})
