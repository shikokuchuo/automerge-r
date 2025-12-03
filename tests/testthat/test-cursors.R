test_that("am_cursor creates and retrieves cursor positions", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create cursor at position 5 (after "hello", before " ")
  cursor <- am_cursor(text_obj, 5)
  expect_s3_class(cursor, "am_cursor")

  # Retrieve cursor position
  pos <- am_cursor_position(cursor)
  expect_equal(pos, 5)
})

test_that("cursors track positions across text edits", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create cursor at position 6 (before "world")
  cursor <- am_cursor(text_obj, 6)

  # Insert text before cursor
  am_text_splice(text_obj, 0, 0, "Hi ")

  # Cursor should move forward by 3 characters
  new_pos <- am_cursor_position(cursor)
  expect_equal(new_pos, 9)  # 6 + 3 = 9
})

test_that("cursors handle UTF-32 character indexing correctly", {
  doc <- am_create()
  # Text with emoji (single character in UTF-32)
  am_put(doc, AM_ROOT, "text", am_text("Hello😀World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Position 6 is after emoji (position 5 is the emoji)
  cursor <- am_cursor(text_obj, 6)
  pos <- am_cursor_position(cursor)
  expect_equal(pos, 6)

  # Insert text before cursor
  am_text_splice(text_obj, 0, 0, "A")

  # Cursor moves by 1 character
  new_pos <- am_cursor_position(cursor)
  expect_equal(new_pos, 7)
})

test_that("cursors work at text boundaries", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Cursor at start (position 0, before 'h')
  cursor_start <- am_cursor(text_obj, 0)
  expect_equal(am_cursor_position(cursor_start), 0)

  # Cursor at end (position 4, at last character 'o')
  # Note: Cursors must be placed within the text, not after it
  cursor_end <- am_cursor(text_obj, 4)
  expect_equal(am_cursor_position(cursor_end), 4)
})

test_that("cursor validation rejects invalid inputs", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Non-numeric position
  expect_error(am_cursor(text_obj, "invalid"), "position must be numeric")

  # Non-scalar position
  expect_error(am_cursor(text_obj, c(1, 2)), "position must be a scalar")

  # Negative position
  expect_error(am_cursor(text_obj, -1), "position must be non-negative")

  # Invalid cursor in am_cursor_position
  expect_error(am_cursor_position("not_a_cursor"),
               "cursor must be an external pointer")
})

test_that("multiple cursors work independently", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create multiple cursors
  cursor1 <- am_cursor(text_obj, 2)
  cursor2 <- am_cursor(text_obj, 6)
  cursor3 <- am_cursor(text_obj, 9)

  # Insert text before all cursors
  am_text_splice(text_obj, 0, 0, "XX")

  # All cursors should move by 2
  expect_equal(am_cursor_position(cursor1), 4)
  expect_equal(am_cursor_position(cursor2), 8)
  expect_equal(am_cursor_position(cursor3), 11)
})

test_that("cursors remain valid after text deletion", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create cursor at position 7 (in "world")
  cursor <- am_cursor(text_obj, 7)

  # Delete text before cursor ("hello ")
  am_text_splice(text_obj, 0, 6, "")

  # Cursor should move back by 6 characters
  new_pos <- am_cursor_position(cursor)
  expect_equal(new_pos, 1)  # 7 - 6 = 1
})
