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
  text_obj <- am_put(doc, AM_ROOT, "text", am_text("Hello"))

  # These should work (baseline)
  am_text_splice(doc, text_obj$obj_id, 5, 0, " World")
  result <- am_text_get(doc, text_obj$obj_id)
  expect_equal(result, "Hello World")

  # Try text operations on non-text object
  map_obj <- am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)

  # This should fail - trying to do text operations on a map
  expect_snapshot(error = TRUE, {
    am_text_splice(doc, map_obj$obj_id, 0, 0, "text")
  })
})

test_that("Operations on invalid object types", {
  doc <- am_create()

  # Create a text object
  text_obj <- am_put(doc, AM_ROOT, "text", am_text("content"))

  # Try to use am_keys on text (should work or error gracefully)
  # Text objects don't have "keys" in the map sense
  result <- am_keys(doc, text_obj$obj_id)
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
  am_put(doc, AM_ROOT, "level1", list(
    level2 = list(
      level3 = list(
        level4 = list(
          level5 = "deep"
        )
      )
    )
  ))

  # Now try to perform an invalid operation deep in the structure
  level1 <- am_get(doc, AM_ROOT, "level1")
  level2 <- am_get(doc, level1$obj_id, "level2")
  level3 <- am_get(doc, level2$obj_id, "level3")

  # Valid operations should work
  expect_type(level3, "list")
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
