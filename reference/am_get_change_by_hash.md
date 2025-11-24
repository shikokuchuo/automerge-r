# Get a specific change by its hash

Retrieves a change from the document's history by its unique hash
identifier. The hash is typically obtained from
[`am_get_heads()`](http://shikokuchuo.net/automerge-r/reference/am_get_heads.md)
or
[`am_get_changes()`](http://shikokuchuo.net/automerge-r/reference/am_get_changes.md).

## Usage

``` r
am_get_change_by_hash(doc, hash)
```

## Arguments

- doc:

  An Automerge document

- hash:

  A raw vector containing the change hash (must be exactly 32 bytes)

## Value

A raw vector containing the serialized change, or `NULL` if the change
hash is not found in the document.

## Examples

``` r
doc <- am_create()
doc$key <- "value"
am_commit(doc, "Add key")

# Get the current heads (change hashes)
heads <- am_get_heads(doc)
head_hash <- heads[[1]]

# Retrieve the change by its hash
change <- am_get_change_by_hash(doc, head_hash)
str(change)  # Raw vector
#>  raw [1:70] 85 6f 4a 83 ...
```
