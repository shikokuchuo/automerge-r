# Cross-Platform Synchronization: JavaScript ↔ R

## Running the Examples

This vignette includes executable JavaScript and R code examples. To run
them:

### Option 1: Automated Test Script

The easiest way to verify JavaScript ↔︎ R interoperability:

``` bash
# From package root directory
Rscript inst/js/run-examples.R

# Or from inst/js/ directory
cd inst/js
Rscript run-examples.R
```

This script will:

- Check for Node.js availability
- Install required npm packages (`@automerge/automerge`)
- Execute all examples and verify results
- Display output showing success/failure

### Option 2: Manual Execution

**Prerequisites:**

``` bash
# Install Node.js from https://nodejs.org/

# Get JavaScript directory
# From installed package:
R -e "cat(system.file('js', package = 'automerge'))"

# From source: inst/js/
cd inst/js
npm install
```

**Run individual examples:**

``` bash
# Create a document in JavaScript
node inst/js/create-shared-doc.js shared_doc.automerge

# Then load in R
Rscript -e 'doc <- automerge::am_load(readBin("shared_doc.automerge", "raw", 1e7)); print(doc)'
```

### Option 3: Interactive Verification

``` r
library(automerge)

# Check if Node.js is available
if (system2("node", "--version", stdout = FALSE, stderr = FALSE) == 0) {
  # Get JavaScript directory
  js_dir <- system.file("js", package = "automerge")

  # Run JavaScript example
  temp_file <- tempfile(fileext = ".automerge")
  system2("node", c(file.path(js_dir, "create-shared-doc.js"), temp_file))

  # Load in R
  doc <- am_load(readBin(temp_file, "raw", 1e7))
  print(doc)
}
```

## Overview

One of Automerge’s key strengths is seamless synchronization across
different platforms and programming languages. This vignette
demonstrates how documents created in JavaScript can be synced with R
and vice versa, enabling collaborative workflows across different
technology stacks.

## Binary Format Compatibility

Automerge uses a standardized binary format (see
[automerge.org/automerge-binary-format-spec](https://automerge.org/automerge-binary-format-spec))
that is identical across all implementations. This means:

- Documents saved in JavaScript can be loaded in R
- Changes made in R can be merged back into JavaScript
- The sync protocol works seamlessly between platforms
- All CRDT types (maps, lists, text, counters) are fully compatible

## Prerequisites

You’ll need:

- **JavaScript**: `@automerge/automerge` package (npm install)
- **R**: `automerge` package (this package)
- A way to exchange binary data between environments (files, HTTP,
  WebSockets, etc.)

For these examples, we’ll use file-based exchange with Node.js on the
JavaScript side.

## Example 1: Creating a Document in JavaScript, Loading in R

### JavaScript Side

``` javascript
// Node.js or browser
import * as Automerge from '@automerge/automerge'
const fs = require('fs')

// Create a document
let doc = Automerge.init()

// Add some data
doc = Automerge.change(doc, 'Initial data', doc => {
  doc.title = 'Collaborative Analysis'
  doc.datasets = []
  doc.datasets.push({ name: 'sales_2024', rows: 1000 })
  doc.datasets.push({ name: 'customers', rows: 5000 })
  doc.metadata = {
    created_by: 'javascript',
    created_at: new Date().toISOString(),
    version: '1.0'
  }
})

// Save to binary format
const bytes = Automerge.save(doc)

// Write to file (Node.js)
fs.writeFileSync('shared_doc.automerge', bytes)

console.log('Document created and saved')
console.log('Actor ID:', Automerge.getActorId(doc))
```

### R Side

``` r
library(automerge)

# Load the document created in JavaScript
doc_bytes <- readBin("shared_doc.automerge", "raw", 1e7)
doc <- am_load(doc_bytes)

# Examine the document
print(doc)

# Access data created in JavaScript
cat("Title:", doc[["title"]], "\n")
cat("Created by:", doc[["metadata"]][["created_by"]], "\n")

# Show datasets
datasets <- doc[["datasets"]]
cat("Number of datasets:", am_length(doc, datasets), "\n")

# Examine first dataset (R uses 1-based indexing)
dataset1 <- am_get(doc, datasets, 1)
cat(
  "First dataset:",
  am_get(doc, dataset1, "name"),
  "with",
  am_get(doc, dataset1, "rows"),
  "rows\n"
)
```

## Example 2: Modifying in R, Syncing Back to JavaScript

### R Side - Make Changes

``` r
# Continue from previous example
# Add analysis results from R
am_put(
  doc,
  AM_ROOT,
  "r_analysis",
  list(
    performed_by = "R",
    timestamp = Sys.time(),
    R_version = paste(R.version$major, R.version$minor, sep = "."),
    summary_stats = list(
      mean_sales = 45231.5,
      median_sales = 38900.0,
      total_customers = 5000L
    )
  )
)

# Commit changes
am_commit(doc, "Added R analysis results")

# Save back to file
writeBin(am_save(doc), "shared_doc.automerge")

cat("Document updated by R and saved\n")
cat("R Actor ID:", am_get_actor_hex(doc), "\n")
```

### JavaScript Side - Load Updated Document

``` javascript
// Load the updated document
const updatedBytes = fs.readFileSync('shared_doc.automerge')
let updatedDoc = Automerge.load(updatedBytes)

console.log('Document loaded with R changes')
console.log('Title:', updatedDoc.title)
console.log('R Analysis:', updatedDoc.r_analysis)
console.log('Mean sales:', updatedDoc.r_analysis.summary_stats.mean_sales)
console.log('Analysis performed by:', updatedDoc.r_analysis.performed_by)

// View change history
const changes = Automerge.getAllChanges(updatedDoc)
console.log(`Total changes: ${changes.length}`)

// Make additional changes in JavaScript
updatedDoc = Automerge.change(updatedDoc, 'Add JS visualization', doc => {
  doc.visualizations = []
  doc.visualizations.push({
    type: 'bar_chart',
    data_source: 'r_analysis.summary_stats',
    created_in: 'javascript'
  })
})

// Save for next R session
fs.writeFileSync('shared_doc.automerge', Automerge.save(updatedDoc))
```

## Example 3: Real-Time Sync Protocol

This example shows how to use the sync protocol for real-time
synchronization between JavaScript and R.

### R Side - Set Up Sync

``` r
# Initial R document
r_doc <- am_create() |>
  am_put(AM_ROOT, "source", "R") |>
  am_put(
    AM_ROOT,
    "data",
    list(
      r_value = 123,
      timestamp = Sys.time()
    )
  ) |>
  am_commit("Initial R doc")

# Create sync state
r_sync <- am_sync_state_new()

# Generate sync message to send to JavaScript
sync_msg_to_js <- am_sync_encode(r_doc, r_sync)

# Save sync message to file (in practice, send over network)
writeBin(sync_msg_to_js, "r_to_js_sync.bin")

cat("R sync message ready:", length(sync_msg_to_js), "bytes\n")
```

### JavaScript Side - Receive and Respond

``` javascript
// Initial JavaScript document
let jsDoc = Automerge.change(Automerge.init(), 'Initial', doc => {
  doc.source = 'JavaScript'
  doc.data = {
    js_value: 456,
    timestamp: Date.now()
  }
})

// Create sync state
let jsSyncState = Automerge.initSyncState()

// Load sync message from R
const syncMsgFromR = fs.readFileSync('r_to_js_sync.bin')

// Receive sync message and update document
;[jsDoc, jsSyncState] = Automerge.receiveSyncMessage(
  jsDoc,
  jsSyncState,
  syncMsgFromR
)

console.log('Received sync from R')
console.log('Document now has:', Object.keys(jsDoc))

// Generate response sync message
const syncMsgToR = Automerge.generateSyncMessage(jsDoc, jsSyncState)

if (syncMsgToR) {
  fs.writeFileSync('js_to_r_sync.bin', syncMsgToR)
  console.log('JS sync message ready:', syncMsgToR.length, 'bytes')
}
```

### R Side - Complete Sync

``` r
# Load sync message from JavaScript
sync_msg_from_js <- readBin("js_to_r_sync.bin", "raw", 1e7)

# Apply sync message
am_sync_decode(r_doc, r_sync, sync_msg_from_js)

# Documents are now synchronized
cat("Sync complete!\n")
cat("R document now contains:\n")
print(names(r_doc))

# Verify we have data from JavaScript
if (!is.null(r_doc[["data"]][["js_value"]])) {
  cat("JavaScript value:", r_doc[["data"]][["js_value"]], "\n")
}
```

## Example 4: Concurrent Edits and Automatic Merge

This demonstrates Automerge’s CRDT capabilities with concurrent edits in
both platforms.

### Scenario Setup

``` r
# Create a shared document
shared <- am_create() |>
  am_put(AM_ROOT, "document", "Shared Document") |>
  am_put(AM_ROOT, "sections", am_list()) |>
  am_commit("Initialize document")

# Save for both platforms
shared_bytes <- am_save(shared)
writeBin(shared_bytes, "concurrent_doc.automerge")
```

### JavaScript - Concurrent Edit 1

``` javascript
// Load shared document
let jsDoc = Automerge.load(fs.readFileSync('concurrent_doc.automerge'))

// JavaScript makes changes
jsDoc = Automerge.change(jsDoc, 'Add JS section', doc => {
  doc.sections.push({
    title: 'JavaScript Analysis',
    content: 'Web visualization results',
    author: 'JS Team'
  })
  doc.js_edit_time = Date.now()
})

// Save changes
fs.writeFileSync('js_concurrent.automerge', Automerge.save(jsDoc))
```

Or run the provided script:

``` bash
# From installed package
JS_DIR=$(Rscript -e "cat(system.file('js', package='automerge'))")
node $JS_DIR/concurrent-edit.js concurrent_doc.automerge js_concurrent.automerge

# Or from source
node inst/js/concurrent-edit.js concurrent_doc.automerge js_concurrent.automerge
```

### R - Concurrent Edit 2

``` r
# Load the same original document
r_doc <- am_load(shared_bytes)

# R makes different changes to the same document
sections <- r_doc[["sections"]]
am_insert(
  r_doc,
  sections,
  1,
  list(
    title = "R Statistical Analysis",
    content = "Regression model results",
    author = "R Team"
  )
)

am_put(r_doc, AM_ROOT, "r_edit_time", Sys.time())
am_commit(r_doc, "Add R section")

# Save R changes
writeBin(am_save(r_doc), "r_concurrent.automerge")
```

### Merge Concurrent Changes (R Side)

``` r
# Load JavaScript version
js_doc_bytes <- readBin("js_concurrent.automerge", "raw", 1e7)
js_doc <- am_load(js_doc_bytes)

# Merge JavaScript changes into R document
am_merge(r_doc, js_doc)

# Verify merge - should have both sections
sections_merged <- r_doc[["sections"]]
cat(
  "After merge, document has",
  am_length(r_doc, sections_merged),
  "sections\n"
)

# Section 1 (from R)
section1 <- am_get(r_doc, sections_merged, 1)
cat("Section 1:", am_get(r_doc, section1, "title"), "\n")

# Section 2 (from JavaScript)
section2 <- am_get(r_doc, sections_merged, 2)
cat("Section 2:", am_get(r_doc, section2, "title"), "\n")

# Both timestamps preserved
cat("R edit time:", r_doc[["r_edit_time"]], "\n")
cat("JS edit time:", r_doc[["js_edit_time"]], "\n")
```

### Merge Concurrent Changes (JavaScript Side)

The same merge can be done on the JavaScript side:

``` javascript
// JavaScript loads R version and merges
const rDocBytes = fs.readFileSync('r_concurrent.automerge')
const rDoc = Automerge.load(rDocBytes)

// Merge R changes into JS document
jsDoc = Automerge.merge(jsDoc, rDoc)

// Verify - both sections present
console.log('After merge, sections:', jsDoc.sections.length)
console.log('Section 0:', jsDoc.sections[0].title, '(from R)')
console.log('Section 1:', jsDoc.sections[1].title, '(from JS)')

// Both timestamps preserved
console.log('R edit time:', jsDoc.r_edit_time)
console.log('JS edit time:', jsDoc.js_edit_time)
```

Or verify using the provided script:

``` bash
# From installed package
JS_DIR=$(Rscript -e "cat(system.file('js', package='automerge'))")
node $JS_DIR/verify-merge.js r_concurrent.automerge

# Or from source
node inst/js/verify-merge.js r_concurrent.automerge
```

## Example 5: Text CRDT Synchronization

Text objects are particularly interesting as they demonstrate
character-level CRDT merge.

### JavaScript - Create Text Document

``` javascript
let textDoc = Automerge.change(Automerge.init(), doc => {
  doc.notes = new Automerge.Text('Hello from JavaScript')
})

fs.writeFileSync('text_doc.automerge', Automerge.save(textDoc))
```

### R - Load and Edit Text

``` r
# Load text document
text_doc <- am_load(readBin("text_doc.automerge", "raw", 1e7))

# Get text object
notes <- am_get(text_doc, AM_ROOT, "notes")

# Append text in R (0-based position indexing)
current_length <- am_length(text_doc, notes)
am_text_splice(notes, current_length, 0, " and R!")
am_commit(text_doc, "R appended text")

# Get full text
full_text <- am_text_get(notes)
cat("Text after R edit:", full_text, "\n")
# Output: "Hello from JavaScript and R!"

# Save back
writeBin(am_save(text_doc), "text_doc.automerge")
```

### JavaScript - Verify Text Edits

``` javascript
// Load updated text document
const updatedTextDoc = Automerge.load(fs.readFileSync('text_doc.automerge'))

console.log('Text content:', updatedTextDoc.notes.toString())
// Output: "Hello from JavaScript and R!"
```

## Type Compatibility Matrix

| Automerge      | JavaScript                                       | R                     | Notes                               |
|----------------|--------------------------------------------------|-----------------------|-------------------------------------|
| Map            | Object [`{}`](https://rdrr.io/r/base/Paren.html) | Named list            | Root is always a map                |
| List           | Array `[]`                                       | Unnamed list          | R uses 1-based indexing             |
| Text           | `Automerge.Text`                                 | Text object (am_text) | Character-level CRDT                |
| String         | `string`                                         | `character(1)`        | UTF-8 encoding                      |
| Number (int)   | `number`                                         | `integer` / `double`  | 32-bit int if in range, else double |
| Number (float) | `number`                                         | `double`              | Double precision (64-bit)           |
| Boolean        | `boolean`                                        | `logical`             | TRUE/FALSE                          |
| Null           | `null`                                           | `NULL`                | Absence of value                    |
| Bytes          | `Uint8Array`                                     | `raw`                 | Binary data                         |
| Timestamp      | `Date` / `number`                                | `POSIXct`             | Milliseconds since epoch            |
| Counter        | CRDT counter                                     | `am_counter`          | Conflict-free counter               |

**Important Notes:**

- **Integer Sizes**: Automerge stores 64-bit signed integers internally.
  R integers are 32-bit, so values outside the range ±2,147,483,647 are
  automatically converted to `numeric` (double). JavaScript uses 64-bit
  floats for all numbers (safe integers up to ±9,007,199,254,740,991).

- **List Indexing**: JavaScript uses 0-based indexing (`array[0]`), R
  uses 1-based indexing (`am_get(doc, list_obj, 1)`)

- **Text Operations**: Both use 0-based positions for text operations
  (splice, cursors, marks)

- **UTF-32 vs UTF-16**: R bindings use UTF-32 character indexing by
  default, JavaScript uses UTF-16. Positions may differ for emoji and
  some Unicode characters.

## Binary Format Details

The saved document format includes:

- **Change history**: All operations since document creation
- **Actor IDs**: Unique identifiers for each editing session
- **Dependencies**: Causal relationships between changes
- **Compressed storage**: Columnar format with RLE compression

The binary format is deterministic and identical across platforms,
enabling:

- File-based collaboration (Dropbox, Git LFS, etc.)
- Network synchronization (HTTP, WebSockets)
- Conflict-free merging regardless of edit order

## Troubleshooting

### Character Encoding Issues

Both JavaScript and R use UTF-8 for strings. If you encounter encoding
issues:

``` r
# Ensure UTF-8 encoding when reading from files
doc <- am_load(readBin("doc.automerge", "raw", 1e7))

# Check string encoding
str_value <- doc[["string_field"]]
Encoding(str_value) # Should be "UTF-8"
```

### Binary File Transfer

When transferring files between systems, always use binary mode:

``` bash
# Correct: binary transfer
scp -B doc.automerge server:/path/

# Incorrect: text mode (can corrupt)
# Don't use text mode transfer for .automerge files
```

### Actor ID Collisions

Each platform generates random actor IDs. To use custom IDs:

``` r
# R - specify actor ID as raw bytes or hex string
doc <- am_create(actor_id = "r-session-123")
```

``` javascript
// JavaScript - specify actor ID
let doc = Automerge.init({ actorId: "js-session-456" })
```

### Indexing Differences

Remember the indexing conventions:

``` r
# Lists: R uses 1-based indexing
list_obj <- doc[["items"]]
first_item <- am_get(doc, list_obj, 1) # First element

# Text operations: 0-based positions (same as JavaScript)
text_obj <- doc[["content"]]
am_text_splice(text_obj, 0, 0, "Start") # Position 0 = before first char
```

``` javascript
// JavaScript - lists use 0-based indexing
const firstItem = doc.items[0]  // First element

// Text operations - also 0-based
doc.content.insertAt(0, "Start")
```

## Testing Cross-Platform Interoperability

All examples in this vignette can be tested using the executable scripts
provided in `inst/js/`:

### Automated Testing

Run all examples automatically:

``` bash
Rscript inst/js/run-examples.R
```

This will execute all JavaScript scripts, verify results in R, and
demonstrate complete round-trip interoperability.

### Manual Testing

See the documentation in `inst/js/README.md` (or after installation, use
`system.file("js/README.md", package = "automerge")`) for detailed
instructions on running individual examples and integrating with your
own tests.

### Available Scripts

The following scripts are available in `inst/js/`:

- `create-shared-doc.js` - Create documents in JavaScript
- `verify-r-changes.js` - Verify R modifications from JavaScript
- `concurrent-edit.js` - Make concurrent edits in JavaScript
- `verify-merge.js` - Verify CRDT merge from JavaScript

To find these scripts after installation:

``` r
system.file("js", package = "automerge")
```

## Further Reading

- [Automerge Website](https://automerge.org)
- [Binary Format
  Specification](https://automerge.org/automerge-binary-format-spec)
- [JavaScript API Documentation](https://automerge.org/docs/api/)
- [CRDT Research Papers](https://crdt.tech)
- [Sync Protocol
  Vignette](http://shikokuchuo.net/automerge-r/articles/sync-protocol.md) -
  Details on the sync protocol
- [CRDT Concepts
  Vignette](http://shikokuchuo.net/automerge-r/articles/crdt-concepts.md) -
  Understanding CRDTs
- JavaScript Interoperability Scripts - See
  `system.file("js", package = "automerge")` for executable examples
