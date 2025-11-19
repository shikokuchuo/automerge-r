# Object Operations Tests (Phase 2)

# Map Operations --------------------------------------------------------------

test_that("am_put() works with map (root)", {
  doc <- am_create()
  result <- am_put(doc, AM_ROOT, "key", "value")
  expect_identical(result, doc) # Returns doc invisibly
})

test_that("am_get() retrieves map values", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "name", "Alice")
  am_put(doc, AM_ROOT, "age", 30L)

  expect_equal(am_get(doc, AM_ROOT, "name"), "Alice")
  expect_equal(am_get(doc, AM_ROOT, "age"), 30L)
})

test_that("am_get() returns NULL for missing keys", {
  doc <- am_create()
  result <- am_get(doc, AM_ROOT, "nonexistent")
  expect_null(result)
})

test_that("am_put() supports all scalar types", {
  doc <- am_create()

  # NULL
  am_put(doc, AM_ROOT, "null_val", NULL)
  expect_null(am_get(doc, AM_ROOT, "null_val"))

  # Logical
  am_put(doc, AM_ROOT, "bool_val", TRUE)
  expect_equal(am_get(doc, AM_ROOT, "bool_val"), TRUE)

  # Integer
  am_put(doc, AM_ROOT, "int_val", 42L)
  expect_equal(am_get(doc, AM_ROOT, "int_val"), 42L)

  # Numeric (double)
  am_put(doc, AM_ROOT, "num_val", 3.14)
  expect_equal(am_get(doc, AM_ROOT, "num_val"), 3.14)

  # String
  am_put(doc, AM_ROOT, "str_val", "hello")
  expect_equal(am_get(doc, AM_ROOT, "str_val"), "hello")

  # Raw bytes
  raw_val <- as.raw(c(1, 2, 3, 4))
  am_put(doc, AM_ROOT, "raw_val", raw_val)
  expect_equal(am_get(doc, AM_ROOT, "raw_val"), raw_val)
})

test_that("am_keys() returns all map keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  am_put(doc, AM_ROOT, "c", 3)

  keys <- am_keys(doc, AM_ROOT)
  expect_type(keys, "character")
  expect_length(keys, 3)
  expect_true(all(c("a", "b", "c") %in% keys))
})

test_that("am_keys() returns empty vector for empty map", {
  doc <- am_create()
  keys <- am_keys(doc, AM_ROOT)
  expect_type(keys, "character")
  expect_length(keys, 0)
})

test_that("am_length() returns map size", {
  doc <- am_create()
  expect_equal(am_length(doc, AM_ROOT), 0L)

  am_put(doc, AM_ROOT, "a", 1)
  expect_equal(am_length(doc, AM_ROOT), 1L)

  am_put(doc, AM_ROOT, "b", 2)
  expect_equal(am_length(doc, AM_ROOT), 2L)
})

test_that("am_delete() removes map entries", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  expect_equal(am_length(doc, AM_ROOT), 1L)

  am_delete(doc, AM_ROOT, "key")
  expect_equal(am_length(doc, AM_ROOT), 0L)
  expect_null(am_get(doc, AM_ROOT, "key"))
})

test_that("am_put() updates existing keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value1")
  expect_equal(am_get(doc, AM_ROOT, "key"), "value1")

  am_put(doc, AM_ROOT, "key", "value2")
  expect_equal(am_get(doc, AM_ROOT, "key"), "value2")
  expect_equal(am_length(doc, AM_ROOT), 1L) # Still only 1 key
})

# List Operations -------------------------------------------------------------

test_that("am_put() creates and works with lists", {
  doc <- am_create()

  # Create a list (returns am_object directly)
  list_obj <- am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)

  expect_s3_class(list_obj, "am_object")
  expect_s3_class(list_obj$doc, "am_doc")
  expect_s3_class(list_obj$obj_id, "am_objid")
})

test_that("am_put() appends to lists with 'end'", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  # Append items
  am_put(doc, list_obj$obj_id, "end", "first")
  am_put(doc, list_obj$obj_id, "end", "second")
  am_put(doc, list_obj$obj_id, "end", "third")

  expect_equal(am_length(doc, list_obj$obj_id), 3L)
})

test_that("am_get() retrieves list elements by position", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj$obj_id, "end", "first")
  am_put(doc, list_obj$obj_id, "end", "second")

  # 1-based indexing
  expect_equal(am_get(doc, list_obj$obj_id, 1L), "first")
  expect_equal(am_get(doc, list_obj$obj_id, 2L), "second")
})

test_that("am_put() replaces list elements at position", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj$obj_id, "end", "original")
  am_put(doc, list_obj$obj_id, 1L, "replaced")

  expect_equal(am_get(doc, list_obj$obj_id, 1L), "replaced")
  expect_equal(am_length(doc, list_obj$obj_id), 1L) # Still 1 element
})

test_that("am_delete() removes list elements", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj$obj_id, "end", "first")
  am_put(doc, list_obj$obj_id, "end", "second")
  am_put(doc, list_obj$obj_id, "end", "third")

  expect_equal(am_length(doc, list_obj$obj_id), 3L)

  am_delete(doc, list_obj$obj_id, 2L) # Delete "second"
  expect_equal(am_length(doc, list_obj$obj_id), 2L)

  # Remaining elements shift down
  expect_equal(am_get(doc, list_obj$obj_id, 1L), "first")
  expect_equal(am_get(doc, list_obj$obj_id, 2L), "third")
})

# Nested Objects --------------------------------------------------------------

test_that("am_put() creates nested maps", {
  doc <- am_create()
  person_obj <- am_put(doc, AM_ROOT, "person", AM_OBJ_TYPE_MAP)

  expect_s3_class(person_obj, "am_object")

  # Add fields to nested map
  am_put(doc, person_obj$obj_id, "name", "Bob")
  am_put(doc, person_obj$obj_id, "age", 25L)

  expect_equal(am_get(doc, person_obj$obj_id, "name"), "Bob")
  expect_equal(am_get(doc, person_obj$obj_id, "age"), 25L)
})

test_that("Multiple levels of nesting work", {
  doc <- am_create()

  # Level 1: root -> "data" (map)
  data_obj <- am_put(doc, AM_ROOT, "data", AM_OBJ_TYPE_MAP)

  # Level 2: data -> "users" (list)
  users_obj <- am_put(doc, data_obj$obj_id, "users", AM_OBJ_TYPE_LIST)

  # Level 3: users[0] -> user (map)
  user_obj <- am_put(doc, users_obj$obj_id, "end", AM_OBJ_TYPE_MAP)

  # Level 4: user -> "name"
  am_put(doc, user_obj$obj_id, "name", "Charlie")

  # Verify
  expect_equal(am_get(doc, user_obj$obj_id, "name"), "Charlie")
})

# Integration Tests -----------------------------------------------------------

test_that("Map operations integrate with commit/save/load", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "x", 1)
  am_put(doc1, AM_ROOT, "y", 2)
  am_commit(doc1, "Add x and y")

  # Save and load
  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  # Verify values survived
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "y"), 2)
  expect_equal(am_length(doc2, AM_ROOT), 2L)
})

test_that("List operations integrate with commit/save/load", {
  doc1 <- am_create()
  list_obj <- am_put(doc1, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc1, list_obj$obj_id, "end", "a")
  am_put(doc1, list_obj$obj_id, "end", "b")
  am_commit(doc1, "Create list")

  # Save and load
  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  # Get list from loaded doc
  list_obj2 <- am_get(doc2, AM_ROOT, "list")
  expect_equal(am_length(doc2, list_obj2$obj_id), 2L)
  expect_equal(am_get(doc2, list_obj2$obj_id, 1L), "a")
  expect_equal(am_get(doc2, list_obj2$obj_id, 2L), "b")
})

test_that("Merge works with object operations", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Make changes in each doc
  am_put(doc1, AM_ROOT, "x", 1)
  am_commit(doc1, "Add x")

  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "Add y")

  # Merge doc2 into doc1
  am_merge(doc1, doc2)

  # Both keys should be present
  expect_equal(am_get(doc1, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc1, AM_ROOT, "y"), 2)
  expect_equal(am_length(doc1, AM_ROOT), 2L)
})

test_that("Complex document structure", {
  doc <- am_create()

  # Create a document structure like:
  # {
  #   "title": "My Doc",
  #   "tags": ["tag1", "tag2"],
  #   "author": { "name": "Alice", "email": "alice@example.com" }
  # }

  am_put(doc, AM_ROOT, "title", "My Doc")

  tags_obj <- am_put(doc, AM_ROOT, "tags", AM_OBJ_TYPE_LIST)
  am_put(doc, tags_obj$obj_id, "end", "tag1")
  am_put(doc, tags_obj$obj_id, "end", "tag2")

  author_obj <- am_put(doc, AM_ROOT, "author", AM_OBJ_TYPE_MAP)
  am_put(doc, author_obj$obj_id, "name", "Alice")
  am_put(doc, author_obj$obj_id, "email", "alice@example.com")

  # Verify structure
  expect_equal(am_get(doc, AM_ROOT, "title"), "My Doc")
  expect_equal(am_length(doc, tags_obj$obj_id), 2L)
  expect_equal(am_get(doc, tags_obj$obj_id, 1L), "tag1")
  expect_equal(am_get(doc, author_obj$obj_id, "name"), "Alice")
  expect_equal(am_get(doc, author_obj$obj_id, "email"), "alice@example.com")
})
