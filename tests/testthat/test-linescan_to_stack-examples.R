test_that("`linescan_to_stack()` works", {
  linescan <- ijtiff_img(array(rep(1:4, each = 4), dim = c(
    4, 4,
    1, 1
  )))
  stack <- linescan_to_stack(linescan)
  expect_equal(
    array(stack, dim = dim(stack)),
    array(rep(1:4, 4), dim = c(1, 4, 1, 4))
  )
  expect_equal(linescan, stack_to_linescan(stack))
  arr <- array(1, dim = rep(4, 4))
  expect_snapshot_error(linescan_to_stack(arr))
  expect_snapshot_error(stack_to_linescan(arr))
})
