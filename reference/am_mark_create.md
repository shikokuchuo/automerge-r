# Create a mark on a text range

Marks attach metadata or formatting information to a range of text.
Unlike simple annotations, marks are CRDT-aware and merge correctly
across concurrent edits.

## Usage

``` r
am_mark_create(obj, start, end, name, value, expand = AM_MARK_EXPAND_NONE)
```

## Arguments

- obj:

  An Automerge object ID (must be a text object)

- start:

  Integer start position (0-based inter-character position, inclusive)

- end:

  Integer end position (0-based inter-character position, exclusive)

- name:

  Character string identifying the mark (e.g., "bold", "comment")

- value:

  The mark's value (any Automerge-compatible type: NULL, logical,
  integer, numeric, character, raw, POSIXct, or am_counter)

- expand:

  Character string controlling mark expansion behavior when text is
  inserted at boundaries. Options:

  "none"

  :   Mark does not expand (default)

  "before"

  :   Mark expands to include text inserted before start

  "after"

  :   Mark expands to include text inserted after end

  "both"

  :   Mark expands in both directions

  Use the constants
  [AM_MARK_EXPAND_NONE](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md),
  [AM_MARK_EXPAND_BEFORE](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md),
  [AM_MARK_EXPAND_AFTER](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md),
  or
  [AM_MARK_EXPAND_BOTH](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md).

## Value

The text object `obj` (invisibly)

## Indexing Convention

**Mark positions use 0-based indexing** (unlike list indices which are
1-based). Positions specify locations **between** characters. The range
`[start, end)` includes `start` but excludes `end`.

For the text "Hello":

      H e l l o
     0 1 2 3 4 5  <- positions (0-based, between characters)

Marking positions 0 to 5 marks all 5 characters. Marking 0 to 3 marks
"Hel". Positions count Unicode code points (characters), not bytes.

## Expand Behavior

The `expand` parameter controls what happens when text is inserted
exactly at the mark boundaries:

- `"none"`: New text is never included in the mark

- `"before"`: Text inserted at `start` is included

- `"after"`: Text inserted at `end` is included

- `"both"`: Text inserted at either boundary is included

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

# Mark "Hello" as bold (positions 0-4, characters 0-4)
am_mark_create(text_obj, 0, 5, "bold", TRUE)

# Mark "World" as italic with expansion
am_mark_create(text_obj, 6, 11, "italic", TRUE,
               expand = AM_MARK_EXPAND_BOTH)

# Get all marks
marks <- am_marks(text_obj)
print(marks)
#> [[1]]
#> [[1]]$name
#> [1] "bold"
#> 
#> [[1]]$value
#> [1] TRUE
#> 
#> [[1]]$start
#> [1] 0
#> 
#> [[1]]$end
#> [1] 5
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "italic"
#> 
#> [[2]]$value
#> [1] TRUE
#> 
#> [[2]]$start
#> [1] 6
#> 
#> [[2]]$end
#> [1] 11
#> 
#> 
```
