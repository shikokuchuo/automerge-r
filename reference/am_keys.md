# Get all keys from an Automerge map

Returns a character vector of all keys in a map.

## Usage

``` r
am_keys(doc, obj)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (must be a map), or `AM_ROOT` for the document
  root

## Value

Character vector of keys (empty if map is empty)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "a", 1)
am_put(doc, AM_ROOT, "b", 2)

keys <- am_keys(doc, AM_ROOT)
keys  # c("a", "b")
#> [1] "a" "b"
```
