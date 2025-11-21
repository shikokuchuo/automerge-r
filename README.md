
<!-- README.md is generated from README.Rmd. Please edit that file -->

# automerge

<!-- badges: start -->

[![R-CMD-check](https://github.com/shikokuchuo/automerge-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/shikokuchuo/automerge-r/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/shikokuchuo/automerge-r/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/automerge-r)
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

- Rust toolchain \>= 1.89.0 - Install from <https://rustup.rs/>
- CMake \>= 3.25 - Included in Rtools43+ on Windows

Alternatively, install `automerge-c` (with UTF-32 character indexing
enabled) system-wide to skip the source build.

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
doc$age <- 20L
doc[["active"]] <- TRUE
doc
#> <Automerge Document>
#> Actor: 40b2c02a11b397ce63f3b20260d9c4a6 
#> Root keys: 3 
#> Keys: active, age, name
```

### Reading Values

Access values just like a regular R list:

``` r
doc$name
#> [1] "Alice"
doc[["age"]]
#> [1] 20
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
#> <Automerge Map>
#> Length: 4 
#> Keys: address, age, email, name
```

### Advanced Types

Automerge supports specialized CRDT types:

``` r
doc$created <- Sys.time() # POSIXct timestamp
doc$score <- am_counter(0) # Counter
doc$notes <- am_text("世界") # Text object with CRDT semantics
```

### Working with Text

Text objects support fine-grained editing:

``` r
text_obj <- doc$notes
text_obj
#> <Automerge Text>
#> Length: 2 characters
#> Content: "世界"
am_text_splice(text_obj, 2, 0, "🌍")
am_text_get(text_obj)
#> [1] "世界🌍"
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
#> [1] 20
#> 
#> $created
#> [1] "2025-11-21 21:27:22 GMT"
#> 
#> $name
#> [1] "Alice"
#> 
#> $notes
#> [1] "世界🌍"
#> 
#> $score
#> <Automerge Counter: 0 >
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
str(bytes)
#>  raw [1:329] 85 6f 4a 83 ...

doc2 <- am_load(bytes)
doc2
#> <Automerge Document>
#> Actor: 73e24f46aac44f0ca0f161352fadddae 
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
am_put(doc, AM_ROOT, "age", 20L)
doc
#> <Automerge Document>
#> Actor: 30fd8db35ed7fc4efafbec341d8e8c7b 
#> Root keys: 2 
#> Keys: age, name
```

## Synchronization

Automerge’s core strength is automatic synchronization of concurrent
changes across multiple documents. The package provides both low-level
sync protocol access and high-level convenience functions.

### Basic Synchronization

The simplest way to sync two documents:

``` r
# Create two documents with different changes
doc1 <- am_create()
doc1$x <- 1
doc1$y <- 2
am_commit(doc1, "Add x and y")

doc2 <- am_create()
doc2$a <- "hello"
doc2$b <- "world"
am_commit(doc2, "Add a and b")

# Synchronize them automatically
result <- am_sync_bidirectional(doc1, doc2)
cat("Synced in", result$rounds, "rounds\n")
#> Synced in 4 rounds

# Both documents now have all keys
doc1
#> <Automerge Document>
#> Actor: c876dd6374e7b9260c3f7cb48d62742a 
#> Root keys: 4 
#> Keys: a, b, x, y
doc2
#> <Automerge Document>
#> Actor: b35a314493b0c738f9f328b59c963ba1 
#> Root keys: 4 
#> Keys: a, b, x, y
```

### Concurrent Edits

Automerge automatically resolves conflicts from concurrent edits:

``` r
# Start with a synchronized document
doc1 <- am_create()
doc1$counter <- 0
am_commit(doc1)

# Fork to create independent copy
doc2 <- am_fork(doc1)

# Make different changes in each document
doc1$counter <- 10
doc1$edited_by <- "Alice"
am_commit(doc1, "Alice's changes")

doc2$counter <- 20
doc2$edited_by <- "Bob"
am_commit(doc2, "Bob's changes")

# Sync automatically resolves conflicts
am_sync_bidirectional(doc1, doc2)
#> $doc1
#> <Automerge Document>
#> Actor: 38b6cf2505a2cf75fca0fc17b6d78274 
#> Root keys: 2 
#> Keys: counter, edited_by 
#> 
#> $doc2
#> <Automerge Document>
#> Actor: 9d03c194b42e281c4adfd90f34a64482 
#> Root keys: 2 
#> Keys: counter, edited_by 
#> 
#> $rounds
#> [1] 5
#> 
#> $converged
#> [1] TRUE

# Both documents converge to the same state
# The counter value is deterministically chosen (CRDT semantics)
doc1$counter == doc2$counter
#> [1] TRUE
doc1$edited_by == doc2$edited_by
#> [1] TRUE
```

### Manual Change Management

For custom sync workflows, use the low-level change tracking API:

``` r
# Track document history
doc <- am_create()
doc$version <- 1
am_commit(doc, "v1")

doc$version <- 2
am_commit(doc, "v2")

# Get all changes
changes <- am_get_changes(doc, NULL)
cat("Number of changes:", length(changes), "\n")
#> Number of changes: 2

# Apply changes to another document
doc_replica <- am_create()
am_apply_changes(doc_replica, changes)

doc_replica$version
#> [1] 2
```

### Low-Level Sync Protocol

For network synchronization or custom protocols:

``` r
# Create two documents with different data
doc1 <- am_create()
doc1$from_doc1 <- "Alice's data"
doc1$priority <- 1L
am_commit(doc1)

doc2 <- am_create()
doc2$from_doc2 <- "Bob's data"
doc2$priority <- 2L
am_commit(doc2)

# Create sync states (one per peer)
sync1 <- am_sync_state_new()
sync2 <- am_sync_state_new()

# Generate sync message from doc1
msg <- am_sync_encode(doc1, sync1)

# Receive and apply on doc2
am_sync_decode(doc2, sync2, msg)

# Generate response from doc2
response <- am_sync_encode(doc2, sync2)

# Continue until both return NULL (converged)
while (!is.null(response)) {
  am_sync_decode(doc1, sync1, response)
  response <- am_sync_encode(doc1, sync1)
  if (!is.null(response)) {
    am_sync_decode(doc2, sync2, response)
    response <- am_sync_encode(doc2, sync2)
  }
}

# Documents after sync
doc1
#> <Automerge Document>
#> Actor: fd2453d3dbb4c1092b9d237782223b20 
#> Root keys: 3 
#> Keys: from_doc1, from_doc2, priority
doc2
#> <Automerge Document>
#> Actor: 664a71bb523fe0ea1eab12166d4297f2 
#> Root keys: 3 
#> Keys: from_doc1, from_doc2, priority
```

### Document Heads

Track document state with change hashes:

``` r
doc <- am_create()
doc$data <- "initial"
am_commit(doc)

# Get current heads (change hashes)
heads <- am_get_heads(doc)
cat("Number of heads:", length(heads), "\n")
#> Number of heads: 1

# Make more changes
doc$data <- "updated"
am_commit(doc)

# Heads have changed
new_heads <- am_get_heads(doc)
identical(heads, new_heads)
#> [1] FALSE
```

### Use Cases

**Distributed Systems**: Sync R sessions across multiple machines

``` r
# On machine 1
doc1 <- am_create()
doc1$results <- list(mean = 42, sd = 5)
am_commit(doc1)
temp_file <- tempfile(fileext = ".rds")
saveRDS(am_save(doc1), temp_file)

# On machine 2
doc2 <- am_load(readRDS(temp_file))
doc2$additional_analysis <- list(median = 41, iqr = 8)
am_commit(doc2)
doc2
#> <Automerge Document>
#> Actor: e17d3b442844789d1431ce6aa01cffc6 
#> Root keys: 2 
#> Keys: additional_analysis, results
```

**Collaborative Analysis**: Multiple analysts working on the same
dataset

``` r
# Analyst A adds model results
doc_a <- am_create()
doc_a$model_a <- list(accuracy = 0.95, f1 = 0.93)
am_commit(doc_a, "Model A results")

# Analyst B adds different model (concurrent)
doc_b <- am_create()
doc_b$model_b <- list(accuracy = 0.97, f1 = 0.94)
am_commit(doc_b, "Model B results")

# Sync merges both contributions automatically
am_sync_bidirectional(doc_a, doc_b)
#> $doc1
#> <Automerge Document>
#> Actor: b3393ec9f392f049bd77b739cd0b331d 
#> Root keys: 2 
#> Keys: model_a, model_b 
#> 
#> $doc2
#> <Automerge Document>
#> Actor: 6013da91127e8489f859c0b13c503645 
#> Root keys: 2 
#> Keys: model_a, model_b 
#> 
#> $rounds
#> [1] 4
#> 
#> $converged
#> [1] TRUE

# Both documents now have all models
names(doc_a)
#> [1] "model_a" "model_b"
names(doc_b)
#> [1] "model_a" "model_b"
```

**Offline-First Workflows**: Make changes offline, sync when connected

``` r
# Work offline
offline_doc <- am_create()
offline_doc$field_data <- list(
  temp = 23.5,
  humidity = 65,
  timestamp = Sys.time()
)
am_commit(offline_doc, "Offline data collection")

# Central repository has other data
central_doc <- am_create()
central_doc$processed_data <- list(status = "ready", samples = 100L)
am_commit(central_doc, "Central data")

# Later, sync with central repository
am_sync_bidirectional(offline_doc, central_doc)
#> $doc1
#> <Automerge Document>
#> Actor: 88603aabe04ef6d3bbff4d914566f9de 
#> Root keys: 2 
#> Keys: field_data, processed_data 
#> 
#> $doc2
#> <Automerge Document>
#> Actor: f90a5ab2d7e4df48a818f570fee7f5bd 
#> Root keys: 2 
#> Keys: field_data, processed_data 
#> 
#> $rounds
#> [1] 4
#> 
#> $converged
#> [1] TRUE

# Both documents have all data
names(offline_doc)
#> [1] "field_data"     "processed_data"
names(central_doc)
#> [1] "field_data"     "processed_data"
```

## Resources

- [Automerge Website](https://automerge.org/)
- [Automerge GitHub](https://github.com/automerge/automerge)
