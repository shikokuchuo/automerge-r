# Get a value from an Automerge map or list

Retrieves a value from an Automerge map or list. Returns `NULL` if the
key or index doesn't exist.

## Usage

``` r
am_get(doc, obj, key)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (from nested object), or `AM_ROOT` for the
  document root

- key:

  For maps: character string key. For lists: numeric index (1-based).
  Returns `NULL` for indices `<= 0` or beyond list length.

## Value

The value at the specified key/position, or `NULL` if not found. Nested
objects are returned as `am_object` instances.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "name", "Alice")

name <- am_get(doc, AM_ROOT, "name")
print(name)  # "Alice"
#> [1] "Alice"
```
