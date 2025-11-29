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

  Integer position in the text (0-based inter-character position)

## Value

An `am_cursor` object (external pointer) that can be used with
[`am_cursor_position()`](http://shikokuchuo.net/automerge-r/reference/am_cursor_position.md)
to retrieve the current position

## Indexing Convention

**Cursor positions use 0-based indexing** (unlike list indices which are
1-based). This is because positions specify locations **between**
characters, not the characters themselves:

- Position 0 = before the first character

- Position 1 = between 1st and 2nd characters

- Position 5 = after the 5th character

For the text "Hello":

      H e l l o
     0 1 2 3 4 5  <- positions (0-based, between characters)

This matches
[`am_text_splice()`](http://shikokuchuo.net/automerge-r/reference/am_text_splice.md)
behavior. Positions count Unicode code points (characters), not bytes.

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
new_pos  # 8 (cursor moved by 3 characters)
#> [1] 8
```
