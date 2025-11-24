# Delete a key from a map or position from a list

Removes a key-value pair from a map or an element from a list.

## Usage

``` r
am_delete(doc, obj, key)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (from nested object), or `AM_ROOT` for the
  document root

- key:

  For maps: character string key to delete. For lists: numeric position
  (1-based) to delete

## Value

The document `doc` (invisibly)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "temp", "value")
am_delete(doc, AM_ROOT, "temp")
```
