# S3 Methods for Automerge Objects

#' @importFrom utils head
NULL

# S3 Methods for am_doc ------------------------------------------------------

#' @name extract-am_doc
#' @title Extract from Automerge document root
#'
#' @description
#' Extract values from the root of an Automerge document using `[[` or `$`.
#' These operators provide R-idiomatic access to document data.
#'
#' @param x An Automerge document
#' @param i Key name (character)
#' @param name Key name (for `$` operator)
#' @return The value at the specified key
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "name", "Alice")
#' am_put(doc, AM_ROOT, "age", 30L)
#'
#' doc[["name"]]  # "Alice"
#' doc$age        # 30L
`[[.am_doc` <- function(x, i) {
  am_get(x, AM_ROOT, i)
}

#' @rdname extract-am_doc
#' @export
`$.am_doc` <- function(x, name) {
  am_get(x, AM_ROOT, name)
}

#' @name replace-am_doc
#' @title Replace in Automerge document root
#'
#' @description
#' Replace or insert values at the root of an Automerge document using
#' `[[<-` or `$<-`. These operators provide R-idiomatic modification.
#'
#' @param x An Automerge document
#' @param i Key name (character)
#' @param name Key name (for `$<-` operator)
#' @param value Value to store
#' @return The document (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' doc[["name"]] <- "Bob"
#' doc$age <- 25L
`[[<-.am_doc` <- function(x, i, value) {
  am_put(x, AM_ROOT, i, value)
  x
}

#' @rdname replace-am_doc
#' @export
`$<-.am_doc` <- function(x, name, value) {
  am_put(x, AM_ROOT, name, value)
  x
}

#' Get length of document root
#'
#' Returns the number of keys in the root map of an Automerge document.
#'
#' @param x An Automerge document
#' @return Integer length
#' @export
#' @examples
#' doc <- am_create()
#' doc$a <- 1
#' doc$b <- 2
#' length(doc)  # 2
length.am_doc <- function(x) {
  am_length(x, AM_ROOT)
}

#' Get names from document root
#'
#' Returns the keys from the root map of an Automerge document.
#'
#' @param x An Automerge document
#' @return Character vector of key names
#' @export
#' @examples
#' doc <- am_create()
#' doc$name <- "Alice"
#' doc$age <- 30L
#' names(doc)  # c("name", "age")
names.am_doc <- function(x) {
  am_keys(x, AM_ROOT)
}

#' Print Automerge document
#'
#' Print method for Automerge documents showing basic info and root contents.
#'
#' @param x An Automerge document
#' @param ... Additional arguments (unused)
#' @return The document (invisibly)
#' @export
print.am_doc <- function(x, ...) {
  cat("<Automerge Document>\n")

  actor <- am_get_actor(x)
  actor_hex <- paste(format(actor, width = 2), collapse = "")
  cat("Actor:", actor_hex, "\n")

  root_length <- am_length(x, AM_ROOT)
  cat("Root keys:", root_length, "\n")

  if (root_length > 0) {
    root_keys <- am_keys(x, AM_ROOT)
    cat("Keys:", paste(root_keys, collapse = ", "), "\n")
  }

  invisible(x)
}

#' Convert document root to R list
#'
#' Recursively converts the root of an Automerge document to a standard R list.
#' Maps become named lists, lists become unnamed lists, and nested objects
#' are recursively converted.
#'
#' @param x An Automerge document
#' @param ... Additional arguments (unused)
#' @return Named list with document contents
#' @export
#' @examples
#' doc <- am_create()
#' doc$name <- "Alice"
#' doc$age <- 30L
#'
#' as.list(doc)  # list(name = "Alice", age = 30L)
as.list.am_doc <- function(x, ...) {
  root_keys <- am_keys(x, AM_ROOT)
  result <- lapply(root_keys, function(k) {
    value <- am_get(x, AM_ROOT, k)
    if (inherits(value, "am_object")) {
      as.list.am_object(value, x)
    } else {
      value
    }
  })
  names(result) <- root_keys
  result
}

# S3 Methods for am_object ----------------------------------------------------

#' @name extract-am_object
#' @title Extract from Automerge object
#'
#' @description
#' Extract values from an Automerge object (map or list) using `[[` or `$`.
#'
#' @param x An Automerge object
#' @param i Key name (character) for maps, or position (integer) for lists
#' @param name Key name (for `$` operator, maps only)
#' @return The value at the specified key/position
#'
#' @export
#' @examples
#' doc <- am_create()
#' user <- am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L))
#'
#' user[["name"]]  # "Bob"
#' user$age        # 25L
`[[.am_object` <- function(x, i) {
  x_unclass <- unclass(x)
  am_get(x_unclass$doc, x_unclass$obj_id, i)
}

#' @rdname extract-am_object
#' @export
`$.am_object` <- function(x, name) {
  x_unclass <- unclass(x)
  # Allow direct access to object fields (obj_id, doc)
  if (name %in% names(x_unclass)) {
    return(x_unclass[[name]])
  }
  # Otherwise delegate to am_get
  am_get(x_unclass$doc, x_unclass$obj_id, name)
}

#' @name replace-am_object
#' @title Replace in Automerge object
#'
#' @description
#' Replace or insert values in an Automerge object using `[[<-` or `$<-`.
#'
#' @param x An Automerge object
#' @param i Key name (character) for maps, or position (integer) for lists
#' @param name Key name (for `$<-` operator, maps only)
#' @param value Value to store
#' @return The object (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' user <- am_put(doc, AM_ROOT, "user", list(name = "Bob"))
#' user[["age"]] <- 25L
#' user$city <- "NYC"
`[[<-.am_object` <- function(x, i, value) {
  x_unclass <- unclass(x)
  am_put(x_unclass$doc, x_unclass$obj_id, i, value)
  x
}

#' @rdname replace-am_object
#' @export
`$<-.am_object` <- function(x, name, value) {
  x_unclass <- unclass(x)
  am_put(x_unclass$doc, x_unclass$obj_id, name, value)
  x
}

#' Get length of Automerge object
#'
#' Returns the number of elements in an Automerge object (map or list).
#'
#' @param x An Automerge object
#' @return Integer length
#' @export
#' @examples
#' doc <- am_create()
#' user <- am_put(doc, AM_ROOT, "user", list(a = 1, b = 2))
#' length(user)  # 2
length.am_object <- function(x) {
  x_unclass <- unclass(x)
  am_length(x_unclass$doc, x_unclass$obj_id)
}

#' Get names from Automerge object
#'
#' Returns the keys from an Automerge map object. Returns NULL for lists.
#'
#' @param x An Automerge object
#' @return Character vector of key names (for maps), or NULL (for lists)
#' @export
#' @examples
#' doc <- am_create()
#' user <- am_put(doc, AM_ROOT, "user", list(name = "Alice", age = 30L))
#' names(user)  # c("name", "age")
names.am_object <- function(x) {
  # Try to get keys - will return NULL for non-map objects
  tryCatch(
    am_keys(unclass(x)$doc, unclass(x)$obj_id),
    error = function(e) NULL
  )
}

#' Print Automerge object
#'
#' Print method for Automerge objects showing type and contents summary.
#'
#' @param x An Automerge object
#' @param ... Additional arguments (unused)
#' @return The object (invisibly)
#' @export
print.am_object <- function(x, ...) {
  x_unclass <- unclass(x)
  doc <- x_unclass$doc
  obj_id <- x_unclass$obj_id
  obj_len <- am_length(doc, obj_id)

  # Determine object type by checking if it has keys
  keys <- tryCatch(am_keys(doc, obj_id), error = function(e) NULL)
  is_map <- !is.null(keys)

  obj_type_label <- if (is_map) "Map" else "List"

  cat(sprintf("<%s object>\n", obj_type_label))
  cat("Length:", obj_len, "\n")

  if (is_map && obj_len > 0) {
    cat("Keys:", paste(head(keys, 5), collapse = ", "))
    if (obj_len > 5) cat(", ...")
    cat("\n")
  }

  invisible(x)
}

#' Convert Automerge object to R list
#'
#' Recursively converts an Automerge object to a standard R list.
#'
#' @param x An Automerge object
#' @param doc The document containing this object (automatically provided)
#' @param ... Additional arguments (unused)
#' @return List or named list
#' @keywords internal
as.list.am_object <- function(x, doc = unclass(x)$doc, ...) {
  x_unclass <- unclass(x)
  obj_id <- x_unclass$obj_id

  len <- am_length(doc, obj_id)

  # Try to access by numeric index first (works for lists and maps)
  result_list <- tryCatch({
    lapply(seq_len(len), function(i) {
      value <- am_get(doc, obj_id, i)
      if (inherits(value, "am_object")) {
        as.list.am_object(value, doc)
      } else {
        value
      }
    })
  }, error = function(e) {
    # If numeric indexing fails, it might be a text object
    tryCatch(am_text_get(doc, obj_id), error = function(e2) list())
  })

  # Check if it's a map by trying to get keys
  keys <- tryCatch(am_keys(doc, obj_id), error = function(e) NULL)

  # If keys exist and look like map keys (not element IDs), use them
  # Map keys are regular strings, element IDs contain '@'
  if (!is.null(keys) && length(keys) > 0 && !grepl("@", keys[1])) {
    # It's a map - create named list
    result <- lapply(keys, function(k) {
      value <- am_get(doc, obj_id, k)
      if (inherits(value, "am_object")) {
        as.list.am_object(value, doc)
      } else {
        value
      }
    })
    names(result) <- keys
    return(result)
  }

  # Otherwise return unnamed list
  result_list
}
