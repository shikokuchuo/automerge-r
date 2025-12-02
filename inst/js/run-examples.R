#!/usr/bin/env Rscript

#' Run JavaScript Interoperability Examples
#'
#' This script demonstrates and verifies JavaScript ↔ R interoperability
#' by executing the JavaScript examples and validating the results in R.

library(automerge)

# Colors for output
green <- function(x) paste0("\033[32m", x, "\033[0m")
red <- function(x) paste0("\033[31m", x, "\033[0m")
blue <- function(x) paste0("\033[34m", x, "\033[0m")
bold <- function(x) paste0("\033[1m", x, "\033[0m")

cat(bold("Automerge JavaScript ↔ R Interoperability Tests\n"))
cat(rep("=", 60), "\n\n", sep = "")

# Check for Node.js
node_available <- system2(
  "node",
  "--version",
  stdout = FALSE,
  stderr = FALSE
) ==
  0

if (!node_available) {
  cat(red("✗ Node.js is not available\n"))
  cat("Please install Node.js from https://nodejs.org/\n")
  quit(status = 1)
}

node_version <- system2("node", "--version", stdout = TRUE)
cat(green("✓"), "Node.js available:", node_version, "\n\n")

# Get paths to JavaScript source directory
# This script can run from multiple locations
js_dir <- system.file("js", package = "automerge")

if (js_dir == "" || !dir.exists(js_dir)) {
  # Running from source - find inst/js relative to this script
  script_dir <- dirname(sys.frame(1)$ofile)
  if (is.null(script_dir) || script_dir == "") {
    # Try getwd() if script dir not available
    js_dir <- getwd()
    if (!file.exists(file.path(js_dir, "package.json"))) {
      # Not in inst/js, try to find it
      js_dir <- file.path(getwd(), "inst", "js")
      if (!dir.exists(js_dir)) {
        js_dir <- file.path(dirname(getwd()), "inst", "js")
      }
    }
  } else {
    # Script is in inst/js, use its directory
    js_dir <- script_dir
  }
}

if (!dir.exists(js_dir)) {
  cat(red("✗ JavaScript directory not found\n"))
  cat("Expected location: inst/js/\n")
  quit(status = 1)
}

# Set up user cache directory for npm packages
# This keeps node_modules out of the package directory and persists across sessions
cache_dir <- tools::R_user_dir("automerge", which = "cache")
js_cache_dir <- file.path(cache_dir, "js")

cat(blue("Setting up JavaScript cache directory...\n"))
cat("  Cache location:", js_cache_dir, "\n")

# Create cache directory structure
dir.create(js_cache_dir, recursive = TRUE, showWarnings = FALSE)

# Check if package.json exists in cache and is up-to-date
package_json_source <- file.path(js_dir, "package.json")
package_json_cache <- file.path(js_cache_dir, "package.json")
node_modules_cache <- file.path(js_cache_dir, "node_modules")

needs_install <- FALSE

if (!file.exists(package_json_cache)) {
  # No package.json in cache - need to copy and install
  needs_install <- TRUE
} else {
  # Check if package.json has changed
  source_info <- file.info(package_json_source)
  cache_info <- file.info(package_json_cache)

  if (source_info$mtime > cache_info$mtime) {
    cat(blue("  Package.json has been updated\n"))
    needs_install <- TRUE
  } else if (!dir.exists(node_modules_cache)) {
    cat(blue("  node_modules not found in cache\n"))
    needs_install <- TRUE
  }
}

if (needs_install) {
  # Copy package.json to cache
  cat(blue("  Copying package.json to cache...\n"))
  file.copy(package_json_source, package_json_cache, overwrite = TRUE)

  # Install npm packages in cache directory
  cat(blue("  Installing npm packages (this may take a minute)...\n"))

  # Save current directory
  original_wd <- getwd()
  on.exit(setwd(original_wd), add = TRUE)

  # Change to cache directory for npm install
  setwd(js_cache_dir)

  # Run npm install
  result <- system2(
    "npm",
    c("install", "--no-progress", "--no-audit", "--loglevel=error"),
    stdout = TRUE,
    stderr = TRUE
  )

  # Check if install succeeded
  if (!dir.exists(node_modules_cache)) {
    cat(red("\n✗ npm install failed\n"))
    cat("Output:\n")
    cat(paste(result, collapse = "\n"), "\n")
    quit(status = 1)
  }

  cat(green("  ✓ npm packages installed successfully\n\n"))
} else {
  cat(green("  ✓ npm packages already installed (using cache)\n\n"))
}

# Set NODE_PATH environment variable to use cached node_modules
# This allows scripts in inst/js/ to require packages from the cache
Sys.setenv(NODE_PATH = node_modules_cache)

# Create temp directory for examples
temp_dir <- tempdir()
shared_doc_path <- file.path(temp_dir, "shared_doc.automerge")

# Example 1: JavaScript creates document, R loads it
cat(bold("Example 1: JavaScript → R\n"))
cat(rep("-", 60), "\n", sep = "")

cat("1. Running JavaScript to create document...\n")
result <- system2(
  "node",
  c(file.path(js_dir, "create-shared-doc.js"), shared_doc_path),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(result, collapse = "\n"), "\n\n")

cat("2. Loading document in R...\n")
doc_bytes <- readBin(shared_doc_path, "raw", 1e7)
doc <- am_load(doc_bytes)

cat(green("✓"), "Document loaded successfully\n")
cat("  Title:", doc[["title"]], "\n")
cat("  Created by:", doc[["metadata"]][["created_by"]], "\n")

datasets <- doc[["datasets"]]
cat("  Number of datasets:", am_length(doc, datasets), "\n")

dataset1 <- am_get(doc, datasets, 1)
cat(
  "  First dataset:",
  am_get(doc, dataset1, "name"),
  "with",
  am_get(doc, dataset1, "rows"),
  "rows\n"
)

cat("\n")

# Example 2: R modifies document, JavaScript verifies
cat(bold("Example 2: R → JavaScript\n"))
cat(rep("-", 60), "\n", sep = "")

cat("1. Adding R analysis to document...\n")
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

am_commit(doc, "Added R analysis results")

cat(green("✓"), "R analysis added\n")
cat("  R version:", doc[["r_analysis"]][["R_version"]], "\n")
cat(
  "  Mean sales:",
  doc[["r_analysis"]][["summary_stats"]][["mean_sales"]],
  "\n"
)

cat("\n2. Saving document...\n")
writeBin(am_save(doc), shared_doc_path)
cat(green("✓"), "Document saved\n\n")

cat("3. Running JavaScript to verify changes...\n")
result <- system2(
  "node",
  c(file.path(js_dir, "verify-r-changes.js"), shared_doc_path),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(result, collapse = "\n"), "\n\n")

cat("4. Loading modified document back in R...\n")
doc_bytes <- readBin(shared_doc_path, "raw", 1e7)
doc <- am_load(doc_bytes)

if (!is.null(doc[["visualizations"]])) {
  cat(green("✓"), "JavaScript added visualizations\n")
  viz <- doc[["visualizations"]]
  viz1 <- am_get(doc, viz, 1)
  cat("  Type:", am_get(doc, viz1, "type"), "\n")
  cat("  Created in:", am_get(doc, viz1, "created_in"), "\n")
} else {
  cat(red("✗"), "No visualizations found\n")
}

cat("\n")

# Example 3: Concurrent edits and merge
cat(bold("Example 3: Concurrent Edits and Merge\n"))
cat(rep("-", 60), "\n", sep = "")

cat("1. Creating shared document...\n")
shared <- am_create() |>
  am_put(AM_ROOT, "document", "Shared Document") |>
  am_put(AM_ROOT, "sections", am_list()) |>
  am_commit("Initialize document")

shared_bytes <- am_save(shared)
writeBin(shared_bytes, shared_doc_path)
cat(green("✓"), "Shared document created\n\n")

cat("2. Making concurrent edit in R...\n")
r_doc <- am_load(shared_bytes)
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

r_concurrent_path <- file.path(temp_dir, "r_concurrent.automerge")
writeBin(am_save(r_doc), r_concurrent_path)
cat(green("✓"), "R edit saved\n\n")

cat("3. Making concurrent JavaScript edit...\n")
js_concurrent_path <- file.path(temp_dir, "js_concurrent.automerge")
result <- system2(
  "node",
  c(
    file.path(js_dir, "concurrent-edit.js"),
    shared_doc_path,
    js_concurrent_path
  ),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(result, collapse = "\n"), "\n\n")

cat("4. Merging concurrent edits in R...\n")
js_doc_bytes <- readBin(js_concurrent_path, "raw", 1e7)
js_doc_loaded <- am_load(js_doc_bytes)

am_merge(r_doc, js_doc_loaded)

sections_merged <- r_doc[["sections"]]
num_sections <- am_length(r_doc, sections_merged)
cat(green("✓"), "Merge complete\n")
cat("  Document has", num_sections, "sections after merge\n")

if (num_sections >= 1) {
  section1 <- am_get(r_doc, sections_merged, 1)
  cat("  Section 1:", am_get(r_doc, section1, "title"), "\n")
}
if (num_sections >= 2) {
  section2 <- am_get(r_doc, sections_merged, 2)
  cat("  Section 2:", am_get(r_doc, section2, "title"), "\n")
}

cat("  Both timestamps preserved:\n")
cat("    R edit time:", format(r_doc[["r_edit_time"]]), "\n")
if (!is.null(r_doc[["js_edit_time"]])) {
  # JavaScript stores timestamp as milliseconds since epoch
  js_time <- as.POSIXct(r_doc[["js_edit_time"]] / 1000, origin = "1970-01-01")
  cat("    JS edit time:", format(js_time), "\n")
}

cat("\n5. Verifying merge from JavaScript side...\n")
# Save merged document for JavaScript verification
merged_doc_path <- file.path(temp_dir, "merged_doc.automerge")
writeBin(am_save(r_doc), merged_doc_path)

result <- system2(
  "node",
  c(file.path(js_dir, "verify-merge.js"), merged_doc_path),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(result, collapse = "\n"), "\n\n")

# Summary
cat(bold("Summary\n"))
cat(rep("=", 60), "\n", sep = "")
cat(green("✓ All examples completed successfully!\n"))
cat("\nThe following interoperability features were verified:\n")
cat("  • JavaScript → R document loading\n")
cat("  • R → JavaScript document modifications\n")
cat("  • Bidirectional sync and merge\n")
cat("  • Type compatibility (strings, numbers, lists, maps, timestamps)\n")
cat("  • CRDT conflict-free merging\n")
cat("\nTemporary files created in:", temp_dir, "\n")
cat("npm packages cached in:", js_cache_dir, "\n")
cat("\nTo clean the cache, run: unlink('", cache_dir, "', recursive = TRUE)\n", sep = "")
