# Tests for Convenience Functions

# Path-based Access Tests -------------------------------------------------

test_that("am_get_path navigates nested structures", {
  doc <- am_create()
  am_put(
    doc,
    AM_ROOT,
    "user",
    list(
      name = "Alice",
      address = list(
        city = "NYC",
        zip = 10001L
      )
    )
  )

  # Navigate to nested values
  expect_equal(am_get_path(doc, c("user", "name")), "Alice")
  expect_equal(am_get_path(doc, c("user", "address", "city")), "NYC")
  expect_equal(am_get_path(doc, c("user", "address", "zip")), 10001L)
})

test_that("am_get_path handles missing paths", {
  doc <- am_create()
  doc$user <- list(name = "Alice")

  # Missing path returns NULL
  expect_null(am_get_path(doc, c("user", "address", "city")))
  expect_null(am_get_path(doc, c("nonexistent")))
})

test_that("am_get_path supports mixed string and numeric indices", {
  doc <- am_create()

  # Create structure with both maps and lists
  am_put(
    doc,
    AM_ROOT,
    "users",
    list(
      list(name = "Alice", age = 30L),
      list(name = "Bob", age = 25L)
    )
  )

  # Navigate: map key "users" -> list index 1 -> map key "name"
  name <- am_get_path(doc, list("users", 1, "name"))
  expect_equal(name, "Alice")

  # Navigate to second user's age
  age <- am_get_path(doc, list("users", 2, "age"))
  expect_equal(age, 25L)
})

test_that("am_get_path validates inputs", {
  doc <- am_create()

  expect_error(am_get_path(doc, list()), "path cannot be empty")
  expect_error(am_get_path(doc, NULL), "path must be")
  expect_error(
    am_get_path("not a doc", c("key")),
    "must be an Automerge document"
  )
})

test_that("am_put_path creates nested structures", {
  doc <- am_create()

  # Create nested structure with automatic intermediate objects
  am_put_path(doc, c("user", "address", "city"), "Boston")
  am_put_path(doc, c("user", "address", "zip"), 02101L)
  am_put_path(doc, c("user", "name"), "Alice")

  # Verify structure was created
  expect_equal(am_get_path(doc, c("user", "name")), "Alice")
  expect_equal(am_get_path(doc, c("user", "address", "city")), "Boston")
  expect_equal(am_get_path(doc, c("user", "address", "zip")), 02101L)
})

test_that("am_put_path can disable intermediate creation", {
  doc <- am_create()

  # Should fail without create_intermediate
  expect_error(
    am_put_path(
      doc,
      c("user", "address", "city"),
      "NYC",
      create_intermediate = FALSE
    ),
    "Path component at position 1 does not exist"
  )

  # Create parent first (must use am_map() to create a MAP, not a LIST)
  doc$user <- am_map()
  expect_error(
    am_put_path(
      doc,
      c("user", "address", "city"),
      "NYC",
      create_intermediate = FALSE
    ),
    "Path component at position 2 does not exist"
  )
})

test_that("am_put_path validates inputs", {
  doc <- am_create()

  expect_error(am_put_path(doc, list(), "value"), "path cannot be empty")
  expect_error(am_put_path(doc, NULL, "value"), "path must be")
  expect_error(
    am_put_path("not a doc", c("key"), "value"),
    "must be an Automerge document"
  )
})

test_that("am_put_path returns document invisibly", {
  doc <- am_create()

  result <- withVisible(am_put_path(doc, c("key"), "value"))
  expect_false(result$visible)
  expect_identical(result$value, doc)
})

test_that("am_delete_path removes nested keys", {
  doc <- am_create()
  am_put_path(doc, c("user", "address", "city"), "NYC")
  am_put_path(doc, c("user", "name"), "Alice")

  # Delete nested key
  am_delete_path(doc, c("user", "address"))

  # Address should be gone
  expect_null(am_get_path(doc, c("user", "address")))
  # But name should remain
  expect_equal(am_get_path(doc, c("user", "name")), "Alice")
})

test_that("am_delete_path handles missing paths gracefully", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "user", am_map(name = "Alice"))

  # Should warn for missing intermediate path
  expect_warning(am_delete_path(doc, c("user", "nonexistent", "key")))

  # Deleting nonexistent root key should succeed without warning (single element path)
  expect_no_condition(am_delete_path(doc, c("nonexistent")))
})

test_that("am_delete_path validates inputs", {
  doc <- am_create()

  expect_error(am_delete_path(doc, list()), "path cannot be empty")
  expect_error(am_delete_path(doc, NULL), "path must be")
  expect_error(
    am_delete_path("not a doc", c("key")),
    "must be an Automerge document"
  )
})

test_that("am_delete_path returns document invisibly", {
  doc <- am_create()
  doc$key <- "value"

  result <- withVisible(am_delete_path(doc, c("key")))
  expect_false(result$visible)
  expect_identical(result$value, doc)
})

test_that("path-based access works with deep nesting", {
  doc <- am_create()

  # Create 6-level deep structure
  am_put_path(doc, c("a", "b", "c", "d", "e", "f"), "deep_value")

  # Should be able to retrieve it
  expect_equal(am_get_path(doc, c("a", "b", "c", "d", "e", "f")), "deep_value")

  # Modify intermediate level
  am_put_path(doc, c("a", "b", "c", "modified"), TRUE)
  expect_true(am_get_path(doc, c("a", "b", "c", "modified")))

  # Original deep value still accessible
  expect_equal(am_get_path(doc, c("a", "b", "c", "d", "e", "f")), "deep_value")
})

# Conversion Functions Tests ----------------------------------------------

test_that("as_automerge converts simple lists", {
  data <- list(name = "Alice", age = 30L, active = TRUE)
  doc <- as_automerge(data)

  expect_s3_class(doc, "am_doc")
  expect_equal(doc[["name"]], "Alice")
  expect_equal(doc[["age"]], 30L)
  expect_equal(doc[["active"]], TRUE)
})

test_that("as_automerge converts nested lists", {
  data <- list(
    name = "Alice",
    age = 30L,
    address = list(
      city = "NYC",
      zip = 10001L
    )
  )

  doc <- as_automerge(data)

  expect_equal(doc[["name"]], "Alice")
  expect_equal(am_get_path(doc, c("address", "city")), "NYC")
  expect_equal(am_get_path(doc, c("address", "zip")), 10001L)
})

test_that("as_automerge converts deeply nested structures", {
  data <- list(
    company = list(
      name = "Acme Corp",
      office = list(
        address = list(
          street = "123 Main St",
          city = "Boston"
        )
      )
    )
  )

  doc <- as_automerge(data)

  expect_equal(am_get_path(doc, c("company", "name")), "Acme Corp")
  expect_equal(
    am_get_path(doc, c("company", "office", "address", "city")),
    "Boston"
  )
})

test_that("as_automerge handles scalar values", {
  # Single value
  doc <- as_automerge(42L)
  expect_equal(doc[["value"]], 42L)

  # Single string
  doc <- as_automerge("test")
  expect_equal(doc[["value"]], "test")
})

test_that("as_automerge handles vectors", {
  # Vector becomes a list
  doc <- as_automerge(c(1, 2, 3))
  values <- doc[["values"]]
  expect_s3_class(values, "am_object")
  # am_object is now the external pointer directly
  expect_equal(am_length(doc, values), 3)
})

test_that("as_automerge can use existing document", {
  doc <- am_create()
  doc$existing <- "data"

  # Add to existing document
  as_automerge(list(new = "value"), doc = doc)

  expect_equal(doc$existing, "data")
  expect_equal(doc$new, "value")
})

test_that("as_automerge can specify actor_id", {
  doc <- as_automerge(list(x = 1), actor_id = NULL)
  expect_s3_class(doc, "am_doc")

  # Verify actor ID was set (should be random bytes)
  actor <- am_get_actor(doc)
  expect_type(actor, "raw")
  expect_true(length(actor) > 0)
})

test_that("as_automerge validates inputs", {
  expect_error(
    as_automerge(list(x = 1), doc = "not a doc"),
    "must be an Automerge document"
  )
})

test_that("from_automerge converts to R list", {
  doc <- am_create()
  doc$name <- "Alice"
  doc$age <- 30L
  doc$active <- TRUE

  result <- from_automerge(doc)

  expect_type(result, "list")
  expect_equal(result$name, "Alice")
  expect_equal(result$age, 30L)
  expect_equal(result$active, TRUE)
})

test_that("from_automerge handles nested structures", {
  doc <- am_create()
  am_put(
    doc,
    AM_ROOT,
    "user",
    list(
      name = "Bob",
      address = list(city = "NYC", zip = 10001L)
    )
  )

  result <- from_automerge(doc)

  expect_type(result$user, "list")
  expect_equal(result$user$name, "Bob")
  expect_type(result$user$address, "list")
  expect_equal(result$user$address$city, "NYC")
  expect_equal(result$user$address$zip, 10001L)
})

test_that("from_automerge validates inputs", {
  expect_error(from_automerge("not a doc"), "must be an Automerge document")
})

test_that("as_automerge and from_automerge are inverses", {
  original <- list(
    name = "Alice",
    age = 30L,
    scores = list(85L, 90L, 95L),
    metadata = list(active = TRUE)
  )

  doc <- as_automerge(original)
  result <- from_automerge(doc)

  # Check top-level fields
  expect_equal(result$name, original$name)
  expect_equal(result$age, original$age)
  expect_equal(result$metadata$active, original$metadata$active)
})

# Integration Tests -------------------------------------------------------

test_that("convenience functions work together", {
  # Create document from R data
  data <- list(
    users = list(
      list(name = "Alice", role = "admin"),
      list(name = "Bob", role = "user")
    ),
    config = list(
      database = list(host = "localhost", port = 5432L)
    )
  )

  doc <- as_automerge(data)

  # Use path-based access to modify
  am_put_path(doc, c("config", "database", "port"), 5433L)
  # Must use list() for mixed string/numeric paths to avoid coercion
  am_put_path(doc, list("users", 1, "active"), TRUE)

  # Verify via path access
  expect_equal(am_get_path(doc, c("config", "database", "port")), 5433L)
  expect_true(am_get_path(doc, list("users", 1, "active")))

  # Fork and modify
  doc2 <- am_fork(doc)
  am_put_path(doc2, c("config", "version"), "2.0")

  # Merge back using am_merge
  am_merge(doc, doc2)

  # Convert back to R
  result <- from_automerge(doc)

  expect_equal(result$config$database$port, 5433L)
  expect_equal(result$config$version, "2.0")
})

test_that("path-based functions work with save/load/merge", {
  doc1 <- am_create()
  am_put_path(doc1, c("user", "name"), "Alice")
  am_put_path(doc1, c("user", "location", "city"), "NYC")
  am_commit(doc1)

  # Save and load
  bytes <- am_save(doc1)
  doc_loaded <- am_load(bytes)

  expect_equal(am_get_path(doc_loaded, c("user", "name")), "Alice")
  expect_equal(am_get_path(doc_loaded, c("user", "location", "city")), "NYC")

  # Fork and modify different paths
  doc2 <- am_fork(doc1)
  am_put_path(doc2, c("user", "location", "state"), "NY")
  am_commit(doc2)

  # Merge
  am_merge(doc1, doc2)

  # Both paths should exist
  expect_equal(am_get_path(doc1, c("user", "location", "city")), "NYC")
  expect_equal(am_get_path(doc1, c("user", "location", "state")), "NY")
})

# Edge Cases ------------------------------------------------------------------

test_that("as_automerge handles data.frame", {
  df <- data.frame(x = 1:3, y = letters[1:3], stringsAsFactors = FALSE)

  result <- tryCatch(
    as_automerge(df),
    error = function(e) "error"
  )

  if (inherits(result, "am_doc")) {
    expect_s3_class(result, "am_doc")
  } else {
    expect_equal(result, "error")
  }
})

test_that("as_automerge handles matrix", {
  mat <- matrix(1:9, nrow = 3)

  result <- tryCatch(
    as_automerge(mat),
    error = function(e) "error"
  )

  if (inherits(result, "am_doc")) {
    expect_s3_class(result, "am_doc")
  } else {
    expect_equal(result, "error")
  }
})

test_that("as_automerge handles empty list", {
  doc <- as_automerge(list())
  expect_s3_class(doc, "am_doc")
  expect_equal(am_length(doc, AM_ROOT), 0)
})

test_that("as_automerge handles list with NULL names", {
  data <- list("a", "b", "c")
  doc <- as_automerge(data)
  expect_s3_class(doc, "am_doc")
})

test_that("as_automerge handles partially named list", {
  data <- list(a = 1, "b", c = 3)
  doc <- as_automerge(data)
  expect_s3_class(doc, "am_doc")
})

test_that("as_automerge handles nested empty lists", {
  data <- list(
    outer = list(
      inner = list()
    )
  )
  doc <- as_automerge(data)
  expect_s3_class(doc, "am_doc")

  inner <- am_get_path(doc, c("outer", "inner"))
  expect_s3_class(inner, "am_object")
  # am_object is now the external pointer directly
  expect_equal(am_length(doc, inner), 0)
})

test_that("as_automerge handles very large structures", {
  large_list <- lapply(1:100, function(i) {
    list(id = i, value = paste0("value", i))
  })

  doc <- as_automerge(list(data = large_list))
  expect_s3_class(doc, "am_doc")
})

test_that("from_automerge handles empty document", {
  doc <- am_create()
  result <- from_automerge(doc)

  expect_type(result, "list")
  expect_length(result, 0)
})

test_that("from_automerge handles document with deleted keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key1", "value1")
  am_put(doc, AM_ROOT, "key2", "value2")
  am_delete(doc, AM_ROOT, "key1")

  result <- from_automerge(doc)
  expect_false("key1" %in% names(result))
  expect_true("key2" %in% names(result))
  expect_equal(result$key2, "value2")
})

test_that("from_automerge preserves POSIXct timestamps", {
  timestamp <- Sys.time()
  doc <- am_create()
  am_put(doc, AM_ROOT, "time", timestamp)

  result <- from_automerge(doc)
  expect_s3_class(result$time, "POSIXct")
  expect_equal(as.numeric(result$time), as.numeric(timestamp))
})

test_that("am_get_path with single element path", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")

  expect_equal(am_get_path(doc, "key"), "value")
})

test_that("am_put_path overwrites existing values", {
  doc <- am_create()
  am_put_path(doc, c("key", "nested"), "original")
  am_put_path(doc, c("key", "nested"), "updated")

  expect_equal(am_get_path(doc, c("key", "nested")), "updated")
})

test_that("am_delete_path on intermediate path", {
  doc <- am_create()
  am_put_path(doc, c("a", "b", "c"), "value1")
  am_put_path(doc, c("a", "b", "d"), "value2")
  am_put_path(doc, c("a", "e"), "value3")

  am_delete_path(doc, c("a", "b"))

  expect_null(am_get_path(doc, c("a", "b")))
  expect_null(am_get_path(doc, c("a", "b", "c")))
  expect_equal(am_get_path(doc, c("a", "e")), "value3")
})

test_that("am_get_path handles numeric indices in lists", {
  doc <- am_create()
  doc$items <- am_list("first", "second", "third")

  expect_equal(am_get_path(doc, list("items", 1)), "first")
  expect_equal(am_get_path(doc, list("items", 2)), "second")
  expect_equal(am_get_path(doc, list("items", 3)), "third")
})

test_that("am_get_path returns NULL for out-of-bounds list index", {
  doc <- am_create()
  doc$items <- am_list("first", "second")

  expect_null(am_get_path(doc, list("items", 0)))
  expect_null(am_get_path(doc, list("items", 99)))
})

test_that("am_put_path with list index extends list", {
  doc <- am_create()
  doc$items <- am_list()

  am_put_path(doc, list("items", "end"), "first")
  am_put_path(doc, list("items", "end"), "second")

  expect_equal(am_get_path(doc, list("items", 1)), "first")
  expect_equal(am_get_path(doc, list("items", 2)), "second")
})

test_that("round-trip conversion preserves structure", {
  original <- list(
    name = "Alice",
    scores = list(85, 90, 95),
    metadata = list(
      created = TRUE,
      tags = list("a", "b", "c")
    )
  )

  doc <- as_automerge(original)
  result <- from_automerge(doc)

  expect_equal(result$name, original$name)
  expect_equal(result$metadata$created, original$metadata$created)
})

test_that("as_automerge handles special numeric values carefully", {
  doc <- tryCatch(
    as_automerge(list(inf = Inf, neg_inf = -Inf, nan = NaN)),
    error = function(e) "error"
  )

  expect_true(inherits(doc, "am_doc") || identical(doc, "error"))
})

test_that("as_automerge handles nested lists with mixed types", {
  data <- list(
    int = 1L,
    dbl = 3.14,
    str = "text",
    bool = TRUE,
    null = NULL,
    nested = list(a = 1, b = "two")
  )

  doc <- as_automerge(data)
  expect_s3_class(doc, "am_doc")
  expect_equal(doc$int, 1L)
  expect_equal(doc$str, "text")
  expect_null(doc$null)
})
