# automerge

<!-- badges: start -->
<!-- badges: end -->

R Bindings for the Automerge CRDT Library

## Overview

`automerge` provides R bindings to the [Automerge](https://automerge.org/) Conflict-free Replicated Data Type (CRDT) library via its C FFI. Automerge enables automatic merging of concurrent changes without conflicts, making it ideal for:

- Distributed systems
- Collaborative applications
- Offline-first architectures
- Cross-platform data synchronization

## Features

- Full support for Automerge data types: maps, lists, text, counters
- R-idiomatic functional API with S3 methods
- Low-level and high-level synchronization protocols
- Seamless interoperability with JavaScript and other Automerge implementations
- Zero runtime dependencies (only base R)

## Installation

### From Source (Development Version)

```r
# Install from GitHub
remotes::install_github("posit-dev/automerge-r")
```

### System Requirements

To build from source, you need:

- R >= 4.1.0
- Rust toolchain >= 1.89.0 - Install from https://rustup.rs/
- CMake >= 3.25 - Included in Rtools43+ on Windows

Alternatively, install `automerge-c` system-wide to skip the source build.

## Status

🚧 **Under Active Development** 🚧

This package is currently in the initial development phase. Core functionality is not yet implemented and any existing functionality is subject to change at any time.

## Example Usage

```r
library(automerge)

# Create a document
doc <- am_create()
am_put(doc, AM_ROOT, "name", "Alice")
am_put(doc, AM_ROOT, "age", 30L)

# S3 methods
doc$name <- "Alice"
doc$age <- 30L
doc[["active"]] <- TRUE

# Access with $ and [[
doc$name       # "Alice"
doc[["age"]]   # 30L

# Single-call nested structure creation
doc$user <- list(
    name = "Bob",
    age = 25L,
    address = list(city = "NYC", zip = 10001L)
)

# Nested object access and modification
user <- doc$user
user$email <- "bob@example.com"

# Advanced types
doc$created <- Sys.time()  # POSIXct timestamp
doc$score <- am_counter(0)  # Counter
doc$notes <- am_text("Initial content")  # Text object

# Text operations
text_obj <- doc$notes
am_text_splice(doc, text_obj$obj_id, 9, 0, "new ")
content <- am_text_get(doc, text_obj$obj_id)

# Utility methods
length(doc)    # Number of keys in root
names(doc)     # Key names
as.list(doc)   # Convert to R list

# Document lifecycle
am_commit(doc, "Initial data")
bytes <- am_save(doc)
doc2 <- am_load(bytes)
doc3 <- am_fork(doc)
am_merge(doc, doc3)

# Coming soon: sync protocol (planned)
# result <- am_sync_bidirectional(doc, doc2)
```

## Resources

- [Automerge Website](https://automerge.org/)
- [Automerge GitHub](https://github.com/automerge/automerge)
