# Get text from a text object

Retrieve the full text content from a text object as a string.

## Usage

``` r
am_text_get(text_obj)
```

## Arguments

- text_obj:

  An Automerge text object ID

## Value

Character string with the full text

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "doc", am_text("Hello"))
text_obj <- am_get(doc, AM_ROOT, "doc")

text <- am_text_get(text_obj)
print(text)  # "Hello"
#> [1] "Hello"
```
