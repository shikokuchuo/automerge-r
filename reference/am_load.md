# Load an Automerge document from binary format

Deserializes an Automerge document from the standard binary format. The
binary format is compatible across all Automerge implementations
(JavaScript, Rust, etc.).

## Usage

``` r
am_load(data)
```

## Arguments

- data:

  A raw vector containing a serialized Automerge document

## Value

An external pointer to the Automerge document with class
`c("am_doc", "automerge")`.

## Examples

``` r
# Create, save, and reload
doc1 <- am_create()
bytes <- am_save(doc1)
doc2 <- am_load(bytes)

# Load from file
if (FALSE) { # \dontrun{
doc <- am_load(readBin("document.automerge", "raw", 1e7))
} # }
```
