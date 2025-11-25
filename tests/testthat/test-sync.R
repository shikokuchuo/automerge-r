test_that("am_sync_state_new creates a valid sync state", {
  sync_state <- am_sync_state_new()
  expect_s3_class(sync_state, "am_syncstate")
  expect_type(sync_state, "externalptr")
})

test_that("am_sync_encode/decode work with empty documents", {
  doc1 <- am_create()
  doc2 <- am_create()

  sync1 <- am_sync_state_new()
  sync2 <- am_sync_state_new()

  # First message from doc1
  msg1 <- am_sync_encode(doc1, sync1)
  expect_type(msg1, "raw")
  expect_gt(length(msg1), 0)

  # Receive in doc2
  am_sync_decode(doc2, sync2, msg1)

  # doc2 responds
  msg2 <- am_sync_encode(doc2, sync2)
  if (!is.null(msg2)) {
    am_sync_decode(doc1, sync1, msg2)
  }

  # Eventually both should return NULL (no more messages)
  for (i in 1:10) {
    msg1 <- am_sync_encode(doc1, sync1)
    msg2 <- am_sync_encode(doc2, sync2)
    if (is.null(msg1) && is.null(msg2)) {
      break
    }
    if (!is.null(msg1)) {
      am_sync_decode(doc2, sync2, msg1)
    }
    if (!is.null(msg2)) am_sync_decode(doc1, sync1, msg2)
  }

  expect_null(am_sync_encode(doc1, sync1))
  expect_null(am_sync_encode(doc2, sync2))
})

test_that("am_sync_encode/decode synchronize simple changes", {
  # Create two documents with different changes
  doc1 <- am_create()
  doc2 <- am_create()

  # Make changes in doc1
  am_put(doc1, AM_ROOT, "x", 1)
  am_commit(doc1, "Add x")

  # Make changes in doc2
  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "Add y")

  # Verify they're different before sync
  expect_null(am_get(doc1, AM_ROOT, "y"))
  expect_null(am_get(doc2, AM_ROOT, "x"))

  # Create sync states
  sync1 <- am_sync_state_new()
  sync2 <- am_sync_state_new()

  # Exchange messages until convergence
  for (round in 1:20) {
    msg1 <- am_sync_encode(doc1, sync1)
    msg2 <- am_sync_encode(doc2, sync2)

    if (is.null(msg1) && is.null(msg2)) {
      break
    }

    if (!is.null(msg1)) {
      am_sync_decode(doc2, sync2, msg1)
    }
    if (!is.null(msg2)) am_sync_decode(doc1, sync1, msg2)
  }

  # Both documents should now have both x and y
  expect_equal(am_get(doc1, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc1, AM_ROOT, "y"), 2)
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "y"), 2)
})

test_that("am_sync synchronizes two documents", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Make different changes in each document
  am_put(doc1, AM_ROOT, "a", 1)
  am_put(doc1, AM_ROOT, "b", 2)
  am_commit(doc1)

  am_put(doc2, AM_ROOT, "c", 3)
  am_put(doc2, AM_ROOT, "d", 4)
  am_commit(doc2)

  # Sync using high-level helper
  result <- am_sync(doc1, doc2)

  expect_type(result, "list")
  expect_named(result, c("doc1", "doc2", "rounds"))
  expect_gt(result$rounds, 0)
  expect_lte(result$rounds, 100)

  # Both documents should have all four keys
  expect_equal(am_get(doc1, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc1, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc1, AM_ROOT, "c"), 3)
  expect_equal(am_get(doc1, AM_ROOT, "d"), 4)

  expect_equal(am_get(doc2, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc2, AM_ROOT, "c"), 3)
  expect_equal(am_get(doc2, AM_ROOT, "d"), 4)
})

test_that("am_sync handles concurrent edits", {
  # Start with synchronized documents
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "counter", 0)
  am_commit(doc1)

  # Fork to create doc2
  doc2 <- am_fork(doc1)

  # Make concurrent changes
  am_put(doc1, AM_ROOT, "counter", 1)
  am_put(doc1, AM_ROOT, "x", "from_doc1")
  am_commit(doc1, "Doc1 update")

  am_put(doc2, AM_ROOT, "counter", 10)
  am_put(doc2, AM_ROOT, "y", "from_doc2")
  am_commit(doc2, "Doc2 update")

  # Sync them
  result <- am_sync(doc1, doc2)


  # Both should have both x and y
  expect_equal(am_get(doc1, AM_ROOT, "x"), "from_doc1")
  expect_equal(am_get(doc1, AM_ROOT, "y"), "from_doc2")
  expect_equal(am_get(doc2, AM_ROOT, "x"), "from_doc1")
  expect_equal(am_get(doc2, AM_ROOT, "y"), "from_doc2")

  # Counter should have a conflict resolved by Automerge CRDT semantics
  # (both values exist, but one is selected as the "winner")
  counter1 <- am_get(doc1, AM_ROOT, "counter")
  counter2 <- am_get(doc2, AM_ROOT, "counter")
  expect_equal(counter1, counter2) # Should be the same in both docs
})

test_that("am_get_heads returns current document heads", {
  doc <- am_create()

  # New document should have empty heads
  heads <- am_get_heads(doc)
  expect_type(heads, "list")
  expect_equal(length(heads), 0)

  # Make a change and commit
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc)

  heads <- am_get_heads(doc)
  expect_equal(length(heads), 1)
  expect_type(heads[[1]], "raw")
  expect_gt(length(heads[[1]]), 0)

  # Make another change
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc)

  heads2 <- am_get_heads(doc)
  expect_equal(length(heads2), 1)
  # Heads should have changed
  expect_false(identical(heads[[1]], heads2[[1]]))
})

test_that("am_get_changes returns document history", {
  doc <- am_create()

  # No changes initially
  changes <- am_get_changes(doc, NULL)
  expect_type(changes, "list")
  expect_equal(length(changes), 0)

  # Make some changes
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First change")

  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second change")

  am_put(doc, AM_ROOT, "z", 3)
  am_commit(doc, "Third change")

  # Get all changes
  changes <- am_get_changes(doc, NULL)
  expect_equal(length(changes), 3)

  # Each change should be a raw vector
  for (change in changes) {
    expect_type(change, "raw")
    expect_gt(length(change), 0)
  }
})

test_that("am_apply_changes applies changes to a document", {
  # Create a document with changes
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "a", 1)
  am_put(doc1, AM_ROOT, "b", 2)
  am_commit(doc1)

  am_put(doc1, AM_ROOT, "c", 3)
  am_commit(doc1)

  # Get all changes
  changes <- am_get_changes(doc1, NULL)
  expect_gt(length(changes), 0)

  # Create a new document and apply changes
  doc2 <- am_create()
  am_apply_changes(doc2, changes)

  # doc2 should now have the same data as doc1
  expect_equal(am_get(doc2, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc2, AM_ROOT, "c"), 3)
})

test_that("am_get_history returns full change history", {
  doc <- am_create()

  am_put(doc, AM_ROOT, "v1", "first")
  am_commit(doc, "Version 1")

  am_put(doc, AM_ROOT, "v2", "second")
  am_commit(doc, "Version 2")

  am_put(doc, AM_ROOT, "v3", "third")
  am_commit(doc, "Version 3")

  history <- am_get_history(doc)
  expect_type(history, "list")
  expect_equal(length(history), 3)

  # Each history entry should be a serialized change
  for (entry in history) {
    expect_type(entry, "raw")
  }
})

test_that("sync works with nested objects", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Create nested structure in doc1
  am_put(doc1, AM_ROOT, "config", AM_OBJ_TYPE_MAP)
  map <- am_get(doc1, AM_ROOT, "config")
  am_put(doc1, map, "host", "localhost")
  am_put(doc1, map, "port", 8080)
  am_commit(doc1, "Add config")

  # Create different structure in doc2
  am_put(doc2, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  list <- am_get(doc2, AM_ROOT, "items")
  am_insert(doc2, list, 1, "first")
  am_insert(doc2, list, 2, "second")
  am_commit(doc2, "Add items")

  # Sync
  result <- am_sync(doc1, doc2)

  # Both should have both structures
  config1 <- am_get(doc1, AM_ROOT, "config")
  expect_s3_class(config1, "am_object")
  expect_equal(am_get(doc1, config1, "host"), "localhost")

  items1 <- am_get(doc1, AM_ROOT, "items")
  expect_s3_class(items1, "am_object")
  expect_equal(am_length(doc1, items1), 2)

  config2 <- am_get(doc2, AM_ROOT, "config")
  expect_s3_class(config2, "am_object")

  items2 <- am_get(doc2, AM_ROOT, "items")
  expect_s3_class(items2, "am_object")
})

test_that("sync protocol errors are handled gracefully", {
  doc <- am_create()
  sync_state <- am_sync_state_new()

  # Try to decode invalid sync message
  invalid_msg <- raw(10) # Random bytes
  expect_error(
    am_sync_decode(doc, sync_state, invalid_msg),
    "Automerge error|expected|found"
  )

  # Verify document and sync state are still valid after error
  msg <- am_sync_encode(doc, sync_state)
  expect_true(is.raw(msg) || is.null(msg))
})

test_that("sync state is document-independent", {
  # Create multiple documents
  doc1 <- am_create()
  doc2 <- am_create()
  doc3 <- am_create()

  # Single sync state can be used with different documents
  sync_state <- am_sync_state_new()

  # Use it with doc1
  msg1 <- am_sync_encode(doc1, sync_state)
  expect_true(is.raw(msg1) || is.null(msg1))

  # Use same sync state with doc2 (though this is unusual)
  msg2 <- am_sync_encode(doc2, sync_state)
  expect_true(is.raw(msg2) || is.null(msg2))
})

test_that("am_apply_changes handles empty change list", {
  doc <- am_create()

  # Apply empty changes list
  am_apply_changes(doc, list())

  # Document should still be valid
  am_put(doc, AM_ROOT, "x", 1)
  expect_equal(am_get(doc, AM_ROOT, "x"), 1)
})

test_that("sync works with text objects", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Create text in doc1
  am_put(doc1, AM_ROOT, "notes", AM_OBJ_TYPE_TEXT)
  text1 <- am_get(doc1, AM_ROOT, "notes")
  am_text_splice(text1, 0, 0, "Hello from doc1")
  am_commit(doc1)

  # Create text in doc2
  am_put(doc2, AM_ROOT, "greet", AM_OBJ_TYPE_TEXT)
  text2 <- am_get(doc2, AM_ROOT, "greet")
  am_text_splice(text2, 0, 0, "Hi from doc2")
  am_commit(doc2)

  # Sync
  result <- am_sync(doc1, doc2)

  # Both should have both text objects
  notes1 <- am_get(doc1, AM_ROOT, "notes")
  greet1 <- am_get(doc1, AM_ROOT, "greet")
  expect_equal(am_text_get(notes1), "Hello from doc1")
  expect_equal(am_text_get(greet1), "Hi from doc2")

  notes2 <- am_get(doc2, AM_ROOT, "notes")
  greet2 <- am_get(doc2, AM_ROOT, "greet")
  expect_equal(am_text_get(notes2), "Hello from doc1")
  expect_equal(am_text_get(greet2), "Hi from doc2")
})

test_that("am_get_changes with specific heads", {
  doc <- am_create()

  # Make first change
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  heads1 <- am_get_heads(doc)

  # Make second change
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  # Make third change
  am_put(doc, AM_ROOT, "z", 3)
  am_commit(doc, "Third")

  # Get changes since heads1 (should get changes 2 and 3)
  changes_since <- am_get_changes(doc, heads1)
  expect_type(changes_since, "list")
  expect_equal(length(changes_since), 2)
})

test_that("am_get_changes_added returns added changes", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "x", 1)
  am_commit(doc1)

  # Fork and make independent changes
  doc2 <- am_fork(doc1)

  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2)

  am_put(doc2, AM_ROOT, "z", 3)
  am_commit(doc2)

  # Get what was added to doc2 since the fork
  # am_get_changes_added(doc1, doc2) returns changes in doc2 not in doc1
  added <- am_get_changes_added(doc1, doc2)
  expect_type(added, "list")
  expect_equal(length(added), 2) # Two commits in doc2
})
