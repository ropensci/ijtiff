test_that("text-image-io works", {
  # Create test image
  mm <- matrix(1:60, nrow = 4)
  dim(mm) <- c(dim(mm), 1, 1)
  tmpfl <- tempfile() %>%
    stringr::str_replace_all(stringr::coll("\\"), "/")
  txt_img_write(mm, tmpfl, msg = FALSE)
  tmpfl_txt <- strex::str_give_ext(tmpfl, "txt")

  # Test reading
  expect_true(file.exists(tmpfl_txt))
  expect_equal(as.vector(mm),
    as.vector(txt_img_read(tmpfl_txt, msg = FALSE)),
    ignore_attr = FALSE
  )
  suppressMessages(
    expect_message(
      txt_img_read(tmpfl_txt, msg = TRUE),
      "Reading 4x15 pixel text image"
    )
  )
  file.remove(tmpfl_txt)

  # Test multi-channel
  skip_if_not_installed("abind")
  mmm <- abind::abind(mm, mm, along = 3)
  suppressMessages(
    expect_message(
      write_txt_img(mmm, tmpfl, rds = TRUE),
      "_ch1.txt and .+_ch2.txt"
    )
  )
  expect_equal(readRDS(strex::str_give_ext(tmpfl, "rds")), ijtiff_img(mmm))
  tmpfl_txts <- paste0(tmpfl, "_ch", 1:2, ".txt")
  expect_equal(
    dir(strex::str_before_last(tmpfl, "/"),
      pattern = paste0(
        strex::str_after_last(tmpfl, "/"),
        ".+txt$"
      )
    ),
    strex::str_after_last(tmpfl_txts, "/"),
    ignore_attr = FALSE
  )
  expect_equal(unlist(lapply(tmpfl_txts, read_txt_img, msg = FALSE)),
    as.vector(mmm),
    ignore_attr = FALSE
  )
  file.remove(tmpfl_txts)

  # Test multi-frame
  mmmm <- abind::abind(mmm, mmm, along = 4)
  write_txt_img(mmmm, tmpfl, msg = FALSE)
  tmpfl_txts <- paste0(tmpfl, c(
    "_ch1_frame1",
    "_ch1_frame2",
    "_ch2_frame1",
    "_ch2_frame2"
  ), ".txt")
  expect_equal(
    dir(strex::str_before_last(tmpfl, "/"),
      pattern = paste0(
        strex::str_after_last(tmpfl, "/"),
        ".+txt$"
      )
    ),
    strex::str_after_last(tmpfl_txts, "/"),
    ignore_attr = FALSE
  )
  expect_equal(unlist(lapply(tmpfl_txts, read_txt_img, msg = FALSE)),
    as.vector(mmmm),
    ignore_attr = FALSE
  )
  file.remove(tmpfl_txts)

  # Test error handling
  bad_txt_img <- dplyr::tribble(
    ~col1, ~col2,
    1, "5",
    8, "y"
  )
  tmpfl <- tempfile(fileext = ".txt")
  readr::write_tsv(bad_txt_img, tmpfl, col_names = FALSE)
  expect_error(
    read_txt_img(tmpfl),
    paste0(
      "`path` must be the path to a text file which is.+",
      "an array of.+numbers.",
      "* Column 2 of the text file at your `path`.+",
      "is not numeric."
    )
  )
})
