
<!-- README.md is generated from README.Rmd. Please edit that file -->

# automerge

<!-- badges: start -->

[![R-universe
version](https://shikokuchuo.r-universe.dev/automerge/badges/version)](https://shikokuchuo.r-universe.dev/automerge)
[![R-CMD-check](https://github.com/shikokuchuo/automerge-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/shikokuchuo/automerge-r/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/shikokuchuo/automerge-r/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/automerge-r)
<!-- badges: end -->

R Bindings for the Automerge CRDT Library

## Overview

`automerge` provides R bindings to the
[Automerge](https://automerge.org/) Conflict-free Replicated Data Type
(CRDT) Rust library via its C FFI. Automerge enables automatic merging
of concurrent changes without conflicts, making it ideal for:

- Distributed systems
- Collaborative applications
- Offline-first architectures
- Cross-platform data synchronization

## Features

- Full support for Automerge data types: maps, lists, text, counters
- Cursors for stable position tracking in collaborative text editing
- Marks for attaching metadata and formatting to text ranges
- Intuitive functional API with S3 methods
- Low-level and high-level synchronization protocols
- Seamless interoperability with JavaScript and other Automerge
  implementations
- Zero runtime dependencies (only base R)

## Installation

### Development Version

``` r
install.packages("automerge", repos = "https://shikokuchuo.r-universe.dev")
```

### System Requirements

To build from source, you need:

- Rust toolchain \>= 1.89.0 - Install from <https://rustup.rs/>
- CMake \>= 3.25 - Included in Rtools43+ on Windows

Alternatively, install `automerge-c` (with UTF-32 character indexing
enabled) system-wide to skip the source build.

## Status

🚧 **Under Active Development** 🚧

This package is currently in the initial development phase. Some
functionality is yet to be implemented, and any existing functionality
is subject to change at any time.

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
#> Actor: f73b168ef41899ffa482d7fa85bcdabf 
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

### Cursors and Marks

Cursors provide stable position tracking across edits, while marks
attach metadata to text ranges. These features are essential for
collaborative text editing applications.

#### Cursors

Cursors maintain their position as text is edited:

``` r
doc <- am_create()
doc$text <- am_text("hello world")
text_obj <- doc$text

# Create cursor at position 6 (before "world")
cursor <- am_cursor(text_obj, 6)

# Insert text before the cursor
am_text_splice(text_obj, 0, 0, "XX")

# Cursor automatically adjusts
am_cursor_position(text_obj, cursor)
#> [1] 8
am_text_get(text_obj)
#> [1] "XXhello world"
```

#### Marks

Marks attach formatting or metadata to text ranges:

``` r
doc <- am_create()
doc$text <- am_text("hello world")
text_obj <- doc$text

# Mark "hello" as bold
am_mark_create(text_obj, 0, 5, "bold", TRUE)

# Mark "world" with custom metadata
am_mark_create(text_obj, 6, 11, "comment", "review this")

# Get all marks
am_marks(text_obj)
#> [[1]]
#> [[1]]$name
#> [1] "bold"
#> 
#> [[1]]$value
#> [1] TRUE
#> 
#> [[1]]$start
#> [1] 0
#> 
#> [[1]]$end
#> [1] 5
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "comment"
#> 
#> [[2]]$value
#> [1] "review this"
#> 
#> [[2]]$start
#> [1] 6
#> 
#> [[2]]$end
#> [1] 11

# Get marks at specific position
am_marks_at(text_obj, 2)
#> [[1]]
#> [[1]]$name
#> [1] "bold"
#> 
#> [[1]]$value
#> [1] TRUE
#> 
#> [[1]]$start
#> [1] 0
#> 
#> [[1]]$end
#> [1] 5
```

Marks support expansion modes that control behavior at boundaries:

``` r
# Create mark with expansion
am_mark_create(
  text_obj,
  0,
  5,
  "highlight",
  TRUE,
  expand = AM_MARK_EXPAND_BOTH
)
```

Expansion modes:

- `AM_MARK_EXPAND_NONE`: Mark doesn’t expand (default)
- `AM_MARK_EXPAND_BEFORE`: Expands to include text inserted before start
- `AM_MARK_EXPAND_AFTER`: Expands to include text inserted after end
- `AM_MARK_EXPAND_BOTH`: Expands in both directions

### Utility Methods

Standard R operations work as expected:

``` r
length(doc) # Number of keys
#> [1] 1
names(doc) # Key names
#> [1] "text"
as.list(doc) # Convert to R list
#> $text
#> [1] "hello world"
```

### Saving and Loading

Persist documents to disk or transfer over network:

``` r
doc |> am_commit("Initial data")
bytes <- am_save(doc)
str(bytes)
#>  raw [1:283] 85 6f 4a 83 ...

doc2 <- am_load(bytes)
doc2
#> <Automerge Document>
#> Actor: 6a57e5109d631ff8286c13400f04f6c4 
#> Root keys: 1 
#> Keys: text
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
#> Actor: bf0a9a5446f5fbe1ab99fce32cbfa725 
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
#> Actor: 95a9f094a9b2465b68b23e01cbb9fea4 
#> Root keys: 4 
#> Keys: a, b, x, y
doc2
#> <Automerge Document>
#> Actor: 428aa23eed432f48e9ca3752a2a8e3f1 
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
#> Actor: f638fa0fb9ab2e97013196f53ad5a3e3 
#> Root keys: 2 
#> Keys: counter, edited_by 
#> 
#> $doc2
#> <Automerge Document>
#> Actor: 2831b64c7713f956fb792f0daf5f1d51 
#> Root keys: 2 
#> Keys: counter, edited_by 
#> 
#> $rounds
#> [1] 4
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
#> Actor: 3466ec58947670110392124661b7ebb2 
#> Root keys: 3 
#> Keys: from_doc1, from_doc2, priority
doc2
#> <Automerge Document>
#> Actor: ed8cc28291f783693f80262d21b3c3e8 
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
#> Actor: 4eba1d6075a94f8f88e03193b3da8009 
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
#> Actor: 6d6155f75703ba05a95868ab24ab20cc 
#> Root keys: 2 
#> Keys: model_a, model_b 
#> 
#> $doc2
#> <Automerge Document>
#> Actor: afdeabdf6923c1c3c82f8189913fa62b 
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
#> Actor: 4b2b2e1597d9a9f9247feea91256ba6f 
#> Root keys: 2 
#> Keys: field_data, processed_data 
#> 
#> $doc2
#> <Automerge Document>
#> Actor: be100cddf3387b05fa833516de4f53fb 
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
