# Get the last change made by the local actor

Returns the most recent change created by this document's actor. Useful
for tracking local changes or implementing undo/redo functionality.

## Usage

``` r
am_get_last_local_change(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A raw vector containing the serialized change, or `NULL` if no local
changes have been made.

## Examples

``` r
doc <- am_create()

# Initially, no local changes
am_get_last_local_change(doc)  # NULL
#> NULL

# Make a change
doc$key <- "value"
am_commit(doc, "Add key")

# Now we have a local change
change <- am_get_last_local_change(doc)
str(change)  # Raw vector
#>  raw [1:70] 85 6f 4a 83 ...
```
