# Extract from Automerge object

Extract values from an Automerge object (map or list) using `[[` or `$`.

## Usage

``` r
# S3 method for class 'am_object'
x[[i]]

# S3 method for class 'am_object'
x$name
```

## Arguments

- x:

  An Automerge object

- i:

  Key name (character) for maps, or position (integer) for lists

- name:

  Key name (for `$` operator, maps only)

## Value

The value at the specified key/position

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L))
user <- am_get(doc, AM_ROOT, "user")

user[["name"]]  # "Bob"
#> [1] "Bob"
user$age        # 25L
#> [1] 25
```
