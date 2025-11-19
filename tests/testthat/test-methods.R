# S3 Methods Tests (Phase 4)

# Document Extraction Methods -------------------------------------------------

test_that("[[ and $ extract from document root", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "name", "Alice")
  am_put(doc, AM_ROOT, "age", 30L)
  am_put(doc, AM_ROOT, "active", TRUE)

  # [[ operator
  expect_equal(doc[["name"]], "Alice")
  expect_equal(doc[["age"]], 30L)
  expect_equal(doc[["active"]], TRUE)

  # $ operator
  expect_equal(doc$name, "Alice")
  expect_equal(doc$age, 30L)
  expect_equal(doc$active, TRUE)
})

test_that("[[ and $ return NULL for missing keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "exists", "value")

  expect_null(doc[["missing"]])
  expect_null(doc$missing)
})

test_that("[[ and $ extract nested objects", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L))

  user <- doc[["user"]]
  expect_s3_class(user, "am_object")

  user2 <- doc$user
  expect_s3_class(user2, "am_object")

  # Can access nested values
  expect_equal(user$name, "Bob")
  expect_equal(user$age, 25L)
})

# Document Replacement Methods ------------------------------------------------

test_that("[[<- and $<- assign to document root", {
  doc <- am_create()

  # [[<- operator
  doc[["name"]] <- "Charlie"
  expect_equal(doc[["name"]], "Charlie")

  # $<- operator
  doc$age <- 35L
  expect_equal(doc$age, 35L)
})

test_that("[[<- and $<- update existing keys", {
  doc <- am_create()
  doc$value <- "original"
  expect_equal(doc$value, "original")

  doc$value <- "updated"
  expect_equal(doc$value, "updated")

  doc[["value"]] <- "final"
  expect_equal(doc[["value"]], "final")
})

test_that("[[<- and $<- work with nested structures", {
  doc <- am_create()
  doc$config <- list(debug = TRUE, level = 3L)

  config <- doc$config
  expect_s3_class(config, "am_object")
  expect_equal(config$debug, TRUE)
  expect_equal(config$level, 3L)
})

test_that("[[<- and $<- work with all value types", {
  doc <- am_create()

  doc$null_val <- NULL
  doc$bool_val <- FALSE
  doc$int_val <- 42L
  doc$double_val <- 3.14
  doc$string_val <- "test"
  doc$raw_val <- as.raw(c(1, 2, 3))

  expect_null(doc$null_val)
  expect_equal(doc$bool_val, FALSE)
  expect_equal(doc$int_val, 42L)
  expect_equal(doc$double_val, 3.14)
  expect_equal(doc$string_val, "test")
  expect_equal(doc$raw_val, as.raw(c(1, 2, 3)))
})

# Document Utility Methods ----------------------------------------------------

test_that("length() returns number of root keys", {
  doc <- am_create()
  expect_equal(length(doc), 0L)

  doc$a <- 1
  expect_equal(length(doc), 1L)

  doc$b <- 2
  doc$c <- 3
  expect_equal(length(doc), 3L)
})

test_that("names() returns root keys", {
  doc <- am_create()
  expect_equal(names(doc), character(0))

  doc$name <- "Alice"
  doc$age <- 30L
  doc$active <- TRUE

  doc_names <- names(doc)
  expect_type(doc_names, "character")
  expect_length(doc_names, 3)
  expect_true(all(c("name", "age", "active") %in% doc_names))
})

test_that("print() displays document info", {
  doc <- am_create()
  doc$name <- "Test"
  doc$value <- 123L

  output <- capture.output(print(doc))
  expect_true(any(grepl("Automerge Document", output)))
  expect_true(any(grepl("Actor:", output)))
  expect_true(any(grepl("Root keys:", output)))
})

test_that("as.list() converts document to R list", {
  doc <- am_create()
  doc$name <- "Alice"
  doc$age <- 30L
  doc$active <- TRUE

  result <- as.list(doc)
  expect_type(result, "list")
  # Don't check order as automerge may return keys in different order
  expect_setequal(names(result), c("name", "age", "active"))
  expect_equal(result$name, "Alice")
  expect_equal(result$age, 30L)
  expect_equal(result$active, TRUE)
})

test_that("as.list() recursively converts nested structures", {
  doc <- am_create()
  doc$user <- list(
    name = "Bob",
    profile = list(
      city = "Boston",
      zip = 02101L
    )
  )

  result <- as.list(doc)
  expect_type(result$user, "list")
  expect_equal(result$user$name, "Bob")
  expect_type(result$user$profile, "list")
  expect_equal(result$user$profile$city, "Boston")
  expect_equal(result$user$profile$zip, 02101L)
})

# Object Extraction Methods ---------------------------------------------------

test_that("[[ and $ extract from am_object (maps)", {
  doc <- am_create()
  user <- am_put(doc, AM_ROOT, "user", list(name = "David", age = 40L))

  # [[ operator
  expect_equal(user[["name"]], "David")
  expect_equal(user[["age"]], 40L)

  # $ operator
  expect_equal(user$name, "David")
  expect_equal(user$age, 40L)
})

test_that("[[ extracts from am_object (lists)", {
  doc <- am_create()
  items <- am_put(doc, AM_ROOT, "items", am_list("a", "b", "c"))

  # [[ operator with integer index (1-based)
  expect_equal(items[[1]], "a")
  expect_equal(items[[2]], "b")
  expect_equal(items[[3]], "c")
})

test_that("[[ and $ return NULL for missing keys in am_object", {
  doc <- am_create()
  obj <- am_put(doc, AM_ROOT, "obj", list(key = "value"))

  expect_null(obj[["missing"]])
  expect_null(obj$missing)
})

# Object Replacement Methods --------------------------------------------------

test_that("[[<- and $<- assign to am_object (maps)", {
  doc <- am_create()
  config <- am_put(doc, AM_ROOT, "config", am_map())

  # [[<- operator
  config[["option1"]] <- "value1"
  expect_equal(config[["option1"]], "value1")

  # $<- operator
  config$option2 <- "value2"
  expect_equal(config$option2, "value2")
})

test_that("[[<- assigns to am_object (lists)", {
  doc <- am_create()
  items <- am_put(doc, AM_ROOT, "items", am_list("a", "b", "c"))

  # Replace element
  items[[2]] <- "modified"
  expect_equal(items[[2]], "modified")
  expect_equal(length(items), 3L)
})

test_that("[[<- and $<- modify the underlying document", {
  doc <- am_create()
  user <- am_put(doc, AM_ROOT, "user", list(name = "Original"))

  user$name <- "Updated"

  # Check via object
  expect_equal(user$name, "Updated")

  # Check via document
  user_retrieved <- doc$user
  expect_equal(user_retrieved$name, "Updated")
})

# Object Utility Methods ------------------------------------------------------

test_that("length() works on am_object (maps)", {
  doc <- am_create()
  obj <- am_put(doc, AM_ROOT, "obj", list(a = 1, b = 2, c = 3))

  expect_equal(length(obj), 3L)

  obj$d <- 4
  expect_equal(length(obj), 4L)
})

test_that("length() works on am_object (lists)", {
  doc <- am_create()
  items <- am_put(doc, AM_ROOT, "items", am_list("x", "y", "z"))

  expect_equal(length(items), 3L)
})

test_that("names() returns keys for am_object (maps)", {
  doc <- am_create()
  obj <- am_put(doc, AM_ROOT, "obj", list(alpha = 1, beta = 2, gamma = 3))

  obj_names <- names(obj)
  expect_type(obj_names, "character")
  expect_length(obj_names, 3)
  expect_true(all(c("alpha", "beta", "gamma") %in% obj_names))
})

test_that("names() returns NULL or element IDs for am_object (lists)", {
  doc <- am_create()
  items <- am_put(doc, AM_ROOT, "items", am_list("a", "b", "c"))

  # Lists may return element IDs or NULL
  # This is implementation-specific
  result <- names(items)
  expect_true(is.null(result) || is.character(result))
})

test_that("print() displays am_object info", {
  doc <- am_create()
  user <- am_put(doc, AM_ROOT, "user", list(name = "Test", age = 25L))

  output <- capture.output(print(user))
  expect_true(any(grepl("Map object", output)))
  expect_true(any(grepl("Length:", output)))
  expect_true(any(grepl("Keys:", output)))
})

test_that("as.list() converts am_object to R list", {
  doc <- am_create()
  user <- am_put(doc, AM_ROOT, "user", list(
    name = "Emma",
    age = 28L,
    tags = am_list("dev", "ops")
  ))

  result <- as.list(user)
  expect_type(result, "list")
  expect_equal(result$name, "Emma")
  expect_equal(result$age, 28L)
  expect_type(result$tags, "list")
  expect_equal(result$tags[[1]], "dev")
  expect_equal(result$tags[[2]], "ops")
})

# Integration Tests -----------------------------------------------------------

test_that("S3 methods work seamlessly together", {
  doc <- am_create()

  # Use $<- to build structure
  doc$project <- list(name = "MyApp")
  doc$version <- "1.0.0"

  # Use $ to retrieve and modify nested
  project <- doc$project
  project$description <- "A test application"

  # Use length and names
  expect_equal(length(doc), 2L)
  expect_true("project" %in% names(doc))
  expect_true("version" %in% names(doc))

  expect_equal(length(project), 2L)
  expect_true(all(c("name", "description") %in% names(project)))
})

test_that("S3 methods work with deeply nested structures", {
  doc <- am_create()

  # Build deep structure with operators
  doc$company <- list(
    name = "Acme",
    office = list(
      location = "NYC",
      floor = 5L
    )
  )

  # Navigate and modify using operators
  office <- doc$company$office
  office$floor <- 10L

  # Verify
  expect_equal(doc$company$office$floor, 10L)
})

test_that("S3 methods work after save/load", {
  doc1 <- am_create()
  doc1$data <- list(x = 1, y = 2)
  doc1$status <- "active"

  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  # S3 methods should work on loaded document
  expect_equal(doc2$status, "active")
  expect_equal(length(doc2), 2L)
  expect_true(all(c("data", "status") %in% names(doc2)))

  data <- doc2$data
  expect_equal(data$x, 1)
  expect_equal(data$y, 2)
})

test_that("as.list() handles complex nested structures", {
  doc <- am_create()
  doc$data <- list(
    users = am_list(
      list(name = "Alice", age = 30L),
      list(name = "Bob", age = 25L)
    ),
    metadata = list(
      created = Sys.time(),
      version = "2.0"
    )
  )

  result <- as.list(doc)
  expect_type(result$data, "list")
  expect_type(result$data$users, "list")
  expect_length(result$data$users, 2)
  expect_equal(result$data$users[[1]]$name, "Alice")
  expect_equal(result$data$users[[2]]$name, "Bob")
  expect_equal(result$data$metadata$version, "2.0")
})

test_that("S3 methods respect CRDT semantics", {
  doc1 <- am_create()
  doc2 <- am_fork(doc1)

  # Make concurrent changes using S3 methods
  doc1$value <- "from_doc1"
  doc2$value <- "from_doc2"

  # Merge
  am_merge(doc1, doc2)

  # One value should win (last-write-wins for scalars)
  result <- doc1$value
  expect_true(result %in% c("from_doc1", "from_doc2"))
})
