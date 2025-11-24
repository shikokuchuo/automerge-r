# Splice text in a text object

Insert or delete characters in a text object. This is the primary way to
edit text CRDT objects.

## Usage

``` r
am_text_splice(text_obj, pos, del_count, text)
```

## Arguments

- text_obj:

  An Automerge text object ID

- pos:

  Character position to start splice (0-based, counts Unicode code
  points)

- del_count:

  Number of characters to delete (counts Unicode code points)

- text:

  Text to insert

## Value

The text object `text_obj` (invisibly)

## Details

Text positions use character (Unicode code point) indexing, matching R's
[`substr()`](https://rdrr.io/r/base/substr.html) and
[`nchar()`](https://rdrr.io/r/base/nchar.html) behavior. For example, in
"Hello😀", the emoji is at position 5 (as a single character), not byte
offset 5-8.

This means `nchar("😀")` returns 1, and you can use that directly in
text operations without needing to calculate byte offsets.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "doc", am_text("Hello"))
text_obj <- am_get(doc, AM_ROOT, "doc")

# Insert " World" at position 5 (after "Hello")
am_text_splice(text_obj, 5, 0, " World")

# Get the full text
am_text_get(text_obj)  # "Hello World"
#> [1] "Hello World"

# Works naturally with multibyte characters
am_put(doc, AM_ROOT, "emoji", am_text(""))
text_obj2 <- am_get(doc, AM_ROOT, "emoji")
am_text_splice(text_obj2, 0, 0, "Hello😀")
# Position 5 is the emoji (character index, not bytes)
am_text_splice(text_obj2, 6, 0, "World")
am_text_get(text_obj2)  # "Hello😀World"
#> [1] "Hello😀World"
```
