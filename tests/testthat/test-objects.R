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

  # am_object is now an external pointer with am_object class
  expect_s3_class(list_obj, "am_object")
  expect_s3_class(list_obj, "am_list")
  expect_type(list_obj, "externalptr")
})

test_that("am_put() appends to lists with 'end'", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  # Append items
  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")
  am_put(doc, list_obj, "end", "third")

  expect_equal(am_length(doc, list_obj), 3L)
})

test_that("am_get() retrieves list elements by position", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")

  # 1-based indexing
  expect_equal(am_get(doc, list_obj, 1L), "first")
  expect_equal(am_get(doc, list_obj, 2L), "second")
})

test_that("am_put() replaces list elements at position", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "original")
  am_put(doc, list_obj, 1L, "replaced")

  expect_equal(am_get(doc, list_obj, 1L), "replaced")
  expect_equal(am_length(doc, list_obj), 1L) # Still 1 element
})

test_that("am_delete() removes list elements", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")
  am_put(doc, list_obj, "end", "third")

  expect_equal(am_length(doc, list_obj), 3L)

  am_delete(doc, list_obj, 2L) # Delete "second"
  expect_equal(am_length(doc, list_obj), 2L)

  # Remaining elements shift down
  expect_equal(am_get(doc, list_obj, 1L), "first")
  expect_equal(am_get(doc, list_obj, 2L), "third")
})

# Nested Objects --------------------------------------------------------------

test_that("am_put() creates nested maps", {
  doc <- am_create()
  person_obj <- am_put(doc, AM_ROOT, "person", AM_OBJ_TYPE_MAP)

  expect_s3_class(person_obj, "am_object")

  # Add fields to nested map
  am_put(doc, person_obj, "name", "Bob")
  am_put(doc, person_obj, "age", 25L)

  expect_equal(am_get(doc, person_obj, "name"), "Bob")
  expect_equal(am_get(doc, person_obj, "age"), 25L)
})

test_that("Multiple levels of nesting work", {
  doc <- am_create()

  # Level 1: root -> "data" (map)
  data_obj <- am_put(doc, AM_ROOT, "data", AM_OBJ_TYPE_MAP)

  # Level 2: data -> "users" (list)
  users_obj <- am_put(doc, data_obj, "users", AM_OBJ_TYPE_LIST)

  # Level 3: users[0] -> user (map)
  user_obj <- am_put(doc, users_obj, "end", AM_OBJ_TYPE_MAP)

  # Level 4: user -> "name"
  am_put(doc, user_obj, "name", "Charlie")

  # Verify
  expect_equal(am_get(doc, user_obj, "name"), "Charlie")
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

  am_put(doc1, list_obj, "end", "a")
  am_put(doc1, list_obj, "end", "b")
  am_commit(doc1, "Create list")

  # Save and load
  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  # Get list from loaded doc
  list_obj2 <- am_get(doc2, AM_ROOT, "list")
  expect_equal(am_length(doc2, list_obj2), 2L)
  expect_equal(am_get(doc2, list_obj2, 1L), "a")
  expect_equal(am_get(doc2, list_obj2, 2L), "b")
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
  am_put(doc, tags_obj, "end", "tag1")
  am_put(doc, tags_obj, "end", "tag2")

  author_obj <- am_put(doc, AM_ROOT, "author", AM_OBJ_TYPE_MAP)
  am_put(doc, author_obj, "name", "Alice")
  am_put(doc, author_obj, "email", "alice@example.com")

  # Verify structure
  expect_equal(am_get(doc, AM_ROOT, "title"), "My Doc")
  expect_equal(am_length(doc, tags_obj), 2L)
  expect_equal(am_get(doc, tags_obj, 1L), "tag1")
  expect_equal(am_get(doc, author_obj, "name"), "Alice")
  expect_equal(am_get(doc, author_obj, "email"), "alice@example.com")
})

# Edge Cases ------------------------------------------------------------------

test_that("am_put replaces nested object with scalar", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", list(nested = "data"))

  nested <- am_get(doc, AM_ROOT, "key")
  expect_s3_class(nested, "am_object")

  am_put(doc, AM_ROOT, "key", "scalar")
  expect_equal(am_get(doc, AM_ROOT, "key"), "scalar")
})

test_that("am_put replaces scalar with nested object", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "scalar")
  expect_equal(am_get(doc, AM_ROOT, "key"), "scalar")

  am_put(doc, AM_ROOT, "key", list(nested = "data"))
  nested <- am_get(doc, AM_ROOT, "key")
  expect_s3_class(nested, "am_object")
  expect_equal(am_get(doc, nested, "nested"), "data")
})

test_that("am_delete then re-add same key", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value1")
  am_delete(doc, AM_ROOT, "key")
  expect_null(am_get(doc, AM_ROOT, "key"))

  am_put(doc, AM_ROOT, "key", "value2")
  expect_equal(am_get(doc, AM_ROOT, "key"), "value2")
})

test_that("am_delete then re-add maintains different value", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", 100)
  am_commit(doc)
  am_delete(doc, AM_ROOT, "key")
  am_put(doc, AM_ROOT, "key", 200)

  expect_equal(am_get(doc, AM_ROOT, "key"), 200)
})

test_that("am_keys preserves keys after delete and re-add", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  am_delete(doc, AM_ROOT, "a")
  am_put(doc, AM_ROOT, "a", 3)

  keys <- am_keys(doc, AM_ROOT)
  expect_length(keys, 2)
  expect_true(all(c("a", "b") %in% keys))
})

test_that("am_put with UTF-8 keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "键", "value")
  am_put(doc, AM_ROOT, "clé", "value")
  am_put(doc, AM_ROOT, "🔑", "value")

  expect_equal(am_get(doc, AM_ROOT, "键"), "value")
  expect_equal(am_get(doc, AM_ROOT, "clé"), "value")
  expect_equal(am_get(doc, AM_ROOT, "🔑"), "value")

  keys <- am_keys(doc, AM_ROOT)
  expect_true(all(c("键", "clé", "🔑") %in% keys))
})

test_that("am_put with UTF-8 string values", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "chinese", "你好世界")
  am_put(doc, AM_ROOT, "emoji", "🎉🎊🎈")
  am_put(doc, AM_ROOT, "mixed", "Hello 世界 🌍")

  expect_equal(am_get(doc, AM_ROOT, "chinese"), "你好世界")
  expect_equal(am_get(doc, AM_ROOT, "emoji"), "🎉🎊🎈")
  expect_equal(am_get(doc, AM_ROOT, "mixed"), "Hello 世界 🌍")
})

test_that("am_put with very long key name", {
  doc <- am_create()
  long_key <- paste(rep("key", 1000), collapse = "_")
  am_put(doc, AM_ROOT, long_key, "value")
  expect_equal(am_get(doc, AM_ROOT, long_key), "value")
})

test_that("am_put handles zero values correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "zero_int", 0L)
  am_put(doc, AM_ROOT, "zero_dbl", 0.0)

  expect_identical(am_get(doc, AM_ROOT, "zero_int"), 0L)
  expect_identical(am_get(doc, AM_ROOT, "zero_dbl"), 0.0)
})

test_that("am_put handles negative numbers", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "neg_int", -42L)
  am_put(doc, AM_ROOT, "neg_dbl", -3.14)

  expect_equal(am_get(doc, AM_ROOT, "neg_int"), -42L)
  expect_equal(am_get(doc, AM_ROOT, "neg_dbl"), -3.14)
})

test_that("am_put handles very small and very large doubles", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "small", 1e-308)
  am_put(doc, AM_ROOT, "large", 1e308)

  expect_equal(am_get(doc, AM_ROOT, "small"), 1e-308)
  expect_equal(am_get(doc, AM_ROOT, "large"), 1e308)
})

test_that("am_length updates correctly after mixed operations", {
  doc <- am_create()
  expect_equal(am_length(doc, AM_ROOT), 0L)

  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  expect_equal(am_length(doc, AM_ROOT), 2L)

  am_delete(doc, AM_ROOT, "a")
  expect_equal(am_length(doc, AM_ROOT), 1L)

  am_put(doc, AM_ROOT, "c", 3)
  expect_equal(am_length(doc, AM_ROOT), 2L)

  am_put(doc, AM_ROOT, "b", 22)
  expect_equal(am_length(doc, AM_ROOT), 2L)
})

test_that("list operations maintain order after deletions", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "A")
  am_put(doc, list_obj, "end", "B")
  am_put(doc, list_obj, "end", "C")
  am_put(doc, list_obj, "end", "D")

  am_delete(doc, list_obj, 2)

  expect_equal(am_get(doc, list_obj, 1), "A")
  expect_equal(am_get(doc, list_obj, 2), "C")
  expect_equal(am_get(doc, list_obj, 3), "D")
  expect_equal(am_length(doc, list_obj), 3L)
})

test_that("multiple sequential deletes from list", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  for (i in 1:5) am_put(doc, list_obj, "end", i)
  expect_equal(am_length(doc, list_obj), 5L)

  am_delete(doc, list_obj, 3)
  am_delete(doc, list_obj, 1)
  am_delete(doc, list_obj, 2)

  expect_equal(am_length(doc, list_obj), 2L)
})

test_that("empty nested structures", {
  doc <- am_create()

  empty_map <- am_put(doc, AM_ROOT, "empty_map", AM_OBJ_TYPE_MAP)
  expect_equal(am_length(doc, empty_map), 0L)
  expect_equal(am_keys(doc, empty_map), character(0))

  empty_list <- am_put(doc, AM_ROOT, "empty_list", AM_OBJ_TYPE_LIST)
  expect_equal(am_length(doc, empty_list), 0L)
})

test_that("nested structures persist after save/load", {
  doc1 <- am_create()

  outer <- am_put(doc1, AM_ROOT, "outer", AM_OBJ_TYPE_MAP)
  inner <- am_put(doc1, outer, "inner", AM_OBJ_TYPE_MAP)
  am_put(doc1, inner, "value", 42)

  binary <- am_save(doc1)
  doc2 <- am_load(binary)

  outer2 <- am_get(doc2, AM_ROOT, "outer")
  inner2 <- am_get(doc2, outer2, "inner")
  expect_equal(am_get(doc2, inner2, "value"), 42)
})

# am_insert() Tests -----------------------------------------------------------

test_that("am_insert() inserts at position and shifts elements", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "A")
  am_put(doc, list_obj, "end", "C")

  # Insert "B" at position 2 - should shift "C" to position 3
  am_insert(doc, list_obj, 2L, "B")

  expect_equal(am_length(doc, list_obj), 3L)
  expect_equal(am_get(doc, list_obj, 1L), "A")
  expect_equal(am_get(doc, list_obj, 2L), "B")
  expect_equal(am_get(doc, list_obj, 3L), "C")
})

test_that("am_insert() at position 1 prepends to list", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "B")
  am_put(doc, list_obj, "end", "C")

  # Insert at position 1 - should shift everything down
  am_insert(doc, list_obj, 1L, "A")

  expect_equal(am_length(doc, list_obj), 3L)
  expect_equal(am_get(doc, list_obj, 1L), "A")
  expect_equal(am_get(doc, list_obj, 2L), "B")
  expect_equal(am_get(doc, list_obj, 3L), "C")
})

test_that("am_insert() vs am_put() behavior differs", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "A")
  am_put(doc, list_obj, "end", "B")

  # am_put replaces
  am_put(doc, list_obj, 2L, "REPLACED")
  expect_equal(am_length(doc, list_obj), 2L)
  expect_equal(am_get(doc, list_obj, 2L), "REPLACED")

  # am_insert shifts
  am_insert(doc, list_obj, 2L, "INSERTED")
  expect_equal(am_length(doc, list_obj), 3L)
  expect_equal(am_get(doc, list_obj, 2L), "INSERTED")
  expect_equal(am_get(doc, list_obj, 3L), "REPLACED")
})

test_that("am_insert() appends with 'end'", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_insert(doc, list_obj, "end", "first")
  am_insert(doc, list_obj, "end", "second")

  expect_equal(am_length(doc, list_obj), 2L)
  expect_equal(am_get(doc, list_obj, 1L), "first")
  expect_equal(am_get(doc, list_obj, 2L), "second")
})

test_that("am_insert() returns doc invisibly", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  result <- withVisible(am_insert(doc, list_obj, "end", "value"))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})

test_that("am_insert() only works on lists", {
  doc <- am_create()
  map_obj <- am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)

  expect_error(
    am_insert(doc, map_obj, 1L, "value"),
    "can only be used on list objects"
  )
})

# Type Constructors -----------------------------------------------------------

test_that("am_counter() creates counter with default value", {
  counter <- am_counter()

  expect_s3_class(counter, "am_counter")
  expect_equal(as.integer(counter), 0L)
})

test_that("am_counter() creates counter with specified value", {
  counter <- am_counter(42)

  expect_s3_class(counter, "am_counter")
  expect_equal(as.integer(counter), 42L)
})

test_that("am_counter() coerces to integer", {
  counter <- am_counter(3.7)

  expect_equal(as.integer(counter), 3L)
})

test_that("am_list() creates empty list", {
  result <- am_list()

  expect_s3_class(result, "am_list_type")
  expect_s3_class(result, "list")
  expect_length(result, 0)
})

test_that("am_list() creates list with elements", {
  result <- am_list("a", "b", "c")

  expect_s3_class(result, "am_list_type")
  expect_length(result, 3)
  expect_equal(result[[1]], "a")
  expect_equal(result[[2]], "b")
  expect_equal(result[[3]], "c")
})

test_that("am_list() handles mixed types", {
  result <- am_list(1L, "text", TRUE, 3.14)

  expect_length(result, 4)
  expect_equal(result[[1]], 1L)
  expect_equal(result[[2]], "text")
  expect_equal(result[[3]], TRUE)
  expect_equal(result[[4]], 3.14)
})

test_that("am_map() creates empty map", {
  result <- am_map()

  expect_s3_class(result, "am_map_type")
  expect_s3_class(result, "list")
  expect_length(result, 0)
})

test_that("am_map() creates map with named elements", {
  result <- am_map(key1 = "value1", key2 = "value2")

  expect_s3_class(result, "am_map_type")
  expect_length(result, 2)
  expect_equal(result$key1, "value1")
  expect_equal(result$key2, "value2")
  expect_equal(names(result), c("key1", "key2"))
})

test_that("am_map() handles mixed value types", {
  result <- am_map(int = 1L, str = "text", bool = TRUE, dbl = 3.14)

  expect_length(result, 4)
  expect_equal(result$int, 1L)
  expect_equal(result$str, "text")
  expect_equal(result$bool, TRUE)
  expect_equal(result$dbl, 3.14)
})

test_that("am_text() creates empty text object", {
  result <- am_text()

  expect_s3_class(result, "am_text_type")
  expect_s3_class(result, "character")
  expect_equal(as.character(result), "")
})

test_that("am_text() creates text with initial content", {
  result <- am_text("Hello, World!")

  expect_s3_class(result, "am_text_type")
  expect_equal(as.character(result), "Hello, World!")
})

test_that("am_text() requires scalar string", {
  expect_error(am_text(c("a", "b")), "single character string")
  expect_error(am_text(123), "single character string")
  expect_error(am_text(NULL), "single character string")
})

# Text Operations -------------------------------------------------------------

test_that("am_text_splice() inserts text", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text("Hello"))

  am_text_splice(text_obj, 5, 0, " World")

  result <- am_text_get(text_obj)
  expect_equal(result, "Hello World")
})

test_that("am_text_splice() deletes text", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text("Hello World"))

  am_text_splice(text_obj, 5, 6, "")

  result <- am_text_get(text_obj)
  expect_equal(result, "Hello")
})

test_that("am_text_splice() replaces text", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text("Hello World"))

  am_text_splice(text_obj, 6, 5, "Claude")

  result <- am_text_get(text_obj)
  expect_equal(result, "Hello Claude")
})

test_that("am_text_splice() at position 0 prepends", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text("World"))

  am_text_splice(text_obj, 0, 0, "Hello ")

  result <- am_text_get(text_obj)
  expect_equal(result, "Hello World")
})

test_that("am_text_splice() returns text_obj invisibly", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text("test"))

  result <- withVisible(am_text_splice(text_obj, 0, 0, "x"))

  expect_identical(result$value, text_obj)
  expect_false(result$visible)
})

test_that("am_text_splice() handles UTF-8 text (character indexing)", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text(""))

  am_text_splice(text_obj, 0, 0, "你好")
  char_len <- nchar("你好")  # Natural R character counting!
  am_text_splice(text_obj, char_len, 0, "世界")

  result <- am_text_get(text_obj)
  expect_equal(result, "你好世界")
})

test_that("am_text_splice() handles emoji", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text("Hello"))

  am_text_splice(text_obj, 5, 0, " 🌍")

  result <- am_text_get(text_obj)
  expect_equal(result, "Hello 🌍")
})

test_that("am_text_get() returns text from text object", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text("Test content"))

  result <- am_text_get(text_obj)

  expect_type(result, "character")
  expect_length(result, 1)
  expect_equal(result, "Test content")
})

test_that("am_text_get() returns empty string for empty text", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text())

  result <- am_text_get(text_obj)

  expect_equal(result, "")
})

test_that("text objects persist after save/load", {
  doc1 <- am_create()
  text_obj <- am_put(doc1, AM_ROOT, "doc", am_text("Original"))
  am_text_splice(text_obj, 8, 0, " Text")

  binary <- am_save(doc1)
  doc2 <- am_load(binary)

  text_obj2 <- am_get(doc2, AM_ROOT, "doc")
  result <- am_text_get(text_obj2)
  expect_equal(result, "Original Text")
})

test_that("multiple text edits accumulate correctly", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "doc", am_text(""))

  am_text_splice(text_obj, 0, 0, "The")
  am_text_splice(text_obj, 3, 0, " quick")
  am_text_splice(text_obj, 9, 0, " brown")
  am_text_splice(text_obj, 15, 0, " fox")

  result <- am_text_get(text_obj)
  expect_equal(result, "The quick brown fox")
})

# am_values() Tests -----------------------------------------------------------

test_that("am_values() returns all values from map", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  am_put(doc, AM_ROOT, "c", 3)

  values <- am_values(doc, AM_ROOT)

  expect_type(values, "list")
  expect_length(values, 3)
  expect_true(all(c(1, 2, 3) %in% values))
})

test_that("am_values() returns all values from list", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")
  am_put(doc, list_obj, "end", "third")

  values <- am_values(doc, list_obj)

  expect_type(values, "list")
  expect_length(values, 3)
  expect_equal(values[[1]], "first")
  expect_equal(values[[2]], "second")
  expect_equal(values[[3]], "third")
})

test_that("am_values() returns empty list for empty map", {
  doc <- am_create()

  values <- am_values(doc, AM_ROOT)

  expect_type(values, "list")
  expect_length(values, 0)
})

test_that("am_values() returns empty list for empty list", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  values <- am_values(doc, list_obj)

  expect_type(values, "list")
  expect_length(values, 0)
})

test_that("am_values() handles mixed types", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "int", 42L)
  am_put(doc, AM_ROOT, "str", "text")
  am_put(doc, AM_ROOT, "bool", TRUE)
  am_put(doc, AM_ROOT, "null", NULL)

  values <- am_values(doc, AM_ROOT)

  expect_length(values, 4)
  expect_true(42L %in% values)
  expect_true("text" %in% values)
  expect_true(TRUE %in% values)
})

test_that("am_values() includes nested objects", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "scalar", "value")
  nested <- am_put(doc, AM_ROOT, "nested", AM_OBJ_TYPE_MAP)

  values <- am_values(doc, AM_ROOT)

  expect_length(values, 2)
  expect_true("value" %in% values)
  expect_true(any(sapply(values, function(v) inherits(v, "am_object"))))
})

# List Edge Cases -------------------------------------------------------------

test_that("am_get() with index 0 returns NULL", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  am_put(doc, list_obj, "end", "value")

  result <- am_get(doc, list_obj, 0L)

  expect_null(result)
})

test_that("am_get() with negative index returns NULL", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  am_put(doc, list_obj, "end", "value")

  result <- am_get(doc, list_obj, -1L)

  expect_null(result)
})

test_that("am_get() with out-of-bounds index returns NULL", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  am_put(doc, list_obj, "end", "value")

  result <- am_get(doc, list_obj, 100L)

  expect_null(result)
})

test_that("am_get() on empty list returns NULL", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  result <- am_get(doc, list_obj, 1L)

  expect_null(result)
})

# Return Value Tests ----------------------------------------------------------

test_that("am_put() with scalar returns doc invisibly", {
  doc <- am_create()

  result <- withVisible(am_put(doc, AM_ROOT, "key", "value"))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})

test_that("am_put() with object type returns am_object visibly", {
  doc <- am_create()

  result <- withVisible(am_put(doc, AM_ROOT, "key", AM_OBJ_TYPE_MAP))

  expect_s3_class(result$value, "am_object")
  expect_true(result$visible)
})

test_that("am_delete() returns doc invisibly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")

  result <- withVisible(am_delete(doc, AM_ROOT, "key"))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})
