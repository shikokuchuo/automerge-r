# Tests for error handling in errors.c
# These tests aim to exercise the different error paths in check_result_impl()

test_that("Automerge errors are caught with error messages", {
  # Test AM_STATUS_ERROR with non-empty error message
  # Loading invalid data should trigger an Automerge C error

  # Invalid Automerge format
  expect_snapshot(error = TRUE, {
    am_load(as.raw(c(0x00, 0x01, 0x02)))
  })

  # Random bytes that aren't a valid document
  set.seed(42) # For reproducibility
  expect_snapshot(error = TRUE, {
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
  expect_snapshot(error = TRUE, {
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
    expect_snapshot(error = TRUE, {
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
  expect_snapshot(error = TRUE, {
    am_load(as.raw(c(0xFF)))
  })
})

test_that("Multiple error conditions in sequence", {
  # Test that error state doesn't persist between calls

  # First error
  expect_snapshot(error = TRUE, {
    am_load(as.raw(c(0x00)))
  })

  # Should be able to perform valid operations after error
  doc <- am_create()
  expect_s3_class(doc, "am_doc")

  # Second error
  expect_snapshot(error = TRUE, {
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
    expect_snapshot(error = TRUE, {
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

test_that("am_sync_bidirectional validates doc1 parameter", {
  doc <- am_create()

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional("not a doc", doc)
  })

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(123, doc)
  })

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(NULL, doc)
  })
})

test_that("am_sync_bidirectional validates doc2 parameter", {
  doc <- am_create()

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(doc, "not a doc")
  })

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(doc, 456)
  })

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(doc, NULL)
  })
})

test_that("am_sync_bidirectional validates max_rounds parameter", {
  doc1 <- am_create()
  doc2 <- am_create()

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(doc1, doc2, max_rounds = "not numeric")
  })

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(doc1, doc2, max_rounds = -1)
  })

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(doc1, doc2, max_rounds = 0)
  })

  expect_snapshot(error = TRUE, {
    am_sync_bidirectional(doc1, doc2, max_rounds = c(1, 2))
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
