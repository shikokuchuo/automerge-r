# Save an Automerge document to binary format

Serializes an Automerge document to the standard binary format, which
can be saved to disk or transmitted over a network. The binary format is
compatible across all Automerge implementations (JavaScript, Rust,
etc.).

## Usage

``` r
am_save(doc)
```

## Arguments

- doc:

  An Automerge document (created with
  [`am_create()`](http://shikokuchuo.net/automerge-r/reference/am_create.md)
  or
  [`am_load()`](http://shikokuchuo.net/automerge-r/reference/am_load.md))

## Value

A raw vector containing the serialized document

## Examples

``` r
doc <- am_create()
bytes <- am_save(doc)

# Save to file
if (FALSE) { # \dontrun{
writeBin(am_save(doc), "document.automerge")
} # }
```
