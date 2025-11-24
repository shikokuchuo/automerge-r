# Set value at path

Set a value in an Automerge document using a path vector. Can optionally
create intermediate objects automatically.

## Usage

``` r
am_put_path(doc, path, value, create_intermediate = TRUE)
```

## Arguments

- doc:

  An Automerge document

- path:

  Character vector, numeric vector, or list of mixed types specifying
  the path to the value

- value:

  Value to set at the path

- create_intermediate:

  Logical. If TRUE, creates intermediate maps as needed. Default TRUE.

## Value

The document (invisibly)

## Examples

``` r
doc <- am_create()

# Create nested structure with automatic intermediate objects
am_put_path(doc, c("user", "address", "city"), "Boston")
am_put_path(doc, c("user", "address", "zip"), 02101L)
am_put_path(doc, c("user", "name"), "Alice")

# Verify
am_get_path(doc, c("user", "address", "city"))  # "Boston"
#> [1] "Boston"
```
