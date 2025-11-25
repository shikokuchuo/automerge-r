# Merge changes from another document

Merges all changes from another Automerge document into this one. This
is a one-way merge: changes flow from `other` into `doc`, but `other` is
not modified. For bidirectional synchronization, use
[`am_sync()`](http://shikokuchuo.net/automerge-r/reference/am_sync.md).

## Usage

``` r
am_merge(doc, other)
```

## Arguments

- doc:

  Target document (will receive changes)

- other:

  Source document (provides changes)

## Value

The target document `doc` (invisibly)

## Examples

``` r
doc1 <- am_create()
doc2 <- am_create()

# Make changes in each document
am_put(doc1, AM_ROOT, "x", 1)
am_put(doc2, AM_ROOT, "y", 2)

# Merge doc2's changes into doc1
am_merge(doc1, doc2)
# Now doc1 has both x and y
```
