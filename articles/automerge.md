# Getting Started with automerge

## What is Automerge?

Automerge is a library that enables automatic merging of concurrent
changes without conflicts. It’s built on the concept of Conflict-free
Replicated Data Types (CRDTs), which are data structures designed to be
safely replicated across multiple devices and automatically merged.

### Key Benefits

- **Automatic conflict resolution**: Multiple users can edit the same
  document simultaneously without manual conflict resolution
- **Offline-first**: Changes can be made offline and synchronized later
- **Cross-platform**: Documents created in R can be synced with
  JavaScript, Python, and other implementations
- **Version history**: Complete change history is preserved for auditing
  and debugging
- **Collaborative**: Perfect for building collaborative applications
  like shared notebooks or data pipelines

## Installation

``` r
# From R-universe
install.packages("automerge", repos = "https://shikokuchuo.r-universe.dev")

# From GitHub
pak::pak("shikokuchuo/automerge-r")
```

## Basic Usage

Let’s start with the most fundamental operations:

``` r
library(automerge)
```

### Creating a Document

``` r
doc <- am_create()
print(doc)
#> <Automerge Document>
#> Actor: a231a750ef38c0e092575c5433bae0d5 
#> Root keys: 0
```

### Adding Data - Three Approaches

Automerge provides multiple ways to add data, from functional to
R-idiomatic:

#### 1. Functional API

``` r
am_put(doc, AM_ROOT, "name", "Alice")
am_put(doc, AM_ROOT, "age", 30L)
am_put(doc, AM_ROOT, "active", TRUE)
am_commit(doc, "Initial data")

am_get(doc, AM_ROOT, "name")
#> [1] "Alice"
am_get(doc, AM_ROOT, "age")
#> [1] 30
```

#### 2. S3 Operators (R-idiomatic)

``` r
doc[["email"]] <- "alice@example.com"
doc[["score"]] <- 95.5

doc[["name"]]
#> [1] "Alice"
doc[["age"]]
#> [1] 30

# List all keys
names(doc)
#> [1] "active" "age"    "email"  "name"   "score"
```

#### 3. Pipe-Friendly Style

``` r
doc2 <- am_create() |>
  am_put(AM_ROOT, "name", "Bob") |>
  am_put(AM_ROOT, "age", 25L) |>
  am_put(AM_ROOT, "active", TRUE) |>
  am_commit("Initial setup")

doc2 |> am_get(AM_ROOT, "name")
#> [1] "Bob"
```

## Working with Nested Structures

Automerge supports nested data structures (maps within maps, lists
within maps, etc.).

### Recursive Conversion

The simplest approach is to use R’s native list structures, which are
automatically converted:

``` r
# Create document with nested structure in one call
doc3 <- am_create() |>
  am_put(
    AM_ROOT,
    "company",
    list(
      name = "Acme Corp",
      founded = 2020L,
      employees = list(
        list(name = "Alice", role = "Engineer"),
        list(name = "Bob", role = "Designer")
      ),
      office = list(
        address = list(
          street = "123 Main St",
          city = "Boston",
          zip = 02101L
        ),
        size = 5000.5
      )
    )
  ) |>
  am_commit("Add company data")

# Access nested data (verbose way)
company <- doc3[["company"]]
office <- am_get(doc3, company, "office")
address <- am_get(doc3, office, "address")
am_get(doc3, address, "city")
#> [1] "Boston"
```

### Path-Based Access

For deep structures, path-based helpers make navigation much easier:

``` r
# Much simpler - use path-based access
am_get_path(doc3, c("company", "office", "address", "city"))
#> [1] "Boston"

# Create deep structure using paths
doc4 <- am_create()

am_put_path(doc4, c("config", "database", "host"), "localhost")
am_put_path(doc4, c("config", "database", "port"), 5432L)
am_put_path(doc4, c("config", "cache", "enabled"), TRUE)
am_put_path(doc4, c("config", "cache", "ttl"), 3600L)

# Retrieve values with paths
am_get_path(doc4, c("config", "database", "host"))
#> [1] "localhost"
```

### Converting R Data Structures

Use
[`as_automerge()`](http://shikokuchuo.net/automerge-r/reference/as_automerge.md)
to convert entire R structures at once:

``` r
# Your existing R data
config_data <- list(
  app_name = "MyApp",
  version = "1.0.0",
  database = list(
    host = "localhost",
    port = 5432L,
    credentials = list(
      user = "admin",
      password_hash = "..."
    )
  ),
  features = list("auth", "api", "websocket")
)

# Convert to Automerge document
doc5 <- as_automerge(config_data)
am_commit(doc5, "Initial configuration")

# Easy access with paths
am_get_path(doc5, c("database", "port"))
#> [1] 5432
```

## Working with Lists

Lists in R use 1-based indexing (standard R convention):

``` r
# Create a document with a list
doc6 <- am_create()
am_put(doc6, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
items <- am_get(doc6, AM_ROOT, "items")

# Insert items
am_insert(doc6, items, 1, "first") # Insert at index 1
am_insert(doc6, items, 2, "second") # Insert at index 2
am_insert(doc6, items, 3, "third") # Insert at index 3

# Or use the "end" marker to append
am_insert(doc6, items, "end", "fourth")
am_put(doc6, items, "end", "fifth")

# Get list length
am_length(doc6, items)
#> [1] 5

# Access by index
am_get(doc6, items, 1)
#> [1] "first"
am_get(doc6, items, 2)
#> [1] "second"
```

## Special Automerge Types

### Text Objects (for Collaborative Editing)

Regular strings use deterministic conflict resolution (one value wins).
For collaborative text editing, use text objects:

``` r
doc7 <- am_create()

# Regular string (last-write-wins)
am_put(doc7, AM_ROOT, "title", "My Document")

# Text object (CRDT - supports collaborative editing)
am_put(doc7, AM_ROOT, "content", am_text("Initial content"))
text_obj <- am_get(doc7, AM_ROOT, "content")

# Text supports character-level operations
# For the text "Hello":
#  H e l l o
# 0 1 2 3 4 5  <- positions (0-based, between characters)

am_text_splice(text_obj, 8, 0, "amazing ") # Insert at position 8
am_text_get(text_obj)
#> [1] "Initial amazing content"
```

### Counters (for CRDT Counting)

Counters are special values that can be incremented/decremented without
conflicts:

``` r
doc8 <- am_create()

# Create a counter
am_put(doc8, AM_ROOT, "score", am_counter(0))

am_counter_increment(doc8, AM_ROOT, "score", 10)
am_counter_increment(doc8, AM_ROOT, "score", 5)
am_counter_increment(doc8, AM_ROOT, "score", -3)

doc8[["score"]]
#> <Automerge Counter: 12 >
```

### Timestamps

POSIXct timestamps are natively supported:

``` r
doc9 <- am_create()

am_put(doc9, AM_ROOT, "created_at", Sys.time())
am_put(doc9, AM_ROOT, "updated_at", Sys.time())

doc9[["created_at"]]
#> [1] "2025-11-29 13:12:01 UTC"
```

## Saving and Loading Documents

Documents can be saved to binary format and loaded later:

``` r
# Save to binary format
bytes <- am_save(doc)

# Save to file
temp_file <- tempfile(fileext = ".automerge")
writeBin(bytes, temp_file)

# Load from binary
doc_loaded <- am_load(bytes)

# Or load from file
doc_from_file <- am_load(readBin(temp_file, "raw", 1e6))

# Verify data persisted
doc_from_file[["name"]]
#> [1] "Alice"
```

## Document Lifecycle

### Committing Changes

``` r
doc10 <- am_create()

# Make changes
doc10[["x"]] <- 1
doc10[["y"]] <- 2

# Commit with message
am_commit(doc10, "Add x and y coordinates")

# Make more changes
doc10[["z"]] <- 3
am_commit(doc10, "Add z coordinate")
```

### Forking Documents

Create independent copies:

``` r
doc11 <- am_fork(doc10)

# Changes to fork don't affect original
doc11[["w"]] <- 4
doc10[["w"]] # NULL - not in original
#> NULL
```

### Merging Documents

Merge changes from one document into another:

``` r
# Create two documents
doc12 <- am_create()
doc12[["source"]] <- "doc12"
doc12[["value1"]] <- 100

doc13 <- am_create()
doc13[["source"]] <- "doc13"
doc13[["value2"]] <- 200

# Merge doc13 into doc12
am_merge(doc12, doc13)

# doc12 now has both values
doc12[["value1"]]
#> [1] 100
doc12[["value2"]]
#> [1] 200
doc12[["source"]] # One value wins deterministically for conflicting keys
#> [1] "doc12"
```

## Basic Synchronization

Automerge’s key feature is automatic synchronization between documents:

``` r
# Create two peers
peer1 <- am_create()
peer1[["edited_by"]] <- "peer1"
peer1[["data1"]] <- 100
am_commit(peer1)

peer2 <- am_create()
peer2[["edited_by"]] <- "peer2"
peer2[["data2"]] <- 200
am_commit(peer2)

# Bidirectional sync (documents modified in place)
rounds <- am_sync(peer1, peer2)
rounds
#> [1] 4

# Both documents now have all data
peer1[["data1"]]
#> [1] 100
peer1[["data2"]]
#> [1] 200
peer2[["data1"]]
#> [1] 100
peer2[["data2"]]
#> [1] 200
```

## Next Steps

- Learn about [CRDT
  Concepts](http://shikokuchuo.net/automerge-r/articles/crdt-concepts.md)
  to understand the theory behind Automerge
- Explore [Synchronization
  Patterns](http://shikokuchuo.net/automerge-r/articles/sync-protocol.md)
  for collaborative workflows
- Check the [Quick
  Reference](http://shikokuchuo.net/automerge-r/articles/very-quick-reference.md)
  for a one-page guide to all functions

## Getting Help

``` r
# Function help
?am_create
?am_put
?am_sync

# Package help
?automerge
help(package = "automerge")

# All vignettes
vignette(package = "automerge")
```
