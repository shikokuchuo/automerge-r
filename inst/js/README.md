# JavaScript ↔ R Interoperability Examples

This directory contains executable Node.js scripts that demonstrate and verify cross-platform synchronization between JavaScript and R using Automerge.

## Quick Start

### Automated Testing

The easiest way to verify interoperability:

```bash
# From package root directory
Rscript inst/js/run-examples.R

# Or from this directory (inst/js/)
Rscript run-examples.R
```

This automated script will:
1. Check for Node.js availability
2. Install required npm packages
3. Run all examples
4. Verify results
5. Display colored output showing success/failure

### Setup

```bash
# Install Node.js from https://nodejs.org/
```

The automated test runner (`run-examples.R`) handles npm package installation automatically using R's user cache directory. This means:

- npm packages are installed to `~/.cache/R/automerge/js/` (Unix) or similar OS-specific location
- Packages persist across R sessions and package reinstalls
- No pollution of the package source directory
- Only installed once; subsequent runs reuse the cache

If you want to install npm packages manually:

```bash
# Navigate to this directory
cd inst/js

# Install npm packages
npm install
```

This installs the `@automerge/automerge` package and dependencies locally.

## Available Scripts

### Example 1: Create a document in JavaScript

```bash
node create-shared-doc.js [output-path]
```

Creates an Automerge document in JavaScript and saves it to a binary file that can be loaded in R.

**Example:**
```bash
node create-shared-doc.js shared_doc.automerge
```

**Default output:** `shared_doc.automerge`

### Example 2: Verify R changes

```bash
node verify-r-changes.js [input-path]
```

Loads a document modified by R, verifies the changes, and adds JavaScript changes.

**Example:**
```bash
node verify-r-changes.js shared_doc.automerge
```

### Example 3: Make concurrent edits

```bash
node concurrent-edit.js <base-doc-path> <output-path>
```

Loads a base document and makes concurrent edits (simulating what would happen if a JavaScript user edited the document at the same time as an R user).

**Example:**
```bash
node concurrent-edit.js base.automerge js_edited.automerge
```

### Example 4: Verify merged document

```bash
node verify-merge.js <merged-doc-path>
```

Verifies that a merged document contains changes from both R and JavaScript, demonstrating CRDT conflict-free merge.

**Example:**
```bash
node verify-merge.js merged.automerge
```

## Directory Structure

```
inst/js/                        # Installed JavaScript examples
├── README.md                   # This file
├── run-examples.R              # Automated test runner
├── package.json                # npm dependencies
├── create-shared-doc.js        # Example 1: JS creates doc
├── verify-r-changes.js         # Example 2: JS verifies R changes
├── concurrent-edit.js          # Example 3: JS concurrent edit
└── verify-merge.js             # Example 4: Verify CRDT merge

vignettes/
└── cross-platform.Rmd          # Main vignette with examples
```

## Running from R

### Interactive Use

From R, you can execute these scripts:

```r
# Check if Node.js is available
node_available <- system2("node", "--version", stdout = FALSE, stderr = FALSE) == 0

if (node_available) {
  # Get JavaScript directory (works with installed package or source)
  js_dir <- system.file("js", package = "automerge")

  # Run example 1
  temp_file <- tempfile(fileext = ".automerge")
  system2("node", c(file.path(js_dir, "create-shared-doc.js"), temp_file),
          stdout = TRUE, stderr = TRUE)

  # Load the result
  doc <- automerge::am_load(readBin(temp_file, "raw", 1e7))
  print(doc)
}
```

### Finding Scripts After Installation

When the package is installed:

```r
# Get directory path
js_dir <- system.file("js", package = "automerge")

# List available scripts
list.files(js_dir, pattern = "\\.js$")
```

## Manual Testing Examples

### Example 1: JavaScript → R

```bash
# From installed package
JS_DIR=$(Rscript -e "cat(system.file('js', package='automerge'))")
node $JS_DIR/create-shared-doc.js test.automerge

# Or from source
node inst/js/create-shared-doc.js test.automerge
```

```r
# Load in R
library(automerge)
doc <- am_load(readBin("test.automerge", "raw", 1e7))
print(doc)
```

### Example 2: R → JavaScript

```r
# Modify in R
library(automerge)
doc <- am_load(readBin("test.automerge", "raw", 1e7))
doc[["r_data"]] <- list(value = 42, timestamp = Sys.time())
am_commit(doc, "Add R data")
writeBin(am_save(doc), "test.automerge")
```

```bash
# Verify in JavaScript
node inst/js/verify-r-changes.js test.automerge
```

### Example 3: Concurrent Edits with CRDT Merge

```r
# Create base document
library(automerge)
base <- am_create() |>
  am_put(AM_ROOT, "document", "Shared") |>
  am_put(AM_ROOT, "sections", am_list())
writeBin(am_save(base), "base.automerge")

# R makes concurrent edit
r_doc <- am_load(readBin("base.automerge", "raw", 1e7))
sections <- r_doc[["sections"]]
am_insert(r_doc, sections, 1, list(title = "R Section", author = "R Team"))
writeBin(am_save(r_doc), "r_edit.automerge")
```

```bash
# JavaScript makes concurrent edit (from same base)
node inst/js/concurrent-edit.js base.automerge js_edit.automerge
```

```r
# Merge in R
js_doc <- am_load(readBin("js_edit.automerge", "raw", 1e7))
am_merge(r_doc, js_doc)

# Verify both changes present
sections_merged <- r_doc[["sections"]]
am_length(r_doc, sections_merged)  # Should be 2

# Save merged document
writeBin(am_save(r_doc), "merged.automerge")
```

```bash
# Verify merge contains both changes
node inst/js/verify-merge.js merged.automerge
```

## Integration with Package Tests

These scripts can be used to create test fixtures:

```r
# tests/testthat/helper-js-fixtures.R
create_js_fixtures <- function() {
  if (system2("node", "--version", stdout = FALSE, stderr = FALSE) != 0) {
    skip("Node.js not available")
  }

  js_dir <- system.file("js", package = "automerge")
  if (js_dir == "") {
    js_dir <- file.path(getwd(), "..", "..", "inst", "js")
  }

  fixture_dir <- test_path("fixtures")
  dir.create(fixture_dir, showWarnings = FALSE, recursive = TRUE)

  system2("node", c(file.path(js_dir, "create-shared-doc.js"),
                    file.path(fixture_dir, "js_document.automerge")))
}
```

Example test:

```r
# tests/testthat/test-js-interop.R

test_that("JavaScript interoperability works", {
  skip_if_not(system2("node", "--version", stdout = FALSE, stderr = FALSE) == 0,
              "Node.js not available")

  # Get JavaScript directory (works with installed package or source)
  js_dir <- system.file("js", package = "automerge")
  if (js_dir == "") {
    js_dir <- file.path(getwd(), "..", "..", "inst", "js")
  }

  # Run JavaScript to create fixture
  js_script <- file.path(js_dir, "create-shared-doc.js")
  temp_file <- tempfile(fileext = ".automerge")

  system2("node", c(js_script, temp_file))

  # Load in R
  doc <- am_load(readBin(temp_file, "raw", 1e7))

  # Verify
  expect_equal(doc[["title"]], "Collaborative Analysis")
  expect_equal(doc[["metadata"]][["created_by"]], "javascript")
})
```

## CI/CD Integration

For automated testing in CI/CD:

```yaml
# .github/workflows/test.yml
steps:
  - name: Install Node.js
    uses: actions/setup-node@v3
    with:
      node-version: '18'

  - name: Install npm packages
    run: |
      cd inst/js
      npm install

  - name: Run interoperability tests
    run: Rscript inst/js/run-examples.R
```

## Troubleshooting

### "Node.js not available"

Install Node.js from https://nodejs.org/

### "Cannot find module '@automerge/automerge'"

The automated test runner should install packages to the cache automatically. If you see this error:

1. Check cache location:
   ```r
   tools::R_user_dir("automerge", which = "cache")
   ```

2. Clear cache and retry:
   ```r
   unlink(tools::R_user_dir("automerge", which = "cache"), recursive = TRUE)
   ```

3. Or install manually:
   ```bash
   cd inst/js
   npm install
   ```

### Cleaning the Cache

To remove cached npm packages:

```r
# Clean automerge cache
cache_dir <- tools::R_user_dir("automerge", which = "cache")
unlink(cache_dir, recursive = TRUE)
```

This will force reinstallation on next run.

### Different actor IDs

Each session generates a random actor ID. This is expected behavior.

### Timestamp precision

JavaScript uses milliseconds since epoch, R uses seconds. Small differences (< 1ms) are expected.

## What Gets Verified

The test suite verifies:

- ✓ JavaScript → R document loading
- ✓ R → JavaScript document modifications
- ✓ Bidirectional sync and merge
- ✓ Type compatibility (strings, numbers, lists, maps, timestamps)
- ✓ CRDT conflict-free merging
- ✓ Binary format compatibility
- ✓ Change history preservation

## Further Reading

- Main vignette: `vignette("cross-platform", package = "automerge")`
- [Automerge Website](https://automerge.org)
- [Binary Format Specification](https://automerge.org/automerge-binary-format-spec)
- [JavaScript API Documentation](https://automerge.org/docs/api/)
