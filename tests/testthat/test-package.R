test_that("package loads successfully", {
  expect_true(TRUE)
})

test_that("constants are exported", {
  expect_null(AM_ROOT)
  expect_equal(AM_OBJ_TYPE_LIST, "list")
  expect_equal(AM_OBJ_TYPE_MAP, "map")
  expect_equal(AM_OBJ_TYPE_TEXT, "text")
  expect_equal(AM_MARK_EXPAND_NONE, "none")
  expect_equal(AM_MARK_EXPAND_BEFORE, "before")
  expect_equal(AM_MARK_EXPAND_AFTER, "after")
  expect_equal(AM_MARK_EXPAND_BOTH, "both")
})
