# Bidirectional synchronization

Automatically synchronizes two documents by exchanging messages until
they converge to the same state. This is a high-level convenience
function that handles the entire sync protocol automatically.

## Usage

``` r
am_sync_bidirectional(doc1, doc2, max_rounds = 100)
```

## Arguments

- doc1:

  First Automerge document

- doc2:

  Second Automerge document

- max_rounds:

  Maximum number of message exchange rounds (default: 100). If this
  limit is reached, an error is raised.

## Value

A list with components:

- doc1:

  The first document (updated with changes from doc2)

- doc2:

  The second document (updated with changes from doc1)

- rounds:

  Number of sync rounds completed

- converged:

  Logical indicating if sync converged successfully

## Details

The function exchanges sync messages back and forth between the two
documents until both sides report no more messages to send
([`am_sync_encode()`](http://shikokuchuo.net/automerge-r/reference/am_sync_encode.md)
returns `NULL`). A maximum number of rounds prevents infinite loops in
case of errors.

## Examples

``` r
# Create two documents with different changes
doc1 <- am_create()
doc2 <- am_create()

# Make changes in each document
am_put(doc1, AM_ROOT, "x", 1)
am_put(doc2, AM_ROOT, "y", 2)

# Synchronize them
result <- am_sync_bidirectional(doc1, doc2)
cat("Synced in", result$rounds, "rounds\n")
#> Synced in 4 rounds

# Now both documents have both x and y
```
