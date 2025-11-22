# Additional Edge Case Tests for Coverage

# Test various object type operations that might hit uncovered paths

test_that("operations on empty objects of various types", {
  doc <- am_create()

  # Empty map
  empty_map <- am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  expect_equal(am_length(doc, empty_map), 0)
  expect_equal(length(am_keys(doc, empty_map)), 0)

  # Empty list
  empty_list <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  expect_equal(am_length(doc, empty_list), 0)

  # Empty text
  empty_text <- am_put(doc, AM_ROOT, "text", AM_OBJ_TYPE_TEXT)
  expect_equal(am_text_get(empty_text), "")
})

test_that("operations on objects with many elements", {
  doc <- am_create()

  # Large map
  large_map <- am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  for (i in 1:100) {
    am_put(doc, large_map, paste0("key", i), i)
  }
  expect_equal(am_length(doc, large_map), 100)
  expect_equal(length(am_keys(doc, large_map)), 100)

  # Large list
  large_list <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  for (i in 1:100) {
    am_insert(doc, large_list, "end", i)
  }
  expect_equal(am_length(doc, large_list), 100)
})

test_that("text operations with various Unicode characters", {
  doc <- am_create()

  # Emoji
  text1 <- am_put(doc, AM_ROOT, "emoji", am_text("Hello 😀🎉"))
  expect_equal(am_text_get(text1), "Hello 😀🎉")

  # Various Unicode blocks
  text2 <- am_put(doc, AM_ROOT, "unicode", am_text("日本語 Ελληνικά العربية"))
  expect_equal(am_text_get(text2), "日本語 Ελληνικά العربية")

  # Text with control characters
  text3 <- am_put(doc, AM_ROOT, "control", am_text("line1\nline2\ttab"))
  expect_equal(am_text_get(text3), "line1\nline2\ttab")
})

test_that("counter operations edge cases", {
  doc <- am_create()

  # Counter with zero
  counter0 <- am_counter(0)
  am_put(doc, AM_ROOT, "c0", counter0)
  expect_equal(am_get(doc, AM_ROOT, "c0"), 0)

  # Counter with negative value
  counter_neg <- am_counter(-100)
  am_put(doc, AM_ROOT, "c_neg", counter_neg)
  expect_equal(am_get(doc, AM_ROOT, "c_neg"), -100)

  # Counter with large value
  counter_large <- am_counter(1e9)
  am_put(doc, AM_ROOT, "c_large", counter_large)
  expect_equal(am_get(doc, AM_ROOT, "c_large"), 1e9)
})

test_that("nested objects of different types", {
  doc <- am_create()

  # Map containing list containing map
  map1 <- am_put(doc, AM_ROOT, "map1", AM_OBJ_TYPE_MAP)
  list1 <- am_put(doc, map1, "list1", AM_OBJ_TYPE_LIST)
  am_insert(doc, list1, 1, AM_OBJ_TYPE_MAP)
  map2 <- am_get(doc, list1, 1)  # Get the object we just inserted
  am_put(doc, map2, "deep", "value")

  result <- am_get(doc, AM_ROOT, "map1")
  result2 <- am_get(doc, result, "list1")
  result3 <- am_get(doc, result2, 1)
  expect_equal(am_get(doc, result3, "deep"), "value")
})

test_that("delete operations on various object types", {
  doc <- am_create()

  # Delete from map
  am_put(doc, AM_ROOT, "k1", "v1")
  am_put(doc, AM_ROOT, "k2", "v2")
  am_delete(doc, AM_ROOT, "k1")
  expect_null(am_get(doc, AM_ROOT, "k1"))
  expect_equal(am_get(doc, AM_ROOT, "k2"), "v2")

  # Delete from list
  list_obj <- am_put(doc, AM_ROOT, "list", am_list("a", "b", "c"))
  am_delete(doc, list_obj, 2)
  expect_equal(am_length(doc, list_obj), 2)
})

test_that("insert at various positions in list", {
  doc <- am_create()
  list_obj <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)

  # Insert at position 1 (beginning)
  am_insert(doc, list_obj, 1, "first")
  expect_equal(am_get(doc, list_obj, 1), "first")

  # Insert at position 1 again (pushes previous down)
  am_insert(doc, list_obj, 1, "new_first")
  expect_equal(am_get(doc, list_obj, 1), "new_first")
  expect_equal(am_get(doc, list_obj, 2), "first")

  # Insert at end using "end"
  am_insert(doc, list_obj, "end", "last")
  len <- am_length(doc, list_obj)
  expect_equal(am_get(doc, list_obj, len), "last")
})

test_that("text splice at various positions", {
  doc <- am_create()
  text_obj <- am_put(doc, AM_ROOT, "text", am_text("Hello World"))

  # Splice at beginning
  am_text_splice(text_obj, 0, 0, "Greetings: ")
  expect_equal(am_text_get(text_obj), "Greetings: Hello World")

  # Splice with deletion (deletes "Greetings: " which is 11 chars)
  am_text_splice(text_obj, 0, 11, "Hi ")
  expect_equal(am_text_get(text_obj), "Hi Hello World")

  # Splice at end
  len <- nchar(am_text_get(text_obj))
  am_text_splice(text_obj, len, 0, "!")
  expect_equal(am_text_get(text_obj), "Hi Hello World!")
})

test_that("operations with special key names", {
  doc <- am_create()

  # Empty string key
  am_put(doc, AM_ROOT, "", "empty_key")
  expect_equal(am_get(doc, AM_ROOT, ""), "empty_key")

  # Very long key name
  long_key <- paste(rep("key", 1000), collapse = "_")
  am_put(doc, AM_ROOT, long_key, "value")
  expect_equal(am_get(doc, AM_ROOT, long_key), "value")

  # Keys with special characters
  am_put(doc, AM_ROOT, "key\nwith\nnewlines", "v1")
  am_put(doc, AM_ROOT, "key\twith\ttabs", "v2")
  expect_equal(am_get(doc, AM_ROOT, "key\nwith\nnewlines"), "v1")
  expect_equal(am_get(doc, AM_ROOT, "key\twith\ttabs"), "v2")
})

test_that("timestamp edge cases", {
  doc <- am_create()

  # Very old timestamp
  old_time <- as.POSIXct("1970-01-01 00:00:01", tz = "UTC")
  am_put(doc, AM_ROOT, "old", old_time)
  result <- am_get(doc, AM_ROOT, "old")
  expect_s3_class(result, "POSIXct")

  # Future timestamp
  future_time <- as.POSIXct("2099-12-31 23:59:59", tz = "UTC")
  am_put(doc, AM_ROOT, "future", future_time)
  result2 <- am_get(doc, AM_ROOT, "future")
  expect_s3_class(result2, "POSIXct")
})

test_that("raw bytes edge cases", {
  doc <- am_create()

  # Empty raw vector
  am_put(doc, AM_ROOT, "empty", raw(0))
  expect_equal(am_get(doc, AM_ROOT, "empty"), raw(0))

  # Raw with all possible byte values
  all_bytes <- as.raw(0:255)
  am_put(doc, AM_ROOT, "all", all_bytes)
  expect_equal(am_get(doc, AM_ROOT, "all"), all_bytes)

  # Large raw vector
  large_raw <- as.raw(sample(0:255, 10000, replace = TRUE))
  am_put(doc, AM_ROOT, "large", large_raw)
  expect_equal(length(am_get(doc, AM_ROOT, "large")), 10000)
})

test_that("commit with various parameters", {
  doc <- am_create()

  # Commit with no changes
  am_commit(doc)

  # Commit with message only
  am_put(doc, AM_ROOT, "k1", "v1")
  am_commit(doc, "First commit")

  # Commit with NULL message
  am_put(doc, AM_ROOT, "k2", "v2")
  am_commit(doc, NULL)

  # Commit with message and time
  am_put(doc, AM_ROOT, "k3", "v3")
  time <- Sys.time()
  am_commit(doc, "Timed commit", time)
})

test_that("fork and merge with various scenarios", {
  # Fork from empty document
  doc1 <- am_create()
  doc2 <- am_fork(doc1)
  expect_s3_class(doc2, "am_doc")

  # Fork and immediately merge back
  doc3 <- am_create()
  am_put(doc3, AM_ROOT, "x", 1)
  doc4 <- am_fork(doc3)
  am_merge(doc3, doc4)
  expect_equal(am_get(doc3, AM_ROOT, "x"), 1)

  # Multiple forks
  doc5 <- am_create()
  am_put(doc5, AM_ROOT, "base", "value")
  doc6 <- am_fork(doc5)
  doc7 <- am_fork(doc5)
  doc8 <- am_fork(doc5)

  am_put(doc6, AM_ROOT, "f1", 1)
  am_put(doc7, AM_ROOT, "f2", 2)
  am_put(doc8, AM_ROOT, "f3", 3)

  am_merge(doc5, doc6)
  am_merge(doc5, doc7)
  am_merge(doc5, doc8)

  expect_equal(am_get(doc5, AM_ROOT, "f1"), 1)
  expect_equal(am_get(doc5, AM_ROOT, "f2"), 2)
  expect_equal(am_get(doc5, AM_ROOT, "f3"), 3)
})

test_that("save and load with various document states", {
  # Empty document
  doc1 <- am_create()
  bytes1 <- am_save(doc1)
  doc1_loaded <- am_load(bytes1)
  expect_equal(am_length(doc1_loaded, AM_ROOT), 0)

  # Document with nested structures
  doc2 <- am_create()
  map <- am_put(doc2, AM_ROOT, "data", AM_OBJ_TYPE_MAP)
  list <- am_put(doc2, map, "items", AM_OBJ_TYPE_LIST)
  am_insert(doc2, list, 1, "item1")

  bytes2 <- am_save(doc2)
  doc2_loaded <- am_load(bytes2)

  map_loaded <- am_get(doc2_loaded, AM_ROOT, "data")
  list_loaded <- am_get(doc2_loaded, map_loaded, "items")
  expect_equal(am_get(doc2_loaded, list_loaded, 1), "item1")
})

test_that("keys method returns consistent results", {
  doc <- am_create()

  # Keys from empty map
  expect_equal(am_keys(doc, AM_ROOT), character(0))

  # Keys after adding and removing
  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  am_put(doc, AM_ROOT, "c", 3)
  keys1 <- am_keys(doc, AM_ROOT)
  expect_length(keys1, 3)

  am_delete(doc, AM_ROOT, "b")
  keys2 <- am_keys(doc, AM_ROOT)
  expect_length(keys2, 2)
  expect_false("b" %in% keys2)
})

test_that("length method on various object types", {
  doc <- am_create()

  # Length of root (map)
  expect_equal(am_length(doc, AM_ROOT), 0)
  am_put(doc, AM_ROOT, "k1", "v1")
  expect_equal(am_length(doc, AM_ROOT), 1)

  # Length of nested map
  map <- am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  expect_equal(am_length(doc, map), 0)
  am_put(doc, map, "nested", "value")
  expect_equal(am_length(doc, map), 1)

  # Length of list
  list <- am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  expect_equal(am_length(doc, list), 0)
  am_insert(doc, list, 1, "item")
  expect_equal(am_length(doc, list), 1)
})

test_that("actor operations", {
  # Get actor from new document
  doc1 <- am_create()
  actor1 <- am_get_actor(doc1)
  expect_type(actor1, "raw")
  expect_true(length(actor1) > 0)

  # Set actor
  new_actor <- as.raw(1:16)
  am_set_actor(doc1, new_actor)
  actor2 <- am_get_actor(doc1)
  expect_equal(actor2, new_actor)

  # Create with specific actor
  doc2 <- am_create(actor_id = as.raw(100:115))
  actor3 <- am_get_actor(doc2)
  expect_equal(actor3, as.raw(100:115))
})
