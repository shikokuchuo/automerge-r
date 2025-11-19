# Document Lifecycle Tests (Phase 2)

test_that("am_create() creates a valid document", {
  doc <- am_create()
  expect_s3_class(doc, "am_doc")
  expect_s3_class(doc, "automerge")
})

test_that("am_create() works with NULL actor_id", {
  doc <- am_create(NULL)
  expect_s3_class(doc, "am_doc")
  actor <- am_get_actor(doc)
  expect_type(actor, "raw")
  expect_true(length(actor) > 0)
})

test_that("am_create() works with hex string actor_id", {
  # Create with specific hex actor ID (32 hex chars = 16 bytes)
  hex_id <- paste0(rep("0", 32), collapse = "")
  doc <- am_create(hex_id)
  expect_s3_class(doc, "am_doc")
})

test_that("am_create() works with raw bytes actor_id", {
  # Create with 16 byte actor ID
  actor_bytes <- as.raw(1:16)
  doc <- am_create(actor_bytes)
  expect_s3_class(doc, "am_doc")

  # Verify actor ID was set correctly
  retrieved_actor <- am_get_actor(doc)
  expect_equal(retrieved_actor, actor_bytes)
})

test_that("am_create() errors on invalid actor_id", {
  expect_error(am_create(123), "actor_id must be NULL")
  expect_error(am_create(list()), "actor_id must be NULL")
})

test_that("am_save() returns raw bytes", {
  doc <- am_create()
  bytes <- am_save(doc)
  expect_type(bytes, "raw")
  expect_true(length(bytes) > 0)
})

test_that("am_load() restores a saved document", {
  doc1 <- am_create()
  bytes <- am_save(doc1)

  doc2 <- am_load(bytes)
  expect_s3_class(doc2, "am_doc")
})

test_that("am_load() errors on non-raw input", {
  expect_error(am_load("not raw"), "data must be a raw vector")
  expect_error(am_load(123), "data must be a raw vector")
})

test_that("am_fork() creates independent copy", {
  doc1 <- am_create()
  doc2 <- am_fork(doc1)

  expect_s3_class(doc2, "am_doc")
  # doc1 and doc2 should be different external pointers
  expect_false(identical(doc1, doc2))
})

test_that("am_merge() combines documents", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Merge doc2 into doc1
  result <- am_merge(doc1, doc2)
  expect_identical(result, doc1)  # Should return doc1
})

test_that("am_get_actor() returns raw bytes", {
  doc <- am_create()
  actor <- am_get_actor(doc)

  expect_type(actor, "raw")
  expect_true(length(actor) > 0)

  # Can display as hex
  hex_str <- paste(format(actor, width = 2), collapse = "")
  expect_type(hex_str, "character")
  expect_true(nchar(hex_str) > 0)
})

test_that("am_set_actor() changes actor ID", {
  doc <- am_create()
  original_actor <- am_get_actor(doc)

  # Set new random actor ID
  am_set_actor(doc, NULL)
  new_actor <- am_get_actor(doc)

  expect_type(new_actor, "raw")
  # New actor should be different (almost certainly)
  expect_false(identical(original_actor, new_actor))
})

test_that("am_set_actor() works with hex string", {
  doc <- am_create()
  hex_id <- paste0(rep("0", 32), collapse = "")

  am_set_actor(doc, hex_id)
  actor <- am_get_actor(doc)

  expect_type(actor, "raw")
  expect_equal(length(actor), 16)
})

test_that("am_set_actor() works with raw bytes", {
  doc <- am_create()
  new_actor_bytes <- as.raw(seq(16, 1, -1))  # 16 bytes in reverse

  am_set_actor(doc, new_actor_bytes)
  retrieved_actor <- am_get_actor(doc)

  expect_equal(retrieved_actor, new_actor_bytes)
})

test_that("am_commit() works with no arguments", {
  doc <- am_create()
  result <- am_commit(doc)
  expect_identical(result, doc)  # Returns doc invisibly
})

test_that("am_commit() works with message", {
  doc <- am_create()
  result <- am_commit(doc, "Test commit message")
  expect_identical(result, doc)
})

test_that("am_commit() works with message and time", {
  doc <- am_create()
  timestamp <- Sys.time()
  result <- am_commit(doc, "Commit with timestamp", timestamp)
  expect_identical(result, doc)
})

test_that("am_commit() errors on invalid message", {
  doc <- am_create()
  expect_error(am_commit(doc, 123), "message must be NULL")
  expect_error(am_commit(doc, c("a", "b")), "message must be NULL")
})

test_that("am_commit() errors on invalid time", {
  doc <- am_create()
  expect_error(am_commit(doc, NULL, "not a time"), "time must be NULL")
  expect_error(am_commit(doc, NULL, 12345), "time must be NULL")
})

test_that("am_rollback() works", {
  doc <- am_create()
  result <- am_rollback(doc)
  expect_identical(result, doc)  # Returns doc invisibly
})

test_that("Document lifecycle integration test", {
  # Create document
  doc1 <- am_create()

  # Commit some changes (even though we haven't added data yet)
  am_commit(doc1, "Initial commit")

  # Save to bytes
  bytes <- am_save(doc1)
  expect_type(bytes, "raw")

  # Load from bytes
  doc2 <- am_load(bytes)
  expect_s3_class(doc2, "am_doc")

  # Fork the document
  doc3 <- am_fork(doc2)
  expect_s3_class(doc3, "am_doc")

  # Merge (even though they're identical)
  am_merge(doc1, doc3)

  # All operations succeeded without error
  expect_true(TRUE)
})

test_that("Actor ID round-trip works", {
  doc1 <- am_create()
  actor1 <- am_get_actor(doc1)

  # Create new document with same actor
  doc2 <- am_create(actor1)
  actor2 <- am_get_actor(doc2)

  expect_equal(actor1, actor2)
})
