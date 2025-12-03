# Get the current position of a cursor

Retrieves the current position of a cursor within a text object. The
position automatically adjusts as text is inserted or deleted before the
cursor's original position. The cursor remembers which text object it
was created for, so you only need to pass the cursor itself.

## Usage

``` r
am_cursor_position(cursor)
```

## Arguments

- cursor:

  An `am_cursor` object created by
  [`am_cursor()`](http://shikokuchuo.net/automerge-r/reference/am_cursor.md)

## Value

Integer position (0-based inter-character position) where the cursor
currently points. See
[`am_cursor()`](http://shikokuchuo.net/automerge-r/reference/am_cursor.md)
for indexing details.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

# Create cursor
cursor <- am_cursor(text_obj, 5)

# Get position
pos <- am_cursor_position(cursor)
pos  # 5
#> [1] 5
```
