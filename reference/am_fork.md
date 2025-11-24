# Fork an Automerge document

Creates a fork of an Automerge document at the current heads or at a
specific point in history. The forked document shares history with the
original up to the fork point but can diverge afterwards.

## Usage

``` r
am_fork(doc, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- heads:

  Optional list of change hashes to fork at a specific point in the
  document's history. If `NULL` (default) or an empty list, forks at
  current heads. Each hash should be a raw vector (32 bytes).

## Value

A new Automerge document (fork of the original)

## Examples

``` r
doc1 <- am_create()
doc2 <- am_fork(doc1)

# Now doc1 and doc2 can diverge independently
```
