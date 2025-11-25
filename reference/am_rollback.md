# Roll back pending operations

Cancels all pending operations in the current transaction without
committing them. This allows you to discard changes since the last
commit.

## Usage

``` r
am_rollback(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

The document `doc` (invisibly)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
# Changed my mind, discard the put
am_rollback(doc)
```
