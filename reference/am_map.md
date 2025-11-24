# Create an Automerge map

Creates an R list with explicit Automerge map type. Use this when you
need to create an empty map or force map type interpretation.

## Usage

``` r
am_map(...)
```

## Arguments

- ...:

  Named elements to include in the map

## Value

A named list with class `am_map_type`

## Examples

``` r
# Empty map (avoids ambiguity)
am_map()
#> list()
#> attr(,"class")
#> [1] "am_map_type" "list"       

# Populated map
am_map(key1 = "value1", key2 = "value2")
#> $key1
#> [1] "value1"
#> 
#> $key2
#> [1] "value2"
#> 
#> attr(,"class")
#> [1] "am_map_type" "list"       
```
