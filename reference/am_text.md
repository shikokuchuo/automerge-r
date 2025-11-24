# Create an Automerge text object

Creates a text object for collaborative character-level editing. Unlike
regular strings (which use last-write-wins semantics), text objects
support character-level CRDT merging of concurrent edits, cursor
stability, and marks/formatting.

## Usage

``` r
am_text(initial = "")
```

## Arguments

- initial:

  Initial text content (default "")

## Value

A character vector with class `am_text_type`

## Details

Use text objects for collaborative document editing. Use regular strings
for metadata, labels, and IDs (99\\

## Examples

``` r
# Empty text object
am_text()
#> [1] ""
#> attr(,"class")
#> [1] "am_text_type" "character"   

# Text with initial content
am_text("Hello, World!")
#> [1] "Hello, World!"
#> attr(,"class")
#> [1] "am_text_type" "character"   
```
