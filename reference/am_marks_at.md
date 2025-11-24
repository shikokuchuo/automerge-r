# Get marks at a specific position

Convenience function to retrieve marks that include a specific position.
This is equivalent to calling
[`am_marks()`](http://shikokuchuo.net/automerge-r/reference/am_marks.md)
and filtering the results.

## Usage

``` r
am_marks_at(obj, position)
```

## Arguments

- obj:

  An Automerge object ID (must be a text object)

- position:

  Integer position (0-based) to query

## Value

A list of marks that include the specified position

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

am_mark_create(text_obj, 0, 5, "bold", TRUE)
am_mark_create(text_obj, 2, 7, "underline", TRUE)

# Get marks at position 3 (inside "Hello")
marks_at_3 <- am_marks_at(text_obj, 3)
print(marks_at_3)
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
#> [1] "underline"
#> 
#> [[2]]$value
#> [1] TRUE
#> 
#> [[2]]$start
#> [1] 2
#> 
#> [[2]]$end
#> [1] 7
#> 
#> 
# List of 2 marks (both "bold" and "underline" include position 3)
```
