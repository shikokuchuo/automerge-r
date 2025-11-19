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
doc <- am_create() |>
    am_put(AM_ROOT, "name", "Alice") |>
    am_put(AM_ROOT, "age", 30) |>
    am_commit("Initial data")

# Access data
doc[["name"]]  # "Alice"

# Nested structures
am_put(doc, AM_ROOT, "user", list(
    name = "Bob",
    age = 25,
    address = list(city = "NYC", zip = 10001L)
))

# Synchronization
doc2 <- am_create()
result <- am_sync_bidirectional(doc, doc2)
```

## Resources

- [Automerge Website](https://automerge.org/)
- [Automerge GitHub](https://github.com/automerge/automerge)
