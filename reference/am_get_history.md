# Get document history

Returns the full change history of the document as a list of change
metadata. This provides a simpler interface than
[`am_get_changes()`](http://shikokuchuo.net/automerge-r/reference/am_get_changes.md)
for examining document history without needing to work with serialized
changes directly.

## Usage

``` r
am_get_history(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A list of raw vectors (serialized changes), one for each change in the
document's history, in chronological order.

## Details

**Note**: A future implementation will add detailed change introspection
functions to extract metadata like commit messages, timestamps, actor
IDs, etc.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_commit(doc, "Initial")
am_put(doc, AM_ROOT, "x", 2)
am_commit(doc, "Update")

history <- am_get_history(doc)
cat("Document history contains", length(history), "change(s)\n")
#> Document history contains 2 change(s)
```
