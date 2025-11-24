# Convert document root to R list

Recursively converts the root of an Automerge document to a standard R
list. Maps become named lists, lists become unnamed lists, and nested
objects are recursively converted.

## Usage

``` r
# S3 method for class 'am_doc'
as.list(x, ...)
```

## Arguments

- x:

  An Automerge document

- ...:

  Additional arguments (unused)

## Value

Named list with document contents

## Examples

``` r
doc <- am_create()
doc$name <- "Alice"
doc$age <- 30L

as.list(doc)  # list(name = "Alice", age = 30L)
#> $age
#> [1] 30
#> 
#> $name
#> [1] "Alice"
#> 
```
