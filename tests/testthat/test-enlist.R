test_that("enlist_img handles both integer and double arrays", {
  # Test double array
  dbl_arr <- array(as.double(1:24), dim = c(2, 2, 2, 3))
  dbl_result <- enlist_img(dbl_arr)
  expect_type(dbl_result, "list")
  expect_length(dbl_result, 3) # 3 frames
  expect_true(all(sapply(dbl_result, is.double)))
  expect_equal(dim(dbl_result[[1]]), c(2, 2, 2))

  # Test integer array
  int_arr <- array(1:24, dim = c(2, 2, 2, 3))
  int_result <- enlist_img(int_arr)
  expect_type(int_result, "list")
  expect_length(int_result, 3) # 3 frames
  expect_true(all(sapply(int_result, is.integer)))
  expect_equal(dim(int_result[[1]]), c(2, 2, 2))

  # Test data preservation
  expect_equal(as.vector(int_result[[1]]), 1:8)
  expect_equal(as.vector(int_result[[2]]), 9:16)
  expect_equal(as.vector(int_result[[3]]), 17:24)
})

test_that("enlist_planes handles both integer and double arrays", {
  # Test double array
  dbl_arr <- array(as.double(1:12), dim = c(2, 2, 3))
  dbl_result <- enlist_planes(dbl_arr)
  expect_type(dbl_result, "list")
  expect_length(dbl_result, 3) # 3 planes
  expect_true(all(sapply(dbl_result, is.double)))
  expect_equal(dim(dbl_result[[1]]), c(2, 2))

  # Test integer array
  int_arr <- array(1:12, dim = c(2, 2, 3))
  int_result <- enlist_planes(int_arr)
  expect_type(int_result, "list")
  expect_length(int_result, 3) # 3 planes
  expect_true(all(sapply(int_result, is.integer)))
  expect_equal(dim(int_result[[1]]), c(2, 2))

  # Test data preservation
  expect_equal(as.vector(int_result[[1]]), 1:4)
  expect_equal(as.vector(int_result[[2]]), 5:8)
  expect_equal(as.vector(int_result[[3]]), 9:12)
})

test_that("enlist functions handle edge cases", {
  # Test wrong dimensions with integer array
  expect_error(
    enlist_img(array(1L, dim = c(2, 2, 2))),
    "Must be a 4-d array"
  )
  expect_error(
    enlist_planes(array(1L, dim = c(2, 2))),
    "Must be a 3-d array"
  )

  # Test wrong dimensions with double array
  expect_error(
    enlist_img(array(1.0, dim = c(2, 2, 2))),
    "Must be a 4-d array"
  )
  expect_error(
    enlist_planes(array(1.0, dim = c(2, 2))),
    "Must be a 3-d array"
  )

  # Test empty arrays
  empty_4d <- array(double(), dim = c(0, 0, 0, 0))
  empty_3d <- array(double(), dim = c(0, 0, 0))

  # Verify empty arrays are handled correctly
  empty_4d_result <- enlist_img(empty_4d)
  expect_type(empty_4d_result, "list")
  expect_length(empty_4d_result, 0) # Should be empty list

  empty_3d_result <- enlist_planes(empty_3d)
  expect_type(empty_3d_result, "list")
  expect_length(empty_3d_result, 0) # Should be empty list
})
