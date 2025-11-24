# Get changes since specified heads

Returns all changes that have been made to the document since the
specified heads. If `heads` is `NULL`, returns all changes in the
document's history.

## Usage

``` r
am_get_changes(doc, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- heads:

  A list of raw vectors (change hashes) returned by
  [`am_get_heads()`](http://shikokuchuo.net/automerge-r/reference/am_get_heads.md),
  or `NULL` to get all changes.

## Value

A list of raw vectors, each containing a serialized change.

## Details

Changes are returned as serialized raw vectors that can be transmitted
over the network and applied to other documents using
[`am_apply_changes()`](http://shikokuchuo.net/automerge-r/reference/am_apply_changes.md).

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_commit(doc)

# Get all changes
all_changes <- am_get_changes(doc, NULL)
cat("Document has", length(all_changes), "change(s)\n")
#> Document has 1 change(s)
```
