# Convert Automerge document to R list

Converts an Automerge document to a standard R list. This is equivalent
to
[`as.list.am_doc()`](http://shikokuchuo.net/automerge-r/reference/as.list.am_doc.md).

## Usage

``` r
from_automerge(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

Named list with document contents

## Examples

``` r
doc <- am_create()
doc$name <- "Alice"
doc$age <- 30L

from_automerge(doc)  # list(name = "Alice", age = 30L)
#> $age
#> [1] 30
#> 
#> $name
#> [1] "Alice"
#> 
```
