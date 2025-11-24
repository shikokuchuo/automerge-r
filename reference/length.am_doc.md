# Get length of document root

Returns the number of keys in the root map of an Automerge document.

## Usage

``` r
# S3 method for class 'am_doc'
length(x)
```

## Arguments

- x:

  An Automerge document

## Value

Integer length

## Examples

``` r
doc <- am_create()
doc$a <- 1
doc$b <- 2
length(doc)  # 2
#> [1] 2
```
