# Put a value into an Automerge map or list

Inserts or updates a value in an Automerge map or list. The function
automatically dispatches to the appropriate operation based on the
object type and key/position type.

## Usage

``` r
am_put(doc, obj, key, value)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (from nested object), or `AM_ROOT` for the
  document root

- key:

  For maps: character string key. For lists: numeric position (1-based)
  or `"end"` to append

- value:

  The value to store. Supported types:

  - `NULL` - stores null

  - Logical - stores boolean (must be scalar)

  - Integer - stores integer (must be scalar)

  - Numeric - stores double (must be scalar)

  - Character - stores string (must be scalar)

  - Raw - stores bytes

  - `AM_OBJ_TYPE_LIST/MAP/TEXT` - creates nested object

## Value

The document `doc` (invisibly).

## Examples

``` r
doc <- am_create()

# Put values in root map (returns doc invisibly)
am_put(doc, AM_ROOT, "name", "Alice")
am_put(doc, AM_ROOT, "age", 30L)
am_put(doc, AM_ROOT, "active", TRUE)

# Create nested list and retrieve it
am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
items <- am_get(doc, AM_ROOT, "items")
```
