# Get all marks in a text object

Retrieves all marks (formatting/metadata annotations) present in a text
object at a specific document state.

## Usage

``` r
am_marks(obj)
```

## Arguments

- obj:

  An Automerge object ID (must be a text object)

## Value

A list of marks, where each mark is a list with fields:

- name:

  Character string identifying the mark

- value:

  The mark's value (various types supported)

- start:

  Integer start position (0-based, inclusive)

- end:

  Integer end position (0-based, exclusive)

## Character Indexing

Mark positions use 0-based indexing (like C and
[`am_text_splice()`](http://shikokuchuo.net/automerge-r/reference/am_text_splice.md))
and count Unicode code points (characters), not bytes.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

am_mark_create(text_obj, 0, 5, "bold", TRUE)
am_mark_create(text_obj, 6, 11, "italic", TRUE)

marks <- am_marks(text_obj)
print(marks)
#> [[1]]
#> [[1]]$name
#> [1] "bold"
#> 
#> [[1]]$value
#> [1] TRUE
#> 
#> [[1]]$start
#> [1] 0
#> 
#> [[1]]$end
#> [1] 5
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "italic"
#> 
#> [[2]]$value
#> [1] TRUE
#> 
#> [[2]]$start
#> [1] 6
#> 
#> [[2]]$end
#> [1] 11
#> 
#> 
# List of 2 marks with name, value, start, end
```
