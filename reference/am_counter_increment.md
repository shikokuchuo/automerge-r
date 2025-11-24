# Increment a counter value

Increments an Automerge counter by the specified delta. Counters are
CRDT types that support concurrent increments from multiple actors.
Unlike regular integers, counter increments are commutative and do not
conflict when merged.

## Usage

``` r
am_counter_increment(doc, obj, key, delta)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (map or list), or `AM_ROOT` for the document
  root

- key:

  For maps: a character string key. For lists: an integer position
  (1-based)

- delta:

  Integer value to add to the counter (can be negative)

## Value

The document (invisibly), allowing for chaining with pipes

## Details

The delta can be negative to decrement the counter.

## Examples

``` r
# Counter in document root (map)
doc <- am_create()
doc$score <- am_counter(0)
am_counter_increment(doc, AM_ROOT, "score", 10)
doc$score  # 10
#> <Automerge Counter: 10 >

am_counter_increment(doc, AM_ROOT, "score", 5)
doc$score  # 15
#> <Automerge Counter: 15 >

# Decrement with negative delta
am_counter_increment(doc, AM_ROOT, "score", -3)
doc$score  # 12
#> <Automerge Counter: 12 >

# Counter in a nested map
doc$stats <- am_map(views = am_counter(0))
stats_obj <- doc$stats
am_counter_increment(doc, stats_obj, "views", 100)

# Counter in a list (1-based indexing)
doc$counters <- list(am_counter(0), am_counter(5))
counters_obj <- doc$counters
am_counter_increment(doc, counters_obj, 1, 1)  # Increment first counter
am_counter_increment(doc, counters_obj, 2, 2)  # Increment second counter
```
