
<!-- README.md is generated from README.Rmd. Please edit that file -->

# automerge

<!-- badges: start -->

<!-- badges: end -->

R Bindings for the Automerge CRDT Library

## Overview

`automerge` provides R bindings to the
[Automerge](https://automerge.org/) Conflict-free Replicated Data Type
(CRDT) library via its C FFI. Automerge enables automatic merging of
concurrent changes without conflicts, making it ideal for:

- Distributed systems
- Collaborative applications
- Offline-first architectures
- Cross-platform data synchronization

## Features

- Full support for Automerge data types: maps, lists, text, counters
- Intuitive functional API with S3 methods
- Low-level and high-level synchronization protocols
- Seamless interoperability with JavaScript and other Automerge
  implementations
- Zero runtime dependencies (only base R)

## Installation

### From Source (Development Version)

``` r
# Install from GitHub
pak::pak("posit-dev/automerge-r")
```

### System Requirements

To build from source, you need:

- R \>= 4.2
- Rust toolchain \>= 1.89.0 - Install from <https://rustup.rs/>
- CMake \>= 3.25 - Included in Rtools43+ on Windows

Alternatively, install `automerge-c` system-wide to skip the source
build.

## Status

🚧 **Under Active Development** 🚧

This package is currently in the initial development phase. Core
functionality is not yet implemented and any existing functionality is
subject to change at any time.

## Example Usage

### Creating and Modifying Documents

Use familiar R syntax to work with Automerge documents:

``` r
library(automerge)

doc <- am_create()
doc$name <- "Alice"
doc$age <- 30L
doc[["active"]] <- TRUE
doc
#> <Automerge Document>
#> Actor: 015437c86004384856446f4a69264dab 
#> Root keys: 3 
#> Keys: active, age, name
```

### Reading Values

Access values just like a regular R list:

``` r
doc$name # "Alice"
#> [1] "Alice"
doc[["age"]] # 30L
#> [1] 30
```

### Nested Structures

Create complex nested objects in a single call:

``` r
doc$user <- list(
  name = "Bob",
  age = 25L,
  address = list(city = "NYC", zip = 10001L)
)
```

Nested objects work independently:

``` r
user <- doc$user
user$email <- "bob@example.com"
user
#> <Map object>
#> Length: 4 
#> Keys: address, age, email, name
```

### Advanced Types

Automerge supports specialized CRDT types:

``` r
doc$created <- Sys.time() # POSIXct timestamp
doc$score <- am_counter(0) # Counter
doc$notes <- am_text("new") # Text object with CRDT semantics
```

### Working with Text

Text objects support fine-grained editing:

``` r
text_obj <- doc$notes
am_text_splice(doc, text_obj$obj_id, 3, 0, "s")
am_text_get(doc, text_obj$obj_id)
#> [1] "news"
```

### Utility Methods

Standard R operations work as expected:

``` r
length(doc) # Number of keys
#> [1] 7
names(doc) # Key names
#> [1] "active"  "age"     "created" "name"    "notes"   "score"   "user"
as.list(doc) # Convert to R list
#> $active
#> [1] TRUE
#> 
#> $age
#> [1] 30
#> 
#> $created
#> [1] "2025-11-20 17:36:19 GMT"
#> 
#> $name
#> [1] "Alice"
#> 
#> $notes
#> $notes[[1]]
#> [1] "n"
#> 
#> $notes[[2]]
#> [1] "e"
#> 
#> $notes[[3]]
#> [1] "w"
#> 
#> $notes[[4]]
#> [1] "s"
#> 
#> 
#> $score
#> [1] 0
#> attr(,"class")
#> [1] "am_counter"
#> 
#> $user
#> $user$address
#> $user$address$city
#> [1] "NYC"
#> 
#> $user$address$zip
#> [1] 10001
#> 
#> 
#> $user$age
#> [1] 25
#> 
#> $user$email
#> [1] "bob@example.com"
#> 
#> $user$name
#> [1] "Bob"
```

### Saving and Loading

Persist documents to disk or transfer over network:

``` r
doc |> am_commit("Initial data")
bytes <- am_save(doc)
doc2 <- am_load(bytes)
doc2
#> <Automerge Document>
#> Actor: 31557e91d1114cfae0345407a9b7d7a7 
#> Root keys: 7 
#> Keys: active, age, created, name, notes, score, user
```

### Forking and Merging

Create independent copies and merge changes automatically:

``` r
doc3 <- am_fork(doc)
doc3$name <- "Charlie"

am_merge(doc, doc3)
doc$name
#> [1] "Charlie"
```

### Low-Level API

For fine-grained control, use the functional API:

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "name", "Alice")
am_put(doc, AM_ROOT, "age", 30L)
doc
#> <Automerge Document>
#> Actor: 1f2771ec270b6d79e34ca3495c9484a0 
#> Root keys: 2 
#> Keys: age, name
```

## Resources

- [Automerge Website](https://automerge.org/)
- [Automerge GitHub](https://github.com/automerge/automerge)
