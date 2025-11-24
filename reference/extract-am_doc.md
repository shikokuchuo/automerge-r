# Extract from Automerge document root

Extract values from the root of an Automerge document using `[[` or `$`.
These operators provide R-idiomatic access to document data.

## Usage

``` r
# S3 method for class 'am_doc'
x[[i]]

# S3 method for class 'am_doc'
x$name
```

## Arguments

- x:

  An Automerge document

- i:

  Key name (character)

- name:

  Key name (for `$` operator)

## Value

The value at the specified key

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "name", "Alice")
am_put(doc, AM_ROOT, "age", 30L)

doc[["name"]]  # "Alice"
#> [1] "Alice"
doc$age        # 30L
#> [1] 30
```
