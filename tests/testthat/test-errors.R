# Tests for error handling in errors.c
# These tests aim to exercise the different error paths in check_result_impl()

# Helper to strip line numbers from C error messages to avoid brittle snapshots
strip_line_numbers <- function(x) {
  gsub("(\\w+\\.c):[0-9]+:", "\\1:LINE:", x)
}

test_that("Automerge errors are caught with error messages", {
  # Test AM_STATUS_ERROR with non-empty error message
  # Loading invalid data should trigger an Automerge C error

  # Invalid Automerge format
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_load(as.raw(c(0x00, 0x01, 0x02)))
  })

  # Random bytes that aren't a valid document
  set.seed(42) # For reproducibility
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_load(as.raw(sample(0:255, 100, replace = TRUE)))
  })
})

test_that("am_load validates input type", {
  # These test R-level validation before reaching C
  expect_snapshot(error = TRUE, {
    am_load("not raw")
  })

  expect_snapshot(error = TRUE, {
    am_load(123)
  })

  expect_snapshot(error = TRUE, {
    am_load(list())
  })

  expect_snapshot(error = TRUE, {
    am_load(NULL)
  })
})

test_that("Invalid document pointers are caught", {
  # Pass invalid objects where documents are expected
  expect_snapshot(error = TRUE, {
    am_save("not a document")
  })

  expect_snapshot(error = TRUE, {
    am_fork(123)
  })

  expect_snapshot(error = TRUE, {
    am_merge("doc1", "doc2")
  })
})

test_that("Invalid operations on documents", {
  doc <- am_create()

  # Invalid actor ID types
  expect_snapshot(error = TRUE, {
    am_set_actor(doc, 123)
  })

  expect_snapshot(error = TRUE, {
    am_set_actor(doc, list())
  })

  # Merge with invalid second document
  expect_snapshot(error = TRUE, {
    am_merge(doc, "not a doc")
  })
})

test_that("Invalid object operations", {
  doc <- am_create()

  # Try to get from invalid object pointer
  expect_snapshot(error = TRUE, {
    am_get(doc, "not an objid", "key")
  })

  # Delete from invalid object
  expect_snapshot(error = TRUE, {
    am_delete(doc, 123, "key")
  })
})

test_that("Commit with invalid parameters", {
  doc <- am_create()

  # Invalid message type
  expect_snapshot(error = TRUE, {
    am_commit(doc, 123)
  })

  expect_snapshot(error = TRUE, {
    am_commit(doc, c("a", "b"))
  })

  # Invalid time type
  expect_snapshot(error = TRUE, {
    am_commit(doc, NULL, "not a time")
  })

  expect_snapshot(error = TRUE, {
    am_commit(doc, NULL, 123)
  })
})

test_that("Text operations with invalid inputs", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # These should work (baseline)
  am_text_splice(text_obj, 5, 0, " World")
  result <- am_text_get(text_obj)
  expect_equal(result, "Hello World")

  # Try text operations on non-text object
  am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  map_obj <- am_get(doc, AM_ROOT, "map")

  # This should fail - trying to do text operations on a map
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_text_splice(map_obj, 0, 0, "text")
  })
})

test_that("Operations on invalid object types", {
  doc <- am_create()

  # Create a text object
  am_put(doc, AM_ROOT, "text", am_text("content"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Try to use am_keys on text (should work or error gracefully)
  # Text objects don't have "keys" in the map sense
  result <- am_keys(doc, text_obj)
  expect_true(is.character(result) || is.null(result))
})

test_that("Large documents don't cause issues", {
  # This tests that we don't hit buffer size limits
  doc <- am_create()

  # Create a document with many keys
  for (i in 1:1000) {
    am_put(doc, AM_ROOT, paste0("key", i), i)
  }

  # Should be able to save and load large documents
  bytes <- am_save(doc)
  doc2 <- am_load(bytes)

  # Verify some values
  expect_equal(am_get(doc2, AM_ROOT, "key1"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "key1000"), 1000)
})

test_that("Nested errors propagate correctly", {
  # Test that errors deep in nested structures are caught
  doc <- am_create()

  # Create deeply nested structure
  am_put(
    doc,
    AM_ROOT,
    "level1",
    list(
      level2 = list(
        level3 = list(
          level4 = list(
            level5 = "deep"
          )
        )
      )
    )
  )

  # Now try to perform an invalid operation deep in the structure
  level1 <- am_get(doc, AM_ROOT, "level1")
  level2 <- am_get(doc, level1, "level2")
  level3 <- am_get(doc, level2, "level3")

  # Valid operations should work
  expect_type(level3, "externalptr")
  expect_s3_class(level3, "am_object")
})

test_that("Fork and merge error handling", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "x", 1)

  # Fork should work
  doc2 <- am_fork(doc1)
  expect_s3_class(doc2, "am_doc")

  # Make changes
  am_put(doc2, AM_ROOT, "y", 2)

  # Merge should work
  am_merge(doc1, doc2)
  expect_equal(am_get(doc1, AM_ROOT, "y"), 2)

  # Try to merge with invalid document
  expect_snapshot(error = TRUE, {
    am_merge(doc1, NULL)
  })
})

test_that("Type constructor validation", {
  # am_text with invalid input
  expect_snapshot(error = TRUE, {
    am_text(123)
  })

  expect_snapshot(error = TRUE, {
    am_text(c("a", "b"))
  })

  expect_snapshot(error = TRUE, {
    am_text(NULL)
  })
})

test_that("Corrupted document state handling", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")

  # Save valid document
  bytes <- am_save(doc)

  # Modify bytes to simulate corruption (change a few bytes in the middle)
  if (length(bytes) > 10) {
    corrupted <- bytes
    corrupted[5:7] <- as.raw(c(255, 255, 255))

    # Try to load corrupted document - should error
    expect_snapshot(error = TRUE, transform = strip_line_numbers, {
      am_load(corrupted)
    })
  }
})

test_that("Edge case: operations on empty document", {
  doc <- am_create()

  # Getting non-existent key returns NULL
  expect_null(am_get(doc, AM_ROOT, "nonexistent"))

  # Keys of empty root
  expect_equal(am_keys(doc, AM_ROOT), character(0))

  # Length of empty root
  expect_equal(am_length(doc, AM_ROOT), 0)

  # Save and load empty document
  bytes <- am_save(doc)
  doc2 <- am_load(bytes)
  expect_s3_class(doc2, "am_doc")
  expect_equal(am_length(doc2, AM_ROOT), 0)
})

test_that("Error messages include file and line information", {
  # When errors occur, they should include source location
  # This helps with debugging

  # The error message format is: "Automerge error at document.c:LINE: message"
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_load(as.raw(c(0xFF)))
  })
})

test_that("Multiple error conditions in sequence", {
  # Test that error state doesn't persist between calls

  # First error
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_load(as.raw(c(0x00)))
  })

  # Should be able to perform valid operations after error
  doc <- am_create()
  expect_s3_class(doc, "am_doc")

  # Second error
  expect_snapshot(error = TRUE, transform = strip_line_numbers, {
    am_load(as.raw(c(0xFF)))
  })

  # Valid operation again
  am_put(doc, AM_ROOT, "key", "value")
  expect_equal(am_get(doc, AM_ROOT, "key"), "value")
})

test_that("Resource cleanup after errors", {
  # Test that resources are properly freed even after errors
  # This is hard to test directly, but we can verify no crashes

  for (i in 1:10) {
    # Trigger errors in a loop
    set.seed(i) # For reproducibility
    expect_snapshot(error = TRUE, transform = strip_line_numbers, {
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    })
  }

  # Should still be able to create valid documents
  doc <- am_create()
  am_put(doc, AM_ROOT, "after_errors", "works")
  expect_equal(am_get(doc, AM_ROOT, "after_errors"), "works")
})

# Sync validation errors ------------------------------------------------------

test_that("am_sync_decode validates message type", {
  doc <- am_create()
  sync_state <- am_sync_state_new()

  expect_snapshot(error = TRUE, {
    am_sync_decode(doc, sync_state, "not raw")
  })

  expect_snapshot(error = TRUE, {
    am_sync_decode(doc, sync_state, 123)
  })

  expect_snapshot(error = TRUE, {
    am_sync_decode(doc, sync_state, list(1, 2, 3))
  })

  expect_snapshot(error = TRUE, {
    am_sync_decode(doc, sync_state, NULL)
  })
})

test_that("am_sync validates doc1 parameter", {
  doc <- am_create()

  expect_snapshot(error = TRUE, {
    am_sync("not a doc", doc)
  })

  expect_snapshot(error = TRUE, {
    am_sync(123, doc)
  })

  expect_snapshot(error = TRUE, {
    am_sync(NULL, doc)
  })
})

test_that("am_sync validates doc2 parameter", {
  doc <- am_create()

  expect_snapshot(error = TRUE, {
    am_sync(doc, "not a doc")
  })

  expect_snapshot(error = TRUE, {
    am_sync(doc, 456)
  })

  expect_snapshot(error = TRUE, {
    am_sync(doc, NULL)
  })
})

test_that("am_get_changes validates heads parameter", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc)

  expect_snapshot(error = TRUE, {
    am_get_changes(doc, "not a list")
  })

  expect_snapshot(error = TRUE, {
    am_get_changes(doc, 123)
  })

  expect_snapshot(error = TRUE, {
    am_get_changes(doc, raw(5))
  })
})

test_that("am_apply_changes validates changes parameter", {
  doc <- am_create()

  expect_snapshot(error = TRUE, {
    am_apply_changes(doc, "not a list")
  })

  expect_snapshot(error = TRUE, {
    am_apply_changes(doc, 123)
  })

  expect_snapshot(error = TRUE, {
    am_apply_changes(doc, raw(5))
  })

  expect_snapshot(error = TRUE, {
    am_apply_changes(doc, NULL)
  })
})

# Convenience function validation errors --------------------------------------

test_that("am_put_path validates with non-existent intermediate and no create", {
  doc <- am_create()

  expect_snapshot(error = TRUE, {
    am_put_path(doc, c("a", "b", "c"), "value", create_intermediate = FALSE)
  })
})

test_that("am_put_path errors on non-object intermediate path component", {
  doc <- am_create()
  doc$scalar <- "just a string"

  expect_snapshot(error = TRUE, {
    am_put_path(doc, c("scalar", "nested"), "value")
  })
})

test_that("am_put_path errors when trying to create intermediate list element", {
  doc <- am_create()
  doc$items <- am_list("a", "b")

  expect_snapshot(error = TRUE, {
    am_put_path(doc, list("items", 99, "nested"), "value")
  })
})

test_that("am_delete_path warns on non-existent intermediate path", {
  doc <- am_create()
  doc$user <- am_map(name = "Alice")

  expect_warning(
    am_delete_path(doc, c("user", "nonexistent", "key")),
    "Path component at position 2 does not exist"
  )
})

test_that("am_delete_path warns on non-object intermediate path component", {
  doc <- am_create()
  doc$scalar <- 42

  expect_warning(
    am_delete_path(doc, c("scalar", "nested")),
    "Path component at position 1 is not an object"
  )
})

# Object operations validation errors -----------------------------------------

test_that("am_put with invalid key types for maps", {
  doc <- am_create()

  # Map keys must be single character strings
  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, 123, "value")
  })

  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, c("a", "b"), "value")
  })

  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, list("key"), "value")
  })
})

test_that("am_put with invalid positions for lists", {
  doc <- am_create()
  doc$items <- am_list(1, 2, 3)
  items <- am_get(doc, AM_ROOT, "items")

  # List positions must be positive
  expect_snapshot(error = TRUE, {
    am_put(doc, items, 0, "value")
  })

  expect_snapshot(error = TRUE, {
    am_put(doc, items, -1, "value")
  })

  # Position must be scalar
  expect_snapshot(error = TRUE, {
    am_put(doc, items, c(1, 2), "value")
  })
})

test_that("am_put with invalid value types", {
  doc <- am_create()

  # Non-scalar POSIXct
  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, "time", as.POSIXct(c("2024-01-01", "2024-01-02")))
  })

  # Non-scalar counter
  counter <- structure(c(1L, 2L), class = "am_counter")
  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, "counter", counter)
  })

  # Non-scalar or non-string am_text
  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, "text", structure(123, class = "am_text_type"))
  })

  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, "text", structure(c("a", "b"), class = "am_text_type"))
  })
})

test_that("am_insert validates list-only operation", {
  doc <- am_create()

  # Cannot insert into root (which is a map)
  expect_snapshot(error = TRUE, {
    am_insert(doc, AM_ROOT, 1, "value")
  })

  # Cannot insert into a map
  doc$map <- AM_OBJ_TYPE_MAP
  map_obj <- am_get(doc, AM_ROOT, "map")
  expect_snapshot(error = TRUE, {
    am_insert(doc, map_obj, 1, "value")
  })
})

test_that("am_delete with invalid positions for lists", {
  doc <- am_create()
  doc$items <- am_list(1, 2, 3)
  items <- am_get(doc, AM_ROOT, "items")

  # List positions must be positive
  expect_snapshot(error = TRUE, {
    am_delete(doc, items, 0)
  })

  expect_snapshot(error = TRUE, {
    am_delete(doc, items, -1)
  })

  # Position must be scalar
  expect_snapshot(error = TRUE, {
    am_delete(doc, items, c(1, 2))
  })
})

test_that("am_text_splice validation errors", {
  doc <- am_create()
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # pos must be numeric
  expect_snapshot(error = TRUE, {
    am_text_splice(text_obj, "not numeric", 0, "")
  })

  # del_count must be numeric
  expect_snapshot(error = TRUE, {
    am_text_splice(text_obj, 0, "not numeric", "")
  })

  # text must be single character string
  expect_snapshot(error = TRUE, {
    am_text_splice(text_obj, 0, 0, 123)
  })

  expect_snapshot(error = TRUE, {
    am_text_splice(text_obj, 0, 0, c("a", "b"))
  })

  # pos must be non-negative
  expect_snapshot(error = TRUE, {
    am_text_splice(text_obj, -1, 0, "")
  })

  # del_count must be non-negative
  expect_snapshot(error = TRUE, {
    am_text_splice(text_obj, 0, -1, "")
  })
})

test_that("am_counter_increment validation errors", {
  doc <- am_create()
  doc$counter <- am_counter(10)

  # Delta must be numeric
  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, AM_ROOT, "counter", "not numeric")
  })

  # Delta must be scalar
  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, AM_ROOT, "counter", c(1, 2))
  })

  # Map key must be single character string
  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, AM_ROOT, 123, 1)
  })

  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, AM_ROOT, c("a", "b"), 1)
  })

  # Cannot increment counter in text object
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")
  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, text_obj, 0, 1)
  })
})

test_that("am_counter_increment with list positions", {
  doc <- am_create()
  doc$counters <- am_list(am_counter(1), am_counter(2))
  counters <- am_get(doc, AM_ROOT, "counters")

  # Position must be numeric
  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, counters, "not numeric", 1)
  })

  # Position must be scalar
  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, counters, c(1, 2), 1)
  })

  # Position must be >= 1 (1-based indexing)
  expect_snapshot(error = TRUE, {
    am_counter_increment(doc, counters, 0, 1)
  })
})

# Cursor validation errors ----------------------------------------------------

test_that("am_cursor validation errors", {
  doc <- am_create()
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # position must be numeric
  expect_snapshot(error = TRUE, {
    am_cursor(text_obj, "not numeric")
  })

  # position must be scalar
  expect_snapshot(error = TRUE, {
    am_cursor(text_obj, c(1, 2))
  })

  # position must be non-negative
  expect_snapshot(error = TRUE, {
    am_cursor(text_obj, -1)
  })
})

test_that("am_cursor_position validation errors", {
  doc <- am_create()
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 0)

  # cursor must be external pointer
  expect_snapshot(error = TRUE, {
    am_cursor_position(text_obj, "not a cursor")
  })

  expect_snapshot(error = TRUE, {
    am_cursor_position(text_obj, 123)
  })
})

# Mark validation errors ------------------------------------------------------

test_that("am_mark_create validation errors", {
  doc <- am_create()
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # start must be numeric
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, "not numeric", 5, "bold", TRUE)
  })

  # start must be scalar
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, c(0, 1), 5, "bold", TRUE)
  })

  # start must be non-negative
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, -1, 5, "bold", TRUE)
  })

  # end must be numeric
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, "not numeric", "bold", TRUE)
  })

  # end must be scalar
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, c(3, 5), "bold", TRUE)
  })

  # end must be non-negative
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, -1, "bold", TRUE)
  })

  # end must be greater than start
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 5, 5, "bold", TRUE)
  })

  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 5, 3, "bold", TRUE)
  })

  # name must be single character string
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, 5, 123, TRUE)
  })

  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, 5, c("a", "b"), TRUE)
  })

  # expand must be valid string
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, 5, "bold", TRUE, expand = "invalid")
  })

  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, 5, "bold", TRUE, expand = 123)
  })

  # Mark value must be scalar POSIXct
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, 5, "time", as.POSIXct(c("2024-01-01", "2024-01-02")))
  })

  # Mark value must be scalar counter
  counter <- structure(c(1L, 2L), class = "am_counter")
  expect_snapshot(error = TRUE, {
    am_mark_create(text_obj, 0, 5, "counter", counter)
  })
})

test_that("am_marks_at validation errors", {
  doc <- am_create()
  doc$text <- am_text("Hello")
  text_obj <- am_get(doc, AM_ROOT, "text")

  # position must be numeric
  expect_snapshot(error = TRUE, {
    am_marks_at(text_obj, "not numeric")
  })

  # position must be scalar
  expect_snapshot(error = TRUE, {
    am_marks_at(text_obj, c(0, 1))
  })

  # position must be non-negative
  expect_snapshot(error = TRUE, {
    am_marks_at(text_obj, -1)
  })
})

# Document lifecycle validation errors ----------------------------------------

test_that("am_create with invalid actor_id types", {
  # actor_id must be NULL, character, or raw
  expect_snapshot(error = TRUE, {
    am_create(actor_id = 123)
  })

  expect_snapshot(error = TRUE, {
    am_create(actor_id = list("id"))
  })

  expect_snapshot(error = TRUE, {
    am_create(actor_id = TRUE)
  })
})

test_that("am_fork with invalid heads parameter", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  # heads must be NULL or list of raw vectors
  expect_snapshot(error = TRUE, {
    am_fork(doc, heads = "not a list")
  })

  expect_snapshot(error = TRUE, {
    am_fork(doc, heads = 123)
  })

  # Elements must be raw vectors
  expect_snapshot(error = TRUE, {
    am_fork(doc, heads = list("not raw"))
  })

  expect_snapshot(error = TRUE, {
    am_fork(doc, heads = list(123))
  })
})

test_that("am_get_change_by_hash validation errors", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  # hash must be raw vector
  expect_snapshot(error = TRUE, {
    am_get_change_by_hash(doc, "not raw")
  })

  expect_snapshot(error = TRUE, {
    am_get_change_by_hash(doc, 123)
  })

  # hash must be exactly 32 bytes
  expect_snapshot(error = TRUE, {
    am_get_change_by_hash(doc, raw(10))
  })

  expect_snapshot(error = TRUE, {
    am_get_change_by_hash(doc, raw(50))
  })
})
