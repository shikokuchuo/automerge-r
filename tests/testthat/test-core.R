# Core Foundation Tests (Phase 1)
# Tests for package structure, constants, and basic memory management

test_that("Package loads successfully", {
  expect_true("automerge" %in% loadedNamespaces())
})

test_that("Constants are exported correctly", {
  # Root object constant
  expect_null(AM_ROOT)

  # Object type constants (have am_obj_type class)
  expect_s3_class(AM_OBJ_TYPE_LIST, "am_obj_type")
  expect_equal(as.character(AM_OBJ_TYPE_LIST), "list")
  expect_s3_class(AM_OBJ_TYPE_MAP, "am_obj_type")
  expect_equal(as.character(AM_OBJ_TYPE_MAP), "map")
  expect_s3_class(AM_OBJ_TYPE_TEXT, "am_obj_type")
  expect_equal(as.character(AM_OBJ_TYPE_TEXT), "text")

  # Mark expansion constants
  expect_equal(AM_MARK_EXPAND_NONE, "none")
  expect_equal(AM_MARK_EXPAND_BEFORE, "before")
  expect_equal(AM_MARK_EXPAND_AFTER, "after")
  expect_equal(AM_MARK_EXPAND_BOTH, "both")
})

test_that("Internal enum maps are defined", {
  # These are internal, so access via ::: for testing
  obj_type_map <- automerge:::.am_obj_type_map
  expect_type(obj_type_map, "integer")
  expect_named(obj_type_map, c("list", "map", "text"))
  expect_equal(obj_type_map[["list"]], 1L)
  expect_equal(obj_type_map[["map"]], 2L)
  expect_equal(obj_type_map[["text"]], 3L)

  mark_expand_map <- automerge:::.am_mark_expand_map
  expect_type(mark_expand_map, "integer")
  expect_named(mark_expand_map, c("none", "before", "after", "both"))
  expect_equal(mark_expand_map[["none"]], 1L)
  expect_equal(mark_expand_map[["before"]], 2L)
  expect_equal(mark_expand_map[["after"]], 3L)
  expect_equal(mark_expand_map[["both"]], 4L)
})
