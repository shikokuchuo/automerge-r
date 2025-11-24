# Create an Automerge counter

Creates a counter value for use with Automerge. Counters are CRDT types
that support conflict-free increment and decrement operations.

## Usage

``` r
am_counter(value = 0L)
```

## Arguments

- value:

  Initial counter value (default 0)

## Value

An `am_counter` object

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "score", am_counter(0))
```
