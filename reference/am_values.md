# Get all values from a map or list

Returns all values from an Automerge map or list as an R list.

## Usage

``` r
am_values(doc, obj)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID, or `AM_ROOT` for the document root

## Value

R list of values

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "a", 1)
am_put(doc, AM_ROOT, "b", 2)
am_put(doc, AM_ROOT, "c", 3)

values <- am_values(doc, AM_ROOT)
values  # list(1, 2, 3)
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 
```
