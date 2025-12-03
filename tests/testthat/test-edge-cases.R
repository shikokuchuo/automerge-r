# Additional Edge Case Tests for Coverage

# Test various object type operations that might hit uncovered paths

test_that("operations on empty objects of various types", {
  doc <- am_create()

  # Empty map
  am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  empty_map <- am_get(doc, AM_ROOT, "map")
  expect_equal(am_length(doc, empty_map), 0)
  expect_equal(length(am_keys(doc, empty_map)), 0)

  # Empty list
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  empty_list <- am_get(doc, AM_ROOT, "list")
  expect_equal(am_length(doc, empty_list), 0)

  # Empty text
  am_put(doc, AM_ROOT, "text", AM_OBJ_TYPE_TEXT)
  empty_text <- am_get(doc, AM_ROOT, "text")
  expect_equal(am_text_get(empty_text), "")
})

test_that("operations on objects with many elements", {
  doc <- am_create()

  # Large map
  am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  large_map <- am_get(doc, AM_ROOT, "map")
  for (i in 1:100) {
    am_put(doc, large_map, paste0("key", i), i)
  }
  expect_equal(am_length(doc, large_map), 100)
  expect_equal(length(am_keys(doc, large_map)), 100)

  # Large list
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  large_list <- am_get(doc, AM_ROOT, "list")
  for (i in 1:100) {
    am_insert(doc, large_list, "end", i)
  }
  expect_equal(am_length(doc, large_list), 100)
})

test_that("text operations with various Unicode characters", {
  doc <- am_create()

  # Emoji
  am_put(doc, AM_ROOT, "emoji", am_text("Hello 😀🎉"))
  text1 <- am_get(doc, AM_ROOT, "emoji")
  expect_equal(am_text_get(text1), "Hello 😀🎉")

  # Various Unicode blocks
  am_put(doc, AM_ROOT, "unicode", am_text("日本語 Ελληνικά العربية"))
  text2 <- am_get(doc, AM_ROOT, "unicode")
  expect_equal(am_text_get(text2), "日本語 Ελληνικά العربية")

  # Text with control characters
  am_put(doc, AM_ROOT, "control", am_text("line1\nline2\ttab"))
  text3 <- am_get(doc, AM_ROOT, "control")
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
  am_put(doc, AM_ROOT, "map1", AM_OBJ_TYPE_MAP)
  map1 <- am_get(doc, AM_ROOT, "map1")
  am_put(doc, map1, "list1", AM_OBJ_TYPE_LIST)
  list1 <- am_get(doc, map1, "list1")
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
  am_put(doc, AM_ROOT, "list", am_list("a", "b", "c"))
  list_obj <- am_get(doc, AM_ROOT, "list")
  am_delete(doc, list_obj, 2)
  expect_equal(am_length(doc, list_obj), 2)
})

test_that("insert at various positions in list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

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
  am_put(doc, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

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
  result1 <- am_commit(doc)
  expect_s3_class(result1, "am_doc")

  # Commit with message only
  am_put(doc, AM_ROOT, "k1", "v1")
  result2 <- am_commit(doc, "First commit")
  expect_s3_class(result2, "am_doc")

  # Commit with NULL message
  am_put(doc, AM_ROOT, "k2", "v2")
  result3 <- am_commit(doc, NULL)
  expect_s3_class(result3, "am_doc")

  # Commit with message and time
  am_put(doc, AM_ROOT, "k3", "v3")
  time <- Sys.time()
  result4 <- am_commit(doc, "Timed commit", time)
  expect_s3_class(result4, "am_doc")
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
  am_put(doc2, AM_ROOT, "data", AM_OBJ_TYPE_MAP)
  map <- am_get(doc2, AM_ROOT, "data")
  am_put(doc2, map, "items", AM_OBJ_TYPE_LIST)
  list <- am_get(doc2, map, "items")
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
  am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  map <- am_get(doc, AM_ROOT, "map")
  expect_equal(am_length(doc, map), 0)
  am_put(doc, map, "nested", "value")
  expect_equal(am_length(doc, map), 1)

  # Length of list
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list <- am_get(doc, AM_ROOT, "list")
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

# Additional coverage tests ---------------------------------------------------

# Helper to strip line numbers from C error messages
strip_line_numbers <- function(x) {
  gsub("(\\w+\\.c):[0-9]+:", "\\1:LINE:", x)
}

test_that("sync state operations with invalid pointers", {
  doc1 <- am_create()
  doc2 <- am_create()
  sync_state <- am_sync_state_new()

  # Generate a valid message
  msg <- am_sync_encode(doc1, sync_state)

  if (!is.null(msg)) {
    # Valid operation (baseline)
    am_sync_decode(doc2, sync_state, msg)
    expect_s3_class(doc2, "am_doc")
  }

  # Test with non-externalptr for sync_state
  expect_snapshot(error = TRUE, {
    am_sync_encode(doc1, "not a sync state")
  })

  expect_snapshot(error = TRUE, {
    am_sync_encode(doc1, 123)
  })

  expect_snapshot(error = TRUE, {
    am_sync_encode(doc1, list())
  })
})

test_that("sync decode with zero-length message", {
  doc <- am_create()
  sync_state <- am_sync_state_new()

  # Zero-length raw vector should trigger an error
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_sync_decode(doc, sync_state, raw(0))
  })
})

test_that("sync decode with malformed message", {
  doc <- am_create()
  sync_state <- am_sync_state_new()

  # Random bytes that aren't a valid sync message
  set.seed(123)
  bad_msg <- as.raw(sample(0:255, 50, replace = TRUE))

  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_sync_decode(doc, sync_state, bad_msg)
  })

  # Another pattern of invalid bytes
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_sync_decode(doc, sync_state, as.raw(c(0xFF, 0xFF, 0xFF)))
  })
})

test_that("am_fork with invalid heads list elements", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  # Empty list of heads (edge case - should work)
  doc2 <- am_fork(doc, heads = list())
  expect_s3_class(doc2, "am_doc")

  # List with non-raw elements
  expect_snapshot(error = TRUE, {
    am_fork(doc, heads = list(123))
  })

  expect_snapshot(error = TRUE, {
    am_fork(doc, heads = list("not raw"))
  })

  # List with mix of raw and non-raw (tests loop cleanup)
  expect_snapshot(error = TRUE, {
    am_fork(doc, heads = list(raw(32), "invalid", raw(32)))
  })
})

test_that("am_get_changes with empty list", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  # Empty list should work
  changes <- am_get_changes(doc, list())
  expect_type(changes, "list")
})

test_that("am_apply_changes with empty and invalid lists", {
  doc <- am_create()

  # Empty list of changes
  result <- am_apply_changes(doc, list())
  expect_s3_class(result, "am_doc")

  # List with non-raw elements
  expect_snapshot(error = TRUE, {
    am_apply_changes(doc, list(123))
  })

  expect_snapshot(error = TRUE, {
    am_apply_changes(doc, list("not raw"))
  })
})

test_that("am_apply_changes with malformed change data", {
  doc <- am_create()

  # Random bytes that aren't valid changes
  set.seed(456)
  bad_change <- as.raw(sample(0:255, 100, replace = TRUE))

  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_apply_changes(doc, list(bad_change))
  })
})

test_that("am_get_change_by_hash with wrong size hash", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  # Hash with 0 bytes
  expect_snapshot(error = TRUE, {
    am_get_change_by_hash(doc, raw(0))
  })

  # Hash with 31 bytes (one less than required)
  expect_snapshot(error = TRUE, {
    am_get_change_by_hash(doc, raw(31))
  })
})

test_that("operations on text objects that aren't text", {
  doc <- am_create()
  doc$list <- am_list(1, 2, 3)
  list_obj <- am_get(doc, AM_ROOT, "list")

  # am_text_get on a list returns special markers (library handles gracefully)
  result <- am_text_get(list_obj)
  # Result is non-empty string with special characters for list items
  expect_type(result, "character")
  expect_equal(length(result), 1)
})

test_that("cursor operations on non-text objects", {
  doc <- am_create()
  doc$map <- AM_OBJ_TYPE_MAP
  map_obj <- am_get(doc, AM_ROOT, "map")

  # Try to create cursor on a map (should error)
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_cursor(map_obj, 0)
  })
})

test_that("marks on non-text objects", {
  doc <- am_create()
  doc$list <- am_list(1, 2, 3)
  list_obj <- am_get(doc, AM_ROOT, "list")

  # Try to create marks on a list (should error)
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_mark_create(list_obj, 0, 2, "bold", TRUE)
  })

  # Query marks on a list returns empty list (library handles gracefully)
  result <- am_marks_at(list_obj, 0)
  expect_equal(result, list())
})

test_that("am_put with very large list position", {
  doc <- am_create()
  doc$items <- am_list(1, 2, 3)
  items <- am_get(doc, AM_ROOT, "items")

  # Extremely large positions error - library validates bounds
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_put(doc, items, 10000, "last")
  })
})

test_that("am_delete with out-of-bounds list position", {
  doc <- am_create()
  doc$items <- am_list("a", "b", "c")
  items <- am_get(doc, AM_ROOT, "items")

  # Delete position 10 (out of bounds) - should error
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_delete(doc, items, 10)
  })
})

test_that("text operations at boundary positions", {
  doc <- am_create()
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Position 5 is valid (at end of "Hello")
  am_text_splice(text_obj, 5, 0, " World")
  expect_equal(am_text_get(text_obj), "Hello World")

  # Delete beyond text length is handled gracefully - deletes to end
  am_text_splice(text_obj, 0, 1000, "New")
  expect_equal(am_text_get(text_obj), "New")
})

test_that("cursor at boundary and beyond", {
  doc <- am_create()
  doc$text <- am_text("Test")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Position 0 (before first character)
  cursor0 <- am_cursor(text_obj, 0)
  expect_equal(am_cursor_position(cursor0), 0)

  # Position 3 (within text bounds)
  cursor3 <- am_cursor(text_obj, 3)
  expect_equal(am_cursor_position(cursor3), 3)

  # Position at end of text (length) errors - cursors must be < length
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_cursor(text_obj, 4)
  })

  # Beyond text length also errors
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_cursor(text_obj, 1000)
  })
})

test_that("marks at boundary and beyond", {
  doc <- am_create()
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark from 0 to 5 (entire text)
  am_mark_create(text_obj, 0, 5, "style", "bold")
  marks <- am_marks_at(text_obj, 2)
  expect_true(length(marks) > 0)

  # Query marks at position 5 (after last character)
  marks_end <- am_marks_at(text_obj, 5)
  expect_type(marks_end, "list")

  # Marks beyond text length (should error)
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_mark_create(text_obj, 0, 1000, "invalid", "value")
  })
})

test_that("counter increment on non-existent keys", {
  doc <- am_create()

  # Incrementing non-existent counter - should error
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_counter_increment(doc, AM_ROOT, "nonexistent", 1)
  })
})

test_that("counter increment with fractional delta", {
  doc <- am_create()
  doc$counter <- am_counter(0)

  # Counter deltas are integers - fractional values are truncated
  # 0.5 becomes 0
  am_counter_increment(doc, AM_ROOT, "counter", 0.5)
  result <- am_get(doc, AM_ROOT, "counter")
  expect_equal(result, 0)

  # Increment with whole number
  am_counter_increment(doc, AM_ROOT, "counter", 5)
  result2 <- am_get(doc, AM_ROOT, "counter")
  expect_equal(result2, 5)

  # Negative deltas work
  am_counter_increment(doc, AM_ROOT, "counter", -3)
  result3 <- am_get(doc, AM_ROOT, "counter")
  expect_equal(result3, 2)
})

test_that("counter in empty list", {
  doc <- am_create()
  doc$counters <- AM_OBJ_TYPE_LIST
  counters <- am_get(doc, AM_ROOT, "counters")

  # Try to increment counter at position 1 in empty list
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_counter_increment(doc, counters, 1, 1)
  })
})

test_that("operations on forked documents with specific heads", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  # Fork at specific heads
  heads <- am_get_heads(doc1)
  doc2 <- am_fork(doc1, heads = heads)
  expect_s3_class(doc2, "am_doc")

  # Verify forked doc has the data
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)

  # Make changes in both
  doc1$y <- 2
  doc2$z <- 3

  # Merge
  am_merge(doc1, doc2)
  expect_equal(am_get(doc1, AM_ROOT, "z"), 3)
})

test_that("create with various actor ID types", {
  # Raw actor ID (16 bytes)
  actor_raw <- as.raw(1:16)
  doc1 <- am_create(actor_id = actor_raw)
  expect_equal(am_get_actor(doc1), actor_raw)

  # NULL actor ID (random)
  doc2 <- am_create(actor_id = NULL)
  actor2 <- am_get_actor(doc2)
  expect_type(actor2, "raw")
  expect_true(length(actor2) > 0)

  # String actor ID must be valid hex format
  # Get hex representation from a valid actor
  hex_str <- paste0(as.character(actor_raw), collapse = "")
  # Actually, need proper hex format like "01020304..."
  hex_valid <- paste(sprintf("%02x", as.integer(actor_raw)), collapse = "")
  doc3 <- am_create(actor_id = hex_valid)
  actor3 <- am_get_actor(doc3)
  expect_type(actor3, "raw")

  # Invalid hex string errors
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_create(actor_id = "not-valid-hex")
  })
})

test_that("sync between empty documents", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Sync two empty documents
  am_sync(doc1, doc2)

  expect_equal(am_length(doc1, AM_ROOT), 0)
  expect_equal(am_length(doc2, AM_ROOT), 0)
})

test_that("sync state lifecycle", {
  # Create sync state
  state1 <- am_sync_state_new()
  expect_s3_class(state1, "am_syncstate")

  # Use it multiple times
  doc1 <- am_create()
  doc1$x <- 1
  doc2 <- am_create()

  msg1 <- am_sync_encode(doc1, state1)
  if (!is.null(msg1)) {
    am_sync_decode(doc2, state1, msg1)
  }

  # Create another state
  state2 <- am_sync_state_new()
  msg2 <- am_sync_encode(doc2, state2)
  if (!is.null(msg2)) {
    am_sync_decode(doc1, state2, msg2)
  }
})

test_that("sync with malformed state pointer", {
  doc <- am_create()

  # Pass wrong type as sync state
  expect_snapshot(error = TRUE, {
    am_sync_encode(doc, list())
  })

  expect_snapshot(error = TRUE, {
    am_sync_encode(doc, raw(10))
  })
})

test_that("deeply nested structures", {
  doc <- am_create()

  # Create 10 levels of nesting
  doc$level1 <- AM_OBJ_TYPE_MAP
  current <- am_get(doc, AM_ROOT, "level1")

  for (i in 2:10) {
    am_put(doc, current, paste0("level", i), AM_OBJ_TYPE_MAP)
    current <- am_get(doc, current, paste0("level", i))
  }

  # Put value at deepest level
  am_put(doc, current, "deep_value", "found it!")

  # Retrieve through the chain
  obj <- am_get(doc, AM_ROOT, "level1")
  for (i in 2:10) {
    obj <- am_get(doc, obj, paste0("level", i))
  }
  result <- am_get(doc, obj, "deep_value")
  expect_equal(result, "found it!")
})

test_that("wide structures with many siblings", {
  doc <- am_create()

  # Create a map with 1000 keys
  doc$wide <- AM_OBJ_TYPE_MAP
  wide <- am_get(doc, AM_ROOT, "wide")

  for (i in 1:1000) {
    am_put(doc, wide, paste0("key", i), i)
  }

  # Verify all keys exist
  keys <- am_keys(doc, wide)
  expect_equal(length(keys), 1000)

  # Spot check some values
  expect_equal(am_get(doc, wide, "key1"), 1)
  expect_equal(am_get(doc, wide, "key500"), 500)
  expect_equal(am_get(doc, wide, "key1000"), 1000)
})

test_that("mixed type structures", {
  doc <- am_create()

  # Create a structure with all types
  doc$all_types <- am_map(
    string = "text",
    number = 42,
    boolean = TRUE,
    null = NULL,
    raw = raw(5),
    timestamp = Sys.time(),
    counter = am_counter(10),
    list = am_list(1, 2, 3),
    map = am_map(nested = "value"),
    text = am_text("Hello")
  )

  all_types <- am_get(doc, AM_ROOT, "all_types")

  # Verify each type
  expect_equal(am_get(doc, all_types, "string"), "text")
  expect_equal(am_get(doc, all_types, "number"), 42)
  expect_equal(am_get(doc, all_types, "boolean"), TRUE)
  expect_null(am_get(doc, all_types, "null"))
  expect_type(am_get(doc, all_types, "raw"), "raw")
  expect_s3_class(am_get(doc, all_types, "timestamp"), "POSIXct")
  expect_equal(am_get(doc, all_types, "counter"), 10)
})

test_that("multiple rapid commits", {
  doc <- am_create()

  # Make 100 rapid commits
  for (i in 1:100) {
    doc[[paste0("k", i)]] <- i
    am_commit(doc, paste("Commit", i))
  }

  # Verify final state
  expect_equal(am_get(doc, AM_ROOT, "k50"), 50)
  expect_equal(am_get(doc, AM_ROOT, "k100"), 100)
})

test_that("commit with very long message", {
  doc <- am_create()
  doc$x <- 1

  # Very long commit message
  long_msg <- paste(rep("Lorem ipsum dolor sit amet", 1000), collapse = " ")
  result <- am_commit(doc, long_msg)
  expect_s3_class(result, "am_doc")
})

test_that("NA values of different types", {
  doc <- am_create()

  # NA integer
  doc$na_int <- NA_integer_
  expect_true(is.na(am_get(doc, AM_ROOT, "na_int")))

  # NA real
  doc$na_real <- NA_real_
  expect_true(is.na(am_get(doc, AM_ROOT, "na_real")))

  # NA character
  doc$na_char <- NA_character_
  result <- am_get(doc, AM_ROOT, "na_char")
  expect_true(is.na(result) || result == "NA")
})

test_that("Inf and -Inf values", {
  doc <- am_create()

  # Positive infinity
  doc$pos_inf <- Inf
  result1 <- am_get(doc, AM_ROOT, "pos_inf")
  expect_equal(result1, Inf)

  # Negative infinity
  doc$neg_inf <- -Inf
  result2 <- am_get(doc, AM_ROOT, "neg_inf")
  expect_equal(result2, -Inf)
})

test_that("very large and very small numbers", {
  doc <- am_create()

  # Very large number
  doc$large <- 1.7976931348623157e+308
  expect_equal(am_get(doc, AM_ROOT, "large"), 1.7976931348623157e+308)

  # Very small positive number
  doc$small <- 2.225074e-308
  expect_equal(am_get(doc, AM_ROOT, "small"), 2.225074e-308)

  # Very small negative number
  doc$neg_small <- -2.225074e-308
  expect_equal(am_get(doc, AM_ROOT, "neg_small"), -2.225074e-308)
})

test_that("special string values", {
  doc <- am_create()

  # Empty string
  doc$empty <- ""
  expect_equal(am_get(doc, AM_ROOT, "empty"), "")

  # Very long string
  long_str <- paste(rep("a", 100000), collapse = "")
  doc$long <- long_str
  result <- am_get(doc, AM_ROOT, "long")
  expect_equal(nchar(result), 100000)

  # String with only spaces
  doc$spaces <- "     "
  expect_equal(am_get(doc, AM_ROOT, "spaces"), "     ")
})

# Additional targeted tests for uncovered error paths --------------------------

test_that("malformed change hashes in fork heads", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  # List with invalid hash (wrong format) - exercises convert_r_heads_to_amresult error path
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_fork(doc, heads = list(raw(5)))  # Too short, invalid hash
  })

  # Another invalid hash format
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_fork(doc, heads = list(as.raw(1:50)))  # Wrong size
  })
})

test_that("invalid change data structures", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  # Get valid changes
  doc2 <- am_create()
  changes <- am_get_changes(doc1, list())

  # Apply valid changes (baseline)
  am_apply_changes(doc2, changes)
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)

  # Test that changes have expected structure
  expect_true(length(changes) > 0)
  expect_type(changes[[1]], "raw")

  # Applying same changes again is idempotent (no error)
  am_apply_changes(doc2, changes)
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)
})

test_that("sync with corrupted message state", {
  doc1 <- am_create()
  doc1$data <- "test"
  doc2 <- am_create()
  sync_state <- am_sync_state_new()

  # Generate valid message
  msg <- am_sync_encode(doc1, sync_state)

  if (!is.null(msg) && length(msg) > 10) {
    # Corrupt the message
    bad_msg <- msg
    bad_msg[1] <- as.raw(0)  # Corrupt header

    expect_snapshot(error = TRUE, transform = strip_line_numbers, {
      am_sync_decode(doc2, sync_state, bad_msg)
    })
  }
})

test_that("operations with invalid change hashes", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  # Get changes with invalid hash format
  expect_snapshot(error = TRUE, {
    am_get_changes(doc, list(raw(5)))  # Invalid hash size
  })

  expect_snapshot(error = TRUE, {
    am_get_changes(doc, list(as.raw(1:50)))  # Invalid hash size
  })
})

test_that("memory allocation stress test", {
  doc <- am_create()

  # Create many nested objects to stress memory allocation paths
  for (i in 1:50) {
    doc[[paste0("map", i)]] <- AM_OBJ_TYPE_MAP
    map_obj <- am_get(doc, AM_ROOT, paste0("map", i))
    for (j in 1:20) {
      am_put(doc, map_obj, paste0("key", j), paste0("value", i, "_", j))
    }
  }

  # Verify structure survives
  map25 <- am_get(doc, AM_ROOT, "map25")
  expect_equal(am_get(doc, map25, "key10"), "value25_10")

  # Save and load to exercise serialization paths
  bytes <- am_save(doc)
  doc_loaded <- am_load(bytes)
  map25_loaded <- am_get(doc_loaded, AM_ROOT, "map25")
  expect_equal(am_get(doc_loaded, map25_loaded, "key10"), "value25_10")
})

test_that("text operations with empty text objects", {
  doc <- am_create()
  doc$text <- am_text("")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Empty text has no valid cursor positions (length is 0)
  # Cursor requires position < length, so empty text cannot have cursors
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_cursor(text_obj, 0)
  })

  # Marks at position 0 in empty text
  marks <- am_marks_at(text_obj, 0)
  expect_equal(marks, list())

  # Splice into empty text
  am_text_splice(text_obj, 0, 0, "Hello")
  expect_equal(am_text_get(text_obj), "Hello")

  # Now cursor works with non-empty text
  cursor <- am_cursor(text_obj, 0)
  expect_equal(am_cursor_position(cursor), 0)
})

test_that("counter operations on various object types", {
  doc <- am_create()

  # Counter in map
  doc$counter_map <- AM_OBJ_TYPE_MAP
  map_obj <- am_get(doc, AM_ROOT, "counter_map")
  am_put(doc, map_obj, "count", am_counter(10))
  am_counter_increment(doc, map_obj, "count", 5)
  expect_equal(am_get(doc, map_obj, "count"), 15)

  # Counter in list
  doc$counter_list <- am_list(am_counter(1), am_counter(2))
  list_obj <- am_get(doc, AM_ROOT, "counter_list")
  am_counter_increment(doc, list_obj, 1, 10)
  expect_equal(am_get(doc, list_obj, 1), 11)

  # Incrementing with very large values
  am_counter_increment(doc, list_obj, 1, 1000000)
  expect_equal(am_get(doc, list_obj, 1), 1000011)
})

test_that("boundary conditions for marks", {
  doc <- am_create()
  doc$text <- am_text("Hello World")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark at start
  am_mark_create(text_obj, 0, 1, "first", TRUE)
  marks_0 <- am_marks_at(text_obj, 0)
  expect_true(length(marks_0) > 0)

  # Mark at end (position 11 is at end of "Hello World")
  marks_11 <- am_marks_at(text_obj, 11)
  expect_type(marks_11, "list")

  # Overlapping marks
  am_mark_create(text_obj, 0, 5, "bold", TRUE)
  am_mark_create(text_obj, 3, 8, "italic", TRUE)
  marks_4 <- am_marks_at(text_obj, 4)
  expect_true(length(marks_4) >= 2)  # Should have both marks
})

test_that("operations after merge conflicts", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  doc2 <- am_fork(doc1)

  # Create conflict - both modify same key
  doc1$x <- "version1"
  am_commit(doc1)

  doc2$x <- "version2"
  am_commit(doc2)

  # Merge creates conflict state
  am_merge(doc1, doc2)

  # Document should still be usable
  doc1$y <- "new_value"
  expect_equal(am_get(doc1, AM_ROOT, "y"), "new_value")

  # Can still save and load
  bytes <- am_save(doc1)
  doc_loaded <- am_load(bytes)
  expect_equal(am_get(doc_loaded, AM_ROOT, "y"), "new_value")
})

test_that("insert at beginning and end of lists", {
  doc <- am_create()
  doc$list <- AM_OBJ_TYPE_LIST
  list_obj <- am_get(doc, AM_ROOT, "list")

  # Insert at position 1 (empty list)
  am_insert(doc, list_obj, 1, "first")
  expect_equal(am_get(doc, list_obj, 1), "first")

  # Insert at position 1 again (beginning)
  am_insert(doc, list_obj, 1, "new_first")
  expect_equal(am_get(doc, list_obj, 1), "new_first")
  expect_equal(am_get(doc, list_obj, 2), "first")

  # Insert at end
  am_insert(doc, list_obj, "end", "last")
  len <- am_length(doc, list_obj)
  expect_equal(am_get(doc, list_obj, len), "last")

  # Insert in middle
  am_insert(doc, list_obj, 2, "middle")
  expect_equal(am_get(doc, list_obj, 2), "middle")
})

test_that("fork with multiple concurrent changes", {
  doc1 <- am_create()
  doc1$base <- "value"
  am_commit(doc1)

  # Create multiple forks
  doc2 <- am_fork(doc1)
  doc3 <- am_fork(doc1)
  doc4 <- am_fork(doc1)

  # Each makes different changes
  doc2$a <- 1
  doc3$b <- 2
  doc4$c <- 3

  # Merge all back to doc1
  am_merge(doc1, doc2)
  am_merge(doc1, doc3)
  am_merge(doc1, doc4)

  # All changes should be present
  expect_equal(am_get(doc1, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc1, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc1, AM_ROOT, "c"), 3)
  expect_equal(am_get(doc1, AM_ROOT, "base"), "value")
})

test_that("large text operations", {
  doc <- am_create()

  # Create text with 10000 characters
  large_text <- paste(rep("a", 10000), collapse = "")
  doc$text <- am_text(large_text)
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Verify length
  result <- am_text_get(text_obj)
  expect_equal(nchar(result), 10000)

  # Splice in middle
  am_text_splice(text_obj, 5000, 0, "INSERTED")
  result2 <- am_text_get(text_obj)
  expect_equal(nchar(result2), 10008)

  # Delete large chunk
  am_text_splice(text_obj, 1000, 8000, "")
  result3 <- am_text_get(text_obj)
  expect_equal(nchar(result3), 2008)
})

test_that("deeply nested get operations", {
  doc <- am_create()

  # Build deep structure: root -> l1 -> l2 -> l3 -> l4 -> l5
  doc$l1 <- AM_OBJ_TYPE_MAP
  l1 <- am_get(doc, AM_ROOT, "l1")
  am_put(doc, l1, "l2", AM_OBJ_TYPE_MAP)
  l2 <- am_get(doc, l1, "l2")
  am_put(doc, l2, "l3", AM_OBJ_TYPE_MAP)
  l3 <- am_get(doc, l2, "l3")
  am_put(doc, l3, "l4", AM_OBJ_TYPE_MAP)
  l4 <- am_get(doc, l3, "l4")
  am_put(doc, l4, "l5", AM_OBJ_TYPE_MAP)
  l5 <- am_get(doc, l4, "l5")
  am_put(doc, l5, "deep", "found")

  # Retrieve step by step
  result <- am_get(doc, AM_ROOT, "l1")
  result <- am_get(doc, result, "l2")
  result <- am_get(doc, result, "l3")
  result <- am_get(doc, result, "l4")
  result <- am_get(doc, result, "l5")
  result <- am_get(doc, result, "deep")

  expect_equal(result, "found")
})
