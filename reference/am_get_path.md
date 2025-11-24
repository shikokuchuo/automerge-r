# Navigate deep structures with path

Get a value from an Automerge document using a path vector. The path can
contain character keys (for maps), numeric indices (for lists, 1-based),
or a mix of both.

## Usage

``` r
am_get_path(doc, path)
```

## Arguments

- doc:

  An Automerge document

- path:

  Character vector, numeric vector, or list of mixed types specifying
  the path to navigate

## Value

The value at the path, or NULL if not found

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "user", list(
  name = "Alice",
  address = list(city = "NYC", zip = 10001L)
))

# Navigate to nested value
am_get_path(doc, c("user", "address", "city"))  # "NYC"
#> [1] "NYC"

# Mixed navigation (map key, then list index)
doc$users <- list(
  list(name = "Bob"),
  list(name = "Carol")
)
am_get_path(doc, list("users", 1, "name"))  # "Bob"
#> [1] "Bob"
```
