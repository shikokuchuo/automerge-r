# Replace in Automerge document root

Replace or insert values at the root of an Automerge document using
`[[<-` or `$<-`. These operators provide R-idiomatic modification.

## Usage

``` r
# S3 method for class 'am_doc'
x[[i]] <- value

# S3 method for class 'am_doc'
x$name <- value
```

## Arguments

- x:

  An Automerge document

- i:

  Key name (character)

- value:

  Value to store

- name:

  Key name (for `$<-` operator)

## Value

The document (invisibly)

## Examples

``` r
doc <- am_create()
doc[["name"]] <- "Bob"
doc$age <- 25L
```
