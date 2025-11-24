# Get changes in one document that are not in another

Compares two documents and returns the changes that exist in `doc2` but
not in `doc1`. This is useful for determining what changes need to be
applied to bring `doc1` up to date with `doc2`, or for implementing
custom synchronization logic.

## Usage

``` r
am_get_changes_added(doc1, doc2)
```

## Arguments

- doc1:

  An Automerge document (base/reference document)

- doc2:

  An Automerge document (comparison document)

## Value

A list of raw vectors, where each vector is a serialized change that
exists in `doc2` but not in `doc1`. Returns an empty list if `doc1`
already contains all changes from `doc2`.

## Examples

``` r
# Create two independent documents
doc1 <- am_create()
doc1$x <- 1
am_commit(doc1, "Add x")

doc2 <- am_create()
doc2$y <- 2
am_commit(doc2, "Add y")

# Find changes in doc2 that aren't in doc1
changes <- am_get_changes_added(doc1, doc2)
length(changes)  # 1 change
#> [1] 1

# Apply those changes to doc1
am_apply_changes(doc1, changes)

# Now doc1 has both x and y
names(doc1)  # "x" "y"
#> [1] "x" "y"
```
