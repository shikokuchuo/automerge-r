# Convert text object to character string

Extracts the full text content from an Automerge text object as a
standard character string.

## Usage

``` r
# S3 method for class 'am_text'
as.character(x, ...)
```

## Arguments

- x:

  An Automerge text object

- ...:

  Additional arguments (unused)

## Value

Character string with the full text content

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "notes", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "notes")

text_string <- as.character(text_obj)
text_string  # "Hello World"
#> [1] "Hello World"

identical(as.character(text_obj), am_text_get(text_obj))  # TRUE
#> [1] TRUE
```
