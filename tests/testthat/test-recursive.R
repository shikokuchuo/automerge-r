# Recursive Conversion and Advanced Types (Phase 3)

test_that("Recursive conversion works for nested maps", {
  doc <- am_create()

  # Single-call nested structure
  am_put(
    doc,
    AM_ROOT,
    "user",
    list(
      name = "Alice",
      age = 30L,
      active = TRUE
    )
  )

  user <- am_get(doc, AM_ROOT, "user")
  expect_s3_class(user, "am_object")

  expect_equal(am_get(doc, user, "name"), "Alice")
  expect_equal(am_get(doc, user, "age"), 30L)
  expect_equal(am_get(doc, user, "active"), TRUE)
})

test_that("Recursive conversion handles deep nesting", {
  doc <- am_create()

  # Multi-level nested structure (3 levels deep)
  am_put(
    doc,
    AM_ROOT,
    "company",
    list(
      name = "Acme Corp",
      office = list(
        location = "Boston",
        address = list(
          street = "123 Main St",
          city = "Boston",
          zip = 02101L
        )
      )
    )
  )

  company <- am_get(doc, AM_ROOT, "company")
  expect_equal(am_get(doc, company, "name"), "Acme Corp")

  office <- am_get(doc, company, "office")
  expect_equal(am_get(doc, office, "location"), "Boston")

  address <- am_get(doc, office, "address")
  expect_equal(am_get(doc, address, "street"), "123 Main St")
  expect_equal(am_get(doc, address, "city"), "Boston")
  expect_equal(am_get(doc, address, "zip"), 02101L)
})

test_that("Recursive conversion handles mixed maps and lists", {
  doc <- am_create()

  # Map containing lists
  am_put(
    doc,
    AM_ROOT,
    "data",
    list(
      tags = list("r", "automerge", "crdt"), # Unnamed = list
      metadata = list(version = "1.0", author = "user") # Named = map
    )
  )

  data <- am_get(doc, AM_ROOT, "data")

  tags <- am_get(doc, data, "tags")
  expect_equal(am_length(doc, tags), 3L)
  expect_equal(am_get(doc, tags, 1), "r") # 1-based indexing
  expect_equal(am_get(doc, tags, 2), "automerge")
  expect_equal(am_get(doc, tags, 3), "crdt")

  metadata <- am_get(doc, data, "metadata")
  expect_equal(am_get(doc, metadata, "version"), "1.0")
  expect_equal(am_get(doc, metadata, "author"), "user")
})

test_that("Explicit type constructors work", {
  doc <- am_create()

  # Explicit list type (empty)
  am_put(doc, AM_ROOT, "items", am_list())
  items <- am_get(doc, AM_ROOT, "items")
  expect_s3_class(items, "am_object")
  expect_equal(am_length(doc, items), 0L)

  # Explicit list type (populated)
  am_put(doc, AM_ROOT, "tags", am_list("a", "b", "c"))
  tags <- am_get(doc, AM_ROOT, "tags")
  expect_equal(am_length(doc, tags), 3L)
  expect_equal(am_get(doc, tags, 1), "a")

  # Explicit map type (empty)
  am_put(doc, AM_ROOT, "config", am_map())
  config <- am_get(doc, AM_ROOT, "config")
  expect_s3_class(config, "am_object")
  expect_equal(am_length(doc, config), 0L)

  # Explicit map type (populated)
  am_put(doc, AM_ROOT, "settings", am_map(key1 = "val1", key2 = "val2"))
  settings <- am_get(doc, AM_ROOT, "settings")
  expect_equal(am_get(doc, settings, "key1"), "val1")
  expect_equal(am_get(doc, settings, "key2"), "val2")
})

test_that("POSIXct timestamps work", {
  doc <- am_create()

  # Store timestamp
  now <- Sys.time()
  am_put(doc, AM_ROOT, "created", now)

  # Retrieve and verify (allowing for small rounding error)
  retrieved <- am_get(doc, AM_ROOT, "created")
  expect_s3_class(retrieved, "POSIXct")
  expect_equal(as.numeric(retrieved), as.numeric(now), tolerance = 0.001)
})

test_that("am_counter type works", {
  doc <- am_create()

  # Store counter
  am_put(doc, AM_ROOT, "score", am_counter(0))

  # Retrieve and verify
  score <- am_get(doc, AM_ROOT, "score")
  expect_s3_class(score, "am_counter")
  expect_equal(as.integer(score), 0L)

  # Store counter with initial value
  am_put(doc, AM_ROOT, "points", am_counter(100L))
  points <- am_get(doc, AM_ROOT, "points")
  expect_equal(as.integer(points), 100L)
})

test_that("am_text type creates text objects", {
  doc <- am_create()

  # Empty text
  am_put(doc, AM_ROOT, "doc1", am_text())
  text1 <- am_get(doc, AM_ROOT, "doc1")
  expect_s3_class(text1, "am_object")
  # Text object should be empty initially
  expect_equal(am_length(doc, text1), 0L)

  # Text with initial content
  am_put(doc, AM_ROOT, "doc2", am_text("Hello, World!"))
  text2 <- am_get(doc, AM_ROOT, "doc2")
  expect_s3_class(text2, "am_object")
  # Text object should have 13 characters
  expect_equal(am_length(doc, text2), 13L)
})

test_that("text objects vs strings behave differently", {
  doc <- am_create()

  # Regular string (last-write-wins)
  am_put(doc, AM_ROOT, "title", "String Value")
  expect_type(am_get(doc, AM_ROOT, "title"), "character")
  expect_equal(am_get(doc, AM_ROOT, "title"), "String Value")

  # Text object (CRDT)
  am_put(doc, AM_ROOT, "content", am_text("Text Object"))
  text_obj <- am_get(doc, AM_ROOT, "content")
  expect_s3_class(text_obj, "am_object")
  # Length should be character count
  expect_equal(am_length(doc, text_obj), 11L)
})

test_that("Recursive conversion handles NULL values", {
  doc <- am_create()

  am_put(
    doc,
    AM_ROOT,
    "data",
    list(
      present = "value",
      missing = NULL,
      nested = list(
        also_missing = NULL,
        also_present = 42L
      )
    )
  )

  data <- am_get(doc, AM_ROOT, "data")
  expect_equal(am_get(doc, data, "present"), "value")
  expect_null(am_get(doc, data, "missing"))

  nested <- am_get(doc, data, "nested")
  expect_null(am_get(doc, nested, "also_missing"))
  expect_equal(am_get(doc, nested, "also_present"), 42L)
})

test_that("Recursive conversion handles all primitive types", {
  doc <- am_create()

  raw_data <- as.raw(c(0x01, 0x02, 0x03))

  am_put(
    doc,
    AM_ROOT,
    "all_types",
    list(
      null_val = NULL,
      bool_val = TRUE,
      int_val = 42L,
      double_val = 3.14159,
      string_val = "hello",
      raw_val = raw_data,
      timestamp_val = Sys.time(),
      counter_val = am_counter(10L)
    )
  )

  obj <- am_get(doc, AM_ROOT, "all_types")

  expect_null(am_get(doc, obj, "null_val"))
  expect_equal(am_get(doc, obj, "bool_val"), TRUE)
  expect_equal(am_get(doc, obj, "int_val"), 42L)
  expect_equal(am_get(doc, obj, "double_val"), 3.14159, tolerance = 1e-6)
  expect_equal(am_get(doc, obj, "string_val"), "hello")
  expect_equal(am_get(doc, obj, "raw_val"), raw_data)
  expect_s3_class(am_get(doc, obj, "timestamp_val"), "POSIXct")
  expect_s3_class(am_get(doc, obj, "counter_val"), "am_counter")
})

test_that("Recursive conversion integrates with commit/save/load", {
  doc1 <- am_create()

  # Create complex nested structure
  am_put(
    doc1,
    AM_ROOT,
    "project",
    list(
      name = "MyProject",
      version = "1.0.0",
      metadata = list(
        created = Sys.time(),
        tags = list("important", "active"),
        stats = list(
          commits = am_counter(42L),
          stars = am_counter(100L)
        )
      )
    )
  )

  am_commit(doc1, "Added project data")

  # Save and load
  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  # Verify structure is preserved
  project <- am_get(doc2, AM_ROOT, "project")
  expect_equal(am_get(doc2, project, "name"), "MyProject")

  metadata <- am_get(doc2, project, "metadata")
  expect_s3_class(am_get(doc2, metadata, "created"), "POSIXct")

  tags <- am_get(doc2, metadata, "tags")
  expect_equal(am_length(doc2, tags), 2L)

  stats <- am_get(doc2, metadata, "stats")
  commits <- am_get(doc2, stats, "commits")
  expect_s3_class(commits, "am_counter")
  expect_equal(as.integer(commits), 42L)
})

test_that("Very deep nesting (5+ levels) works", {
  doc <- am_create()

  # 6 levels deep
  am_put(
    doc,
    AM_ROOT,
    "level1",
    list(
      level2 = list(
        level3 = list(
          level4 = list(
            level5 = list(
              level6 = "deep value"
            )
          )
        )
      )
    )
  )

  # Navigate down
  l1 <- am_get(doc, AM_ROOT, "level1")
  l2 <- am_get(doc, l1, "level2")
  l3 <- am_get(doc, l2, "level3")
  l4 <- am_get(doc, l3, "level4")
  l5 <- am_get(doc, l4, "level5")
  value <- am_get(doc, l5, "level6")

  expect_equal(value, "deep value")
})

test_that("Empty nested structures work", {
  doc <- am_create()

  # Empty map in map
  am_put(doc, AM_ROOT, "outer", list(inner = list()))
  outer <- am_get(doc, AM_ROOT, "outer")
  inner <- am_get(doc, outer, "inner")
  expect_equal(am_length(doc, inner), 0L)

  # Empty list in map
  am_put(doc, AM_ROOT, "container", list(items = am_list()))
  container <- am_get(doc, AM_ROOT, "container")
  items <- am_get(doc, container, "items")
  expect_equal(am_length(doc, items), 0L)
})

test_that("Extremely deep nesting (150 levels) works without stack overflow", {
  doc <- am_create()

  # Build a deeply nested structure programmatically (150 levels)
  # This exceeds the old MAX_RECURSION_DEPTH=100 limit
  depth <- 150

  # Build nested list structure
  build_nested <- function(n) {
    if (n == 0) {
      return("bottom value")
    }
    list(child = build_nested(n - 1))
  }

  nested_data <- build_nested(depth - 1)

  # This should not crash - test that recursive conversion handles it
  expect_error(
    am_put(doc, AM_ROOT, "deep", nested_data),
    NA  # NA means we expect NO error
  )

  # Navigate down to verify the structure was created
  current <- am_get(doc, AM_ROOT, "deep")
  expect_s3_class(current, "am_object")

  # Navigate several levels down (not all 150, that would be tedious)
  for (i in 1:10) {
    current <- am_get(doc, current, "child")
    if (i < 10) {
      expect_s3_class(current, "am_object")
    }
  }

  # Verify we can commit and save without issues
  expect_error(am_commit(doc, "Deep structure test"), NA)
  expect_error(am_save(doc), NA)
})
