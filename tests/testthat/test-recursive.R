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

  expect_equal(am_get(doc, user$obj_id, "name"), "Alice")
  expect_equal(am_get(doc, user$obj_id, "age"), 30L)
  expect_equal(am_get(doc, user$obj_id, "active"), TRUE)
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
  expect_equal(am_get(doc, company$obj_id, "name"), "Acme Corp")

  office <- am_get(doc, company$obj_id, "office")
  expect_equal(am_get(doc, office$obj_id, "location"), "Boston")

  address <- am_get(doc, office$obj_id, "address")
  expect_equal(am_get(doc, address$obj_id, "street"), "123 Main St")
  expect_equal(am_get(doc, address$obj_id, "city"), "Boston")
  expect_equal(am_get(doc, address$obj_id, "zip"), 02101L)
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

  tags <- am_get(doc, data$obj_id, "tags")
  expect_equal(am_length(doc, tags$obj_id), 3L)
  expect_equal(am_get(doc, tags$obj_id, 1), "r") # 1-based indexing
  expect_equal(am_get(doc, tags$obj_id, 2), "automerge")
  expect_equal(am_get(doc, tags$obj_id, 3), "crdt")

  metadata <- am_get(doc, data$obj_id, "metadata")
  expect_equal(am_get(doc, metadata$obj_id, "version"), "1.0")
  expect_equal(am_get(doc, metadata$obj_id, "author"), "user")
})

test_that("Explicit type constructors work", {
  doc <- am_create()

  # Explicit list type (empty)
  am_put(doc, AM_ROOT, "items", am_list())
  items <- am_get(doc, AM_ROOT, "items")
  expect_s3_class(items, "am_object")
  expect_equal(am_length(doc, items$obj_id), 0L)

  # Explicit list type (populated)
  am_put(doc, AM_ROOT, "tags", am_list("a", "b", "c"))
  tags <- am_get(doc, AM_ROOT, "tags")
  expect_equal(am_length(doc, tags$obj_id), 3L)
  expect_equal(am_get(doc, tags$obj_id, 1), "a")

  # Explicit map type (empty)
  am_put(doc, AM_ROOT, "config", am_map())
  config <- am_get(doc, AM_ROOT, "config")
  expect_s3_class(config, "am_object")
  expect_equal(am_length(doc, config$obj_id), 0L)

  # Explicit map type (populated)
  am_put(doc, AM_ROOT, "settings", am_map(key1 = "val1", key2 = "val2"))
  settings <- am_get(doc, AM_ROOT, "settings")
  expect_equal(am_get(doc, settings$obj_id, "key1"), "val1")
  expect_equal(am_get(doc, settings$obj_id, "key2"), "val2")
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
  expect_equal(am_length(doc, text1$obj_id), 0L)

  # Text with initial content
  am_put(doc, AM_ROOT, "doc2", am_text("Hello, World!"))
  text2 <- am_get(doc, AM_ROOT, "doc2")
  expect_s3_class(text2, "am_object")
  # Text object should have 13 characters
  expect_equal(am_length(doc, text2$obj_id), 13L)
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
  expect_equal(am_length(doc, text_obj$obj_id), 11L)
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
  expect_equal(am_get(doc, data$obj_id, "present"), "value")
  expect_null(am_get(doc, data$obj_id, "missing"))

  nested <- am_get(doc, data$obj_id, "nested")
  expect_null(am_get(doc, nested$obj_id, "also_missing"))
  expect_equal(am_get(doc, nested$obj_id, "also_present"), 42L)
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

  expect_null(am_get(doc, obj$obj_id, "null_val"))
  expect_equal(am_get(doc, obj$obj_id, "bool_val"), TRUE)
  expect_equal(am_get(doc, obj$obj_id, "int_val"), 42L)
  expect_equal(am_get(doc, obj$obj_id, "double_val"), 3.14159, tolerance = 1e-6)
  expect_equal(am_get(doc, obj$obj_id, "string_val"), "hello")
  expect_equal(am_get(doc, obj$obj_id, "raw_val"), raw_data)
  expect_s3_class(am_get(doc, obj$obj_id, "timestamp_val"), "POSIXct")
  expect_s3_class(am_get(doc, obj$obj_id, "counter_val"), "am_counter")
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
  expect_equal(am_get(doc2, project$obj_id, "name"), "MyProject")

  metadata <- am_get(doc2, project$obj_id, "metadata")
  expect_s3_class(am_get(doc2, metadata$obj_id, "created"), "POSIXct")

  tags <- am_get(doc2, metadata$obj_id, "tags")
  expect_equal(am_length(doc2, tags$obj_id), 2L)

  stats <- am_get(doc2, metadata$obj_id, "stats")
  commits <- am_get(doc2, stats$obj_id, "commits")
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
  l2 <- am_get(doc, l1$obj_id, "level2")
  l3 <- am_get(doc, l2$obj_id, "level3")
  l4 <- am_get(doc, l3$obj_id, "level4")
  l5 <- am_get(doc, l4$obj_id, "level5")
  value <- am_get(doc, l5$obj_id, "level6")

  expect_equal(value, "deep value")
})

test_that("Empty nested structures work", {
  doc <- am_create()

  # Empty map in map
  am_put(doc, AM_ROOT, "outer", list(inner = list()))
  outer <- am_get(doc, AM_ROOT, "outer")
  inner <- am_get(doc, outer$obj_id, "inner")
  expect_equal(am_length(doc, inner$obj_id), 0L)

  # Empty list in map
  am_put(doc, AM_ROOT, "container", list(items = am_list()))
  container <- am_get(doc, AM_ROOT, "container")
  items <- am_get(doc, container$obj_id, "items")
  expect_equal(am_length(doc, items$obj_id), 0L)
})
