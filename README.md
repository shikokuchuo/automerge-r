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

## Example Usage (Planned)

```r
library(automerge)

# Create a document
doc <- am_create()
am_put(doc, AM_ROOT, "name", "Alice")
am_put(doc, AM_ROOT, "age", 30L)

# Single-call nested structure creation (Phase 3 ✅)
am_put(doc, AM_ROOT, "user", list(
    name = "Bob",
    age = 25L,
    address = list(city = "NYC", zip = 10001L)
))

# Advanced types
am_put(doc, AM_ROOT, "created", Sys.time())  # POSIXct timestamp
am_put(doc, AM_ROOT, "score", am_counter(0))  # Counter
am_put(doc, AM_ROOT, "notes", am_text("Initial content"))  # Text object

# Text operations
text_obj <- am_get(doc, AM_ROOT, "notes")
am_text_splice(doc, text_obj$obj_id, 9, 0, "new ")
content <- am_text_get(doc, text_obj$obj_id)

# Document lifecycle
am_commit(doc, "Initial data")
bytes <- am_save(doc)
doc2 <- am_load(bytes)
doc3 <- am_fork(doc)
am_merge(doc, doc3)

# Coming soon: S3 methods and sync protocol
# doc[["name"]]  # Planned
# result <- am_sync_bidirectional(doc, doc2)  # Planned
```

## Resources

- [Automerge Website](https://automerge.org/)
- [Automerge GitHub](https://github.com/automerge/automerge)
