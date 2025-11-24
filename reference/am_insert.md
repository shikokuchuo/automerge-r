# Insert a value into an Automerge list

This is an alias for
[`am_put()`](http://shikokuchuo.net/automerge-r/reference/am_put.md)
with insert semantics for lists. For lists,
[`am_put()`](http://shikokuchuo.net/automerge-r/reference/am_put.md)
with a numeric position replaces the element at that position, while
`am_insert()` shifts elements to make room.

## Usage

``` r
am_insert(doc, obj, pos, value)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (must be a list)

- pos:

  Numeric position (1-based) where to insert, or `"end"` to append

- value:

  The value to insert

## Value

The document `doc` (invisibly)

## Examples

``` r
doc <- am_create()
# Create a list and get it
am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
items <- am_get(doc, AM_ROOT, "items")

# Insert items
# am_insert(doc, items, "end", "first")
# am_insert(doc, items, "end", "second")
```
