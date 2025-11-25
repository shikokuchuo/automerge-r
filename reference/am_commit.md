# Commit pending changes

Commits all pending operations in the current transaction, creating a
new change in the document's history. Commits can include an optional
message (like a git commit message) and timestamp.

## Usage

``` r
am_commit(doc, message = NULL, time = NULL)
```

## Arguments

- doc:

  An Automerge document

- message:

  Optional commit message (character string)

- time:

  Optional timestamp (POSIXct). If `NULL`, uses current time.

## Value

The document `doc` (invisibly)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add initial data")

# Commit with specific timestamp
am_commit(doc, "Update", Sys.time())
```
