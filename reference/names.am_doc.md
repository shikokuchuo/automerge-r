# Get names from document root

Returns the keys from the root map of an Automerge document.

## Usage

``` r
# S3 method for class 'am_doc'
names(x)
```

## Arguments

- x:

  An Automerge document

## Value

Character vector of key names

## Examples

``` r
doc <- am_create()
doc$name <- "Alice"
doc$age <- 30L
names(doc)  # c("name", "age")
#> [1] "age"  "name"
```
