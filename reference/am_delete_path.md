# Delete value at path

Delete a value from an Automerge document using a path vector.

## Usage

``` r
am_delete_path(doc, path)
```

## Arguments

- doc:

  An Automerge document

- path:

  Character vector, numeric vector, or list of mixed types specifying
  the path to the value to delete

## Value

The document (invisibly)

## Examples

``` r
doc <- am_create()
am_put_path(doc, c("user", "address", "city"), "NYC")
am_put_path(doc, c("user", "name"), "Alice")

# Delete nested key
am_delete_path(doc, c("user", "address"))

# Address should be gone
am_get_path(doc, c("user", "address"))  # NULL
#> NULL
```
