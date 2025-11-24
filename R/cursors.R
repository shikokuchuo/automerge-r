# Cursor and Mark Operations

#' Create a cursor at a position in a text object
#'
#' Cursors provide stable references to positions within text objects that
#' automatically adjust as the text is edited. This enables features like
#' maintaining selection positions across concurrent edits in collaborative
#' editing scenarios.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param position Integer position in the text (0-based inter-character position)
#'
#' @return An `am_cursor` object (external pointer) that can be used with
#'   [am_cursor_position()] to retrieve the current position
#'
#' @section Indexing Convention:
#' **Cursor positions use 0-based indexing** (unlike list indices which are
#' 1-based). This is because positions specify locations **between** characters,
#' not the characters themselves:
#' \itemize{
#'   \item Position 0 = before the first character
#'   \item Position 1 = between 1st and 2nd characters
#'   \item Position 5 = after the 5th character
#' }
#'
#' For the text "Hello":
#' \preformatted{
#'   H e l l o
#'  0 1 2 3 4 5  <- positions (0-based, between characters)
#' }
#'
#' This matches `am_text_splice()` behavior. Positions count Unicode code points
#' (characters), not bytes.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' # Create cursor at position 5 (after "Hello", before " ")
#' cursor <- am_cursor(text_obj, 5)
#'
#' # Modify text before cursor
#' am_text_splice(text_obj, 0, 0, "Hi ")
#'
#' # Cursor position automatically adjusts
#' new_pos <- am_cursor_position(text_obj, cursor)
#' print(new_pos)  # 8 (cursor moved by 3 characters)
am_cursor <- function(obj, position) {
  .Call(C_am_cursor, obj, position)
}

#' Get the current position of a cursor
#'
#' Retrieves the current position of a cursor within a text object. The
#' position automatically adjusts as text is inserted or deleted before
#' the cursor's original position.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param cursor An `am_cursor` object created by [am_cursor()]
#'
#' @return Integer position (0-based inter-character position) where the cursor
#'   currently points. See [am_cursor()] for indexing details.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' # Create cursor
#' cursor <- am_cursor(text_obj, 5)
#'
#' # Get position
#' pos <- am_cursor_position(text_obj, cursor)
#' print(pos)  # 5
am_cursor_position <- function(obj, cursor) {
  .Call(C_am_cursor_position, obj, cursor)
}

#' Create a mark on a text range
#'
#' Marks attach metadata or formatting information to a range of text.
#' Unlike simple annotations, marks are CRDT-aware and merge correctly
#' across concurrent edits.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param start Integer start position (0-based inter-character position, inclusive)
#' @param end Integer end position (0-based inter-character position, exclusive)
#' @param name Character string identifying the mark (e.g., "bold", "comment")
#' @param value The mark's value (any Automerge-compatible type: NULL, logical,
#'   integer, numeric, character, raw, POSIXct, or am_counter)
#' @param expand Character string controlling mark expansion behavior when text
#'   is inserted at boundaries. Options:
#'   \describe{
#'     \item{"none"}{Mark does not expand (default)}
#'     \item{"before"}{Mark expands to include text inserted before start}
#'     \item{"after"}{Mark expands to include text inserted after end}
#'     \item{"both"}{Mark expands in both directions}
#'   }
#'   Use the constants [AM_MARK_EXPAND_NONE], [AM_MARK_EXPAND_BEFORE],
#'   [AM_MARK_EXPAND_AFTER], or [AM_MARK_EXPAND_BOTH].
#'
#' @return The text object `obj` (invisibly)
#'
#' @section Indexing Convention:
#' **Mark positions use 0-based indexing** (unlike list indices which are
#' 1-based). Positions specify locations **between** characters. The range
#' `[start, end)` includes `start` but excludes `end`.
#'
#' For the text "Hello":
#' \preformatted{
#'   H e l l o
#'  0 1 2 3 4 5  <- positions (0-based, between characters)
#' }
#'
#' Marking positions 0 to 5 marks all 5 characters. Marking 0 to 3 marks "Hel".
#' Positions count Unicode code points (characters), not bytes.
#'
#' @section Expand Behavior:
#' The `expand` parameter controls what happens when text is inserted exactly
#' at the mark boundaries:
#' \itemize{
#'   \item `"none"`: New text is never included in the mark
#'   \item `"before"`: Text inserted at `start` is included
#'   \item `"after"`: Text inserted at `end` is included
#'   \item `"both"`: Text inserted at either boundary is included
#' }
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' # Mark "Hello" as bold (positions 0-4, characters 0-4)
#' am_mark_create(text_obj, 0, 5, "bold", TRUE)
#'
#' # Mark "World" as italic with expansion
#' am_mark_create(text_obj, 6, 11, "italic", TRUE,
#'                expand = AM_MARK_EXPAND_BOTH)
#'
#' # Get all marks
#' marks <- am_marks(text_obj)
#' print(marks)
am_mark_create <- function(obj, start, end, name, value,
                           expand = AM_MARK_EXPAND_NONE) {
  invisible(.Call(C_am_mark_create, obj, start, end, name, value, expand))
}

#' Get all marks in a text object
#'
#' Retrieves all marks (formatting/metadata annotations) present in a text
#' object at a specific document state.
#'
#' @param obj An Automerge object ID (must be a text object)
#'
#' @return A list of marks, where each mark is a list with fields:
#'   \describe{
#'     \item{name}{Character string identifying the mark}
#'     \item{value}{The mark's value (various types supported)}
#'     \item{start}{Integer start position (0-based inter-character position, inclusive)}
#'     \item{end}{Integer end position (0-based inter-character position, exclusive)}
#'   }
#'   Returns an empty list if no marks are present. See [am_mark_create()] for
#'   indexing details.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' am_mark_create(text_obj, 0, 5, "bold", TRUE)
#' am_mark_create(text_obj, 6, 11, "italic", TRUE)
#'
#' marks <- am_marks(text_obj)
#' print(marks)
#' # List of 2 marks with name, value, start, end
am_marks <- function(obj) {
  .Call(C_am_marks, obj)
}

#' Get marks at a specific position
#'
#' Convenience function to retrieve marks that include a specific position.
#' This is equivalent to calling [am_marks()] and filtering the results.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param position Integer position (0-based inter-character position) to query.
#'   See [am_mark_create()] for indexing details.
#'
#' @return A list of marks that include the specified position. Returns an empty
#'   list if no marks cover that position.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' am_mark_create(text_obj, 0, 5, "bold", TRUE)
#' am_mark_create(text_obj, 2, 7, "underline", TRUE)
#'
#' # Get marks at position 3 (inside "Hello")
#' marks_at_3 <- am_marks_at(text_obj, 3)
#' print(marks_at_3)
#' # List of 2 marks (both "bold" and "underline" include position 3)
am_marks_at <- function(obj, position) {
  all_marks <- am_marks(obj)
  if (length(all_marks) == 0) {
    return(list())
  }

  # Filter marks that include the position
  # Mark range is [start, end) - includes start, excludes end
  Filter(function(mark) {
    mark$start <= position && position < mark$end
  }, all_marks)
}
