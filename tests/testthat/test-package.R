test_that("package loads successfully", {
  expect_true(TRUE)
})

test_that("constants are exported", {
  expect_null(AM_ROOT)
  expect_s3_class(AM_OBJ_TYPE_LIST, "am_obj_type")
  expect_equal(as.character(AM_OBJ_TYPE_LIST), "list")
  expect_s3_class(AM_OBJ_TYPE_MAP, "am_obj_type")
  expect_equal(as.character(AM_OBJ_TYPE_MAP), "map")
  expect_s3_class(AM_OBJ_TYPE_TEXT, "am_obj_type")
  expect_equal(as.character(AM_OBJ_TYPE_TEXT), "text")
  expect_equal(AM_MARK_EXPAND_NONE, "none")
  expect_equal(AM_MARK_EXPAND_BEFORE, "before")
  expect_equal(AM_MARK_EXPAND_AFTER, "after")
  expect_equal(AM_MARK_EXPAND_BOTH, "both")
})
