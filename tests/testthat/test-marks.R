test_that("am_mark_create creates marks on text ranges", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark "hello" (positions 0-4) as bold
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE)

  # Get marks
  marks <- am_marks(doc, text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
  expect_equal(marks[[1]]$value, TRUE)
  expect_equal(marks[[1]]$start, 0)
  expect_equal(marks[[1]]$end, 5)
})

test_that("multiple marks can exist on same text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Add multiple marks
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE)
  am_mark_create(doc, text_obj, 6, 11, "italic", TRUE)
  am_mark_create(doc, text_obj, 2, 8, "underline", TRUE)

  # Get all marks
  marks <- am_marks(doc, text_obj)
  expect_length(marks, 3)

  # Check mark names
  mark_names <- sapply(marks, function(m) m$name)
  expect_setequal(mark_names, c("bold", "italic", "underline"))
})

test_that("mark expand mode 'none' works correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "none" (positions 0-4 cover "hello")
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_NONE)

  # Insert text at start boundary (position 0)
  am_text_splice(text_obj, 0, 0, "X")

  # Mark should not expand to include new text
  marks <- am_marks(doc, text_obj)
  expect_equal(marks[[1]]$start, 1)  # Shifted by 1
  expect_equal(marks[[1]]$end, 6)    # Shifted by 1

  # Insert text at end boundary (position 6)
  am_text_splice(text_obj, 6, 0, "Y")

  # Mark should not include new text at end
  marks <- am_marks(doc, text_obj)
  expect_equal(marks[[1]]$start, 1)
  expect_equal(marks[[1]]$end, 6)  # Does not include "Y"
})

test_that("mark expand mode 'before' can be set", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "before"
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BEFORE)

  marks <- am_marks(doc, text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("mark expand mode 'after' can be set", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "after"
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_AFTER)

  marks <- am_marks(doc, text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("mark expand mode 'both' can be set", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "both"
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BOTH)

  marks <- am_marks(doc, text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("mark values support various types", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Boolean value
  am_mark_create(doc, text_obj, 0, 1, "bool", TRUE)

  # Integer value
  am_mark_create(doc, text_obj, 1, 2, "int", 42L)

  # Numeric value
  am_mark_create(doc, text_obj, 2, 3, "num", 3.14)

  # String value
  am_mark_create(doc, text_obj, 3, 4, "str", "test")

  # Note: NULL values are accepted but don't create visible marks
  # (NULL is used to clear/remove marks in automerge-c)
  am_mark_create(doc, text_obj, 4, 5, "null", NULL)

  marks <- am_marks(doc, text_obj)
  expect_length(marks, 4)  # NULL mark doesn't appear in results

  # Verify values
  expect_equal(marks[[1]]$value, TRUE)
  expect_equal(marks[[2]]$value, 42L)
  expect_equal(marks[[3]]$value, 3.14)
  expect_equal(marks[[4]]$value, "test")
})

test_that("am_marks_at returns marks at specific position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create overlapping marks
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE)      # Covers positions 0-4
  am_mark_create(doc, text_obj, 2, 8, "underline", TRUE) # Covers positions 2-7
  am_mark_create(doc, text_obj, 6, 11, "italic", TRUE)   # Covers positions 6-10

  # Position 0: only "bold"
  marks_at_0 <- am_marks_at(doc, text_obj, 0)
  expect_length(marks_at_0, 1)
  expect_equal(marks_at_0[[1]]$name, "bold")

  # Position 3: "bold" and "underline"
  marks_at_3 <- am_marks_at(doc, text_obj, 3)
  expect_length(marks_at_3, 2)
  mark_names <- sapply(marks_at_3, function(m) m$name)
  expect_setequal(mark_names, c("bold", "underline"))

  # Position 6: "underline" and "italic"
  marks_at_6 <- am_marks_at(doc, text_obj, 6)
  expect_length(marks_at_6, 2)
  mark_names <- sapply(marks_at_6, function(m) m$name)
  expect_setequal(mark_names, c("underline", "italic"))

  # Position 9: only "italic"
  marks_at_9 <- am_marks_at(doc, text_obj, 9)
  expect_length(marks_at_9, 1)
  expect_equal(marks_at_9[[1]]$name, "italic")

  # Position outside all marks
  marks_at_11 <- am_marks_at(doc, text_obj, 11)
  expect_length(marks_at_11, 0)
})

test_that("marks work with UTF-32 character indexing", {
  doc <- am_create()
  # Text with emoji (single character in UTF-32)
  am_put(doc, AM_ROOT, "text", am_text("Hello😀World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark the emoji (position 5, which is where emoji is)
  am_mark_create(doc, text_obj, 5, 6, "emoji", TRUE)

  marks <- am_marks(doc, text_obj)
  expect_equal(marks[[1]]$start, 5)
  expect_equal(marks[[1]]$end, 6)
  expect_equal(marks[[1]]$name, "emoji")
})

test_that("mark validation rejects invalid inputs", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Invalid start position
  expect_error(am_mark_create(doc, text_obj, -1, 3, "test", TRUE),
               "start must be non-negative")
  expect_error(am_mark_create(doc, text_obj, "a", 3, "test", TRUE),
               "start must be numeric")

  # Invalid end position
  expect_error(am_mark_create(doc, text_obj, 1, -1, "test", TRUE),
               "end must be non-negative")
  expect_error(am_mark_create(doc, text_obj, 1, "a", "test", TRUE),
               "end must be numeric")

  # End before or equal to start
  expect_error(am_mark_create(doc, text_obj, 5, 3, "test", TRUE),
               "end must be greater than start")
  expect_error(am_mark_create(doc, text_obj, 3, 3, "test", TRUE),
               "end must be greater than start")

  # Invalid name
  expect_error(am_mark_create(doc, text_obj, 1, 3, c("a", "b"), TRUE),
               "name must be a single character string")

  # Invalid expand mode
  expect_error(am_mark_create(doc, text_obj, 1, 3, "test", TRUE, expand = "invalid"),
               "Invalid expand value")
  expect_error(am_mark_create(doc, text_obj, 1, 3, "test", TRUE, expand = 123),
               "expand must be a single character string")
})

test_that("marks with counter and timestamp values", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Counter value
  counter <- structure(5L, class = "am_counter")
  am_mark_create(doc, text_obj, 0, 2, "counter", counter)

  # Timestamp value
  timestamp <- as.POSIXct("2025-01-01 12:00:00", tz = "UTC")
  am_mark_create(doc, text_obj, 3, 5, "timestamp", timestamp)

  marks <- am_marks(doc, text_obj)
  expect_length(marks, 2)

  # Verify counter value
  expect_s3_class(marks[[1]]$value, "am_counter")
  expect_equal(as.integer(marks[[1]]$value), 5L)

  # Verify timestamp value
  expect_s3_class(marks[[2]]$value, "POSIXct")
})

test_that("marks return empty list when no marks exist", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  marks <- am_marks(doc, text_obj)
  expect_length(marks, 0)

  marks_at_5 <- am_marks_at(doc, text_obj, 5)
  expect_length(marks_at_5, 0)
})

test_that("marks work across document commits", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create mark before commit
  am_mark_create(doc, text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "Add bold mark")

  # Mark should still exist after commit
  marks <- am_marks(doc, text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")

  # Add another mark after commit
  am_mark_create(doc, text_obj, 6, 11, "italic", TRUE)
  am_commit(doc, "Add italic mark")

  # Both marks should exist
  marks <- am_marks(doc, text_obj)
  expect_length(marks, 2)
})
