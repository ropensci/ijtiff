test_that("`count_frames()` works", {
  skip_if(win32bit())
  expect_equal(
    count_frames(system.file("img", "Rlogo.tif", package = "ijtiff")),
    structure(1, n_dirs = 1)
  )
  expect_equal(
    frames_count(system.file("img", "2ch_ij.tif", package = "ijtiff")),
    structure(5, n_dirs = 10)
  )
})
