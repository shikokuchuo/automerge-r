# Apply changes to a document

Applies a list of changes (obtained from
[`am_get_changes()`](http://shikokuchuo.net/automerge-r/reference/am_get_changes.md))
to a document. This is useful for manually syncing changes or for
applying changes received over a custom network protocol.

## Usage

``` r
am_apply_changes(doc, changes)
```

## Arguments

- doc:

  An Automerge document

- changes:

  A list of raw vectors (serialized changes) from
  [`am_get_changes()`](http://shikokuchuo.net/automerge-r/reference/am_get_changes.md)

## Value

The document `doc` (invisibly, for chaining)

## Examples

``` r
# Create two documents
doc1 <- am_create()
doc2 <- am_create()

# Make changes in doc1
am_put(doc1, AM_ROOT, "x", 1)
am_commit(doc1)

# Get changes and apply to doc2
changes <- am_get_changes(doc1, NULL)
am_apply_changes(doc2, changes)

# Now doc2 has the same data as doc1
```
