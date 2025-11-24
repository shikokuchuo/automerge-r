# Replace in Automerge object

Replace or insert values in an Automerge object using `[[<-` or `$<-`.

## Usage

``` r
# S3 method for class 'am_object'
x[[i]] <- value

# S3 method for class 'am_object'
x$name <- value
```

## Arguments

- x:

  An Automerge object

- i:

  Key name (character) for maps, or position (integer) for lists

- value:

  Value to store

- name:

  Key name (for `$<-` operator, maps only)

## Value

The object (invisibly)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L))
user <- am_get(doc, AM_ROOT, "user")

user[["name"]] <- "Alice"
user$age <- 30L
```
