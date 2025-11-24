# Create an Automerge list

Creates an R list with explicit Automerge list type. Use this when you
need to create an empty list or force list type interpretation.

## Usage

``` r
am_list(...)
```

## Arguments

- ...:

  Elements to include in the list

## Value

A list with class `am_list_type`

## Examples

``` r
# Empty list (avoids ambiguity)
am_list()
#> list()
#> attr(,"class")
#> [1] "am_list_type" "list"        

# Populated list
am_list("a", "b", "c")
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> [[3]]
#> [1] "c"
#> 
#> attr(,"class")
#> [1] "am_list_type" "list"        
```
