# Convenience Functions for Automerge

# Path-based Access Helpers -----------------------------------------------

#' Navigate deep structures with path
#'
#' Get a value from an Automerge document using a path vector. The path can
#' contain character keys (for maps), numeric indices (for lists, 1-based),
#' or a mix of both.
#'
#' @param doc An Automerge document
#' @param path Character vector, numeric vector, or list of mixed types
#'   specifying the path to navigate
#' @return The value at the path, or NULL if not found
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "user", list(
#'   name = "Alice",
#'   address = list(city = "NYC", zip = 10001L)
#' ))
#'
#' # Navigate to nested value
#' am_get_path(doc, c("user", "address", "city"))  # "NYC"
#'
#' # Mixed navigation (map key, then list index)
#' doc$users <- list(
#'   list(name = "Bob"),
#'   list(name = "Carol")
#' )
#' am_get_path(doc, list("users", 1, "name"))  # "Bob"
am_get_path <- function(doc, path) {
  if (!inherits(doc, "am_doc")) {
    stop("doc must be an Automerge document (am_doc)")
  }

  if (!is.character(path) && !is.numeric(path) && !is.list(path)) {
    stop(
      "path must be a character vector, numeric vector, or list of mixed types"
    )
  }

  if (length(path) == 0L) {
    stop("path cannot be empty")
  }

  obj <- AM_ROOT

  for (key in path) {
    obj <- am_get(doc, obj, key)

    if (is.null(obj)) {
      return()
    }
  }

  obj
}

#' Set value at path
#'
#' Set a value in an Automerge document using a path vector. Can optionally
#' create intermediate objects automatically.
#'
#' @param doc An Automerge document
#' @param path Character vector, numeric vector, or list of mixed types
#'   specifying the path to the value
#' @param value Value to set at the path
#' @param create_intermediate Logical. If TRUE, creates intermediate maps
#'   as needed. Default TRUE.
#' @return The document (invisibly)
#' @export
#' @examples
#' doc <- am_create()
#'
#' # Create nested structure with automatic intermediate objects
#' am_put_path(doc, c("user", "address", "city"), "Boston")
#' am_put_path(doc, c("user", "address", "zip"), 02101L)
#' am_put_path(doc, c("user", "name"), "Alice")
#'
#' # Verify
#' am_get_path(doc, c("user", "address", "city"))  # "Boston"
am_put_path <- function(doc, path, value, create_intermediate = TRUE) {
  if (!inherits(doc, "am_doc")) {
    stop("doc must be an Automerge document (am_doc)")
  }

  if (!is.character(path) && !is.numeric(path) && !is.list(path)) {
    stop(
      "path must be a character vector, numeric vector, or list of mixed types"
    )
  }

  path_len <- length(path)
  if (path_len == 0L) {
    stop("path cannot be empty")
  }

  obj <- AM_ROOT

  for (i in seq_len(path_len - 1L)) {
    key <- path[[i]]
    next_obj <- am_get(doc, obj, key)

    if (is.null(next_obj)) {
      if (create_intermediate) {
        if (is.character(key)) {
          am_put(doc, obj, key, am_map())
          next_obj <- am_get(doc, obj, key)
        } else {
          # For numeric indices, parent must already be a list
          stop(sprintf(
            "Cannot create intermediate list element at index %d",
            key
          ))
        }
      } else {
        stop(sprintf("Path component at position %d does not exist", i))
      }
    }

    if (inherits(next_obj, "am_object")) {
      obj <- next_obj
    } else {
      stop(sprintf("Path component at position %d is not an object", i))
    }
  }

  final_key <- path[[path_len]]
  am_put(doc, obj, final_key, value)

  invisible(doc)
}

#' Delete value at path
#'
#' Delete a value from an Automerge document using a path vector.
#'
#' @param doc An Automerge document
#' @param path Character vector, numeric vector, or list of mixed types
#'   specifying the path to the value to delete
#' @return The document (invisibly)
#' @export
#' @examples
#' doc <- am_create()
#' am_put_path(doc, c("user", "address", "city"), "NYC")
#' am_put_path(doc, c("user", "name"), "Alice")
#'
#' # Delete nested key
#' am_delete_path(doc, c("user", "address"))
#'
#' # Address should be gone
#' am_get_path(doc, c("user", "address"))  # NULL
am_delete_path <- function(doc, path) {
  if (!inherits(doc, "am_doc")) {
    stop("doc must be an Automerge document (am_doc)")
  }

  if (!is.character(path) && !is.numeric(path) && !is.list(path)) {
    stop(
      "path must be a character vector, numeric vector, or list of mixed types"
    )
  }

  path_len <- length(path)
  if (path_len == 0L) {
    stop("path cannot be empty")
  }

  obj <- AM_ROOT

  for (i in seq_len(path_len - 1L)) {
    key <- path[[i]]
    obj_result <- am_get(doc, obj, key)

    if (is.null(obj_result)) {
      warning(sprintf("Path component at position %d does not exist", i))
      return(invisible(doc))
    }

    if (inherits(obj_result, "am_object")) {
      obj <- obj_result
    } else {
      warning(sprintf("Path component at position %d is not an object", i))
      return(invisible(doc))
    }
  }

  final_key <- path[[path_len]]
  am_delete(doc, obj, final_key)

  invisible(doc)
}

# Conversion Functions ----------------------------------------------------

#' Convert R list to Automerge document
#'
#' Converts an R list to an Automerge document. This leverages the recursive
#' conversion built into `am_put()` from Phase 3, allowing nested structures
#' to be created in a single call.
#'
#' @param x R list, vector, or scalar value to convert
#' @param doc Optional existing Automerge document. If NULL, creates a new one.
#' @param actor_id Optional actor ID for new documents (raw bytes or hex string)
#' @return An Automerge document
#' @export
#' @examples
#' # Convert nested list to Automerge
#' data <- list(
#'   name = "Alice",
#'   age = 30L,
#'   scores = list(85, 90, 95),
#'   metadata = list(
#'     created = Sys.time(),
#'     tags = list("user", "active")
#'   )
#' )
#'
#' doc <- as_automerge(data)
#' doc[["name"]]  # "Alice"
#' doc[["age"]]   # 30L
as_automerge <- function(x, doc = NULL, actor_id = NULL) {
  if (is.null(doc)) {
    doc <- am_create(actor_id = actor_id)
  } else if (!inherits(doc, "am_doc")) {
    stop("doc must be an Automerge document or NULL")
  }

  if (is.list(x)) {
    # Leverage recursive conversion: am_put handles nested structures automatically
    for (name in names(x)) {
      am_put(doc, AM_ROOT, name, x[[name]])
    }
  } else if (length(x) == 1L) {
    # Single primitive value
    am_put(doc, AM_ROOT, "value", x)
  } else {
    # Vector of values - create a list
    am_put(doc, AM_ROOT, "values", as.list(x))
  }

  doc
}

#' Convert Automerge document to R list
#'
#' Converts an Automerge document to a standard R list. This is equivalent to
#' `as.list.am_doc()`.
#'
#' @param doc An Automerge document
#' @return Named list with document contents
#' @export
#' @examples
#' doc <- am_create()
#' doc$name <- "Alice"
#' doc$age <- 30L
#'
#' from_automerge(doc)  # list(name = "Alice", age = 30L)
from_automerge <- function(doc) {
  if (!inherits(doc, "am_doc")) {
    stop("doc must be an Automerge document (am_doc)")
  }

  as.list(doc)
}
