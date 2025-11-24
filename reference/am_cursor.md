# Create a cursor at a position in a text object

Cursors provide stable references to positions within text objects that
automatically adjust as the text is edited. This enables features like
maintaining selection positions across concurrent edits in collaborative
editing scenarios.

## Usage

``` r
am_cursor(obj, position)
```

## Arguments

- obj:

  An Automerge object ID (must be a text object)

- position:

  Integer position in the text (0-based indexing, consistent with
  [`am_text_splice()`](http://shikokuchuo.net/automerge-r/reference/am_text_splice.md)).
  Position 0 is before the first character, position 1 is before the
  second character, etc.

## Value

An `am_cursor` object (external pointer) that can be used with
[`am_cursor_position()`](http://shikokuchuo.net/automerge-r/reference/am_cursor_position.md)
to retrieve the current position

## Character Indexing

Positions use 0-based indexing (like C and
[`am_text_splice()`](http://shikokuchuo.net/automerge-r/reference/am_text_splice.md))
and count Unicode code points (characters), not bytes. For example, in
the text "Hello😀", the emoji is at position 5, and each character
(including emoji) counts as 1 position.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

# Create cursor at position 5 (after "Hello", before " ")
cursor <- am_cursor(text_obj, 5)

# Modify text before cursor
am_text_splice(text_obj, 0, 0, "Hi ")

# Cursor position automatically adjusts
new_pos <- am_cursor_position(text_obj, cursor)
print(new_pos)  # 8 (cursor moved by 3 characters)
#> [1] 8
```
