# Get the length of an Automerge map or list

Returns the number of key-value pairs in a map or elements in a list.

## Usage

``` r
am_length(doc, obj)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID, or `AM_ROOT` for the document root

## Value

Integer length/size

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "a", 1)
am_put(doc, AM_ROOT, "b", 2)

len <- am_length(doc, AM_ROOT)
print(len)  # 2
#> [1] 2
```
