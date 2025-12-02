# S3 Methods for Automerge Objects

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
}

#' @rdname replace-am_doc
#' @export
`$<-.am_doc` <- function(x, name, value) {
  am_put(x, AM_ROOT, name, value)
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

  actor_hex <- am_get_actor_hex(x)
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
  root_values <- am_values(x, AM_ROOT)
  result <- lapply(root_values, function(value) {
    if (inherits(value, "am_object")) {
      as.list(value)
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
#' am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L))
#' user <- am_get(doc, AM_ROOT, "user")
#'
#' user[["name"]]  # "Bob"
#' user$age        # 25L
`[[.am_object` <- function(x, i) {
  doc <- .Call(C_get_doc_from_objid, x)
  am_get(doc, x, i)
}

#' @rdname extract-am_object
#' @export
`$.am_object` <- function(x, name) {
  doc <- .Call(C_get_doc_from_objid, x)
  am_get(doc, x, name)
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
#' am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L))
#' user <- am_get(doc, AM_ROOT, "user")
#'
#' user[["name"]] <- "Alice"
#' user$age <- 30L
`[[<-.am_object` <- function(x, i, value) {
  doc <- .Call(C_get_doc_from_objid, x)
  am_put(doc, x, i, value)
  x
}

#' @rdname replace-am_object
#' @export
`$<-.am_object` <- function(x, name, value) {
  doc <- .Call(C_get_doc_from_objid, x)
  am_put(doc, x, name, value)
  x
}

#' Get length of Automerge object
#'
#' Returns the number of elements/keys in an Automerge object.
#'
#' @param x An Automerge object
#' @return Integer length
#' @export
length.am_object <- function(x) {
  doc <- .Call(C_get_doc_from_objid, x)
  am_length(doc, x)
}

#' Get names from Automerge map object
#'
#' Returns the keys from a map object.
#'
#' @param x An Automerge map object
#' @return Character vector of key names
#' @export
names.am_map <- function(x) {
  doc <- .Call(C_get_doc_from_objid, x)
  am_keys(doc, x)
}

#' Print Automerge counter
#'
#' @param x An Automerge counter
#' @param ... Additional arguments (unused)
#' @return The counter (invisibly)
#' @export
print.am_counter <- function(x, ...) {
  cat("<Automerge Counter:", as.integer(x), ">\n")
  invisible(x)
}

#' Print Automerge object (fallback for unknown types)
#'
#' @param x An Automerge object
#' @param ... Additional arguments (unused)
#' @return The object (invisibly)
#' @export
print.am_object <- function(x, ...) {
  cat("<Automerge Object>\n")
  invisible(x)
}

#' Print Automerge map object
#'
#' @param x An Automerge map object
#' @param ... Additional arguments (unused)
#' @return The object (invisibly)
#' @export
print.am_map <- function(x, ...) {
  doc <- .Call(C_get_doc_from_objid, x)
  obj_len <- am_length(doc, x)
  cat("<Automerge Map>\n")
  cat("Length:", obj_len, "\n")

  if (obj_len > 0) {
    keys <- am_keys(doc, x)
    cat("Keys:", paste(keys[seq_len(min(5, length(keys)))], collapse = ", "))
    if (obj_len > 5) {
      cat(", ...")
    }
    cat("\n")
  }

  invisible(x)
}

#' Print Automerge list object
#'
#' @param x An Automerge list object
#' @param ... Additional arguments (unused)
#' @return The object (invisibly)
#' @export
print.am_list <- function(x, ...) {
  doc <- .Call(C_get_doc_from_objid, x)
  obj_len <- am_length(doc, x)
  cat("<Automerge List>\n")
  cat("Length:", obj_len, "\n")

  invisible(x)
}

#' Print Automerge text object
#'
#' @param x An Automerge text object
#' @param ... Additional arguments (unused)
#' @return The object (invisibly)
#' @export
print.am_text <- function(x, ...) {
  text_content <- am_text_get(x)
  cat("<Automerge Text>\n")
  cat("Length:", nchar(text_content), "characters\n")

  if (nchar(text_content) > 50) {
    cat("Content:", paste0('"', substr(text_content, 1, 47), '..."'), "\n")
  } else {
    cat("Content:", paste0('"', text_content, '"'), "\n")
  }

  invisible(x)
}

#' Convert Automerge map to R list
#'
#' Recursively converts an Automerge map to a named R list.
#'
#' @param x An Automerge map object
#' @param doc The document containing this object (automatically provided)
#' @param ... Additional arguments (unused)
#' @return Named list
#' @keywords internal
as.list.am_map <- function(x, doc = NULL, ...) {
  if (is.null(doc)) {
    doc <- .Call(C_get_doc_from_objid, x)
  }
  keys <- am_keys(doc, x)
  values <- am_values(doc, x)
  result <- lapply(values, function(value) {
    if (inherits(value, "am_object")) {
      as.list(value, doc = doc)
    } else {
      value
    }
  })
  names(result) <- keys
  result
}

#' Convert Automerge list to R list
#'
#' Recursively converts an Automerge list to an unnamed R list.
#'
#' @param x An Automerge list object
#' @param doc The document containing this object (automatically provided)
#' @param ... Additional arguments (unused)
#' @return Unnamed list
#' @keywords internal
as.list.am_list <- function(x, doc = NULL, ...) {
  if (is.null(doc)) {
    doc <- .Call(C_get_doc_from_objid, x)
  }
  values <- am_values(doc, x)
  result <- lapply(values, function(value) {
    if (inherits(value, "am_object")) {
      as.list(value, doc = doc)
    } else {
      value
    }
  })
  result
}

#' Convert Automerge text to character string
#'
#' Returns the text content as a character string.
#'
#' @param x An Automerge text object
#' @param doc The document containing this object (automatically provided)
#' @param ... Additional arguments (unused)
#' @return Character string
#' @keywords internal
as.list.am_text <- function(x, doc = NULL, ...) {
  am_text_get(x)
}

#' Convert text object to character string
#'
#' Extracts the full text content from an Automerge text object as a standard
#' character string.
#'
#' @param x An Automerge text object
#' @param ... Additional arguments (unused)
#' @return Character string with the full text content
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "notes", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "notes")
#'
#' text_string <- as.character(text_obj)
#' text_string  # "Hello World"
#'
#' identical(as.character(text_obj), am_text_get(text_obj))  # TRUE
as.character.am_text <- function(x, ...) {
  am_text_get(x)
}

#' Print Automerge cursor
#'
#' @param x An Automerge cursor
#' @param ... Additional arguments (unused)
#' @return The cursor (invisibly)
#' @export
print.am_cursor <- function(x, ...) {
  cat("<Automerge Cursor>\n")
  invisible(x)
}

#' Print Automerge sync state
#'
#' @param x An Automerge sync state
#' @param ... Additional arguments (unused)
#' @return The sync state (invisibly)
#' @export
print.am_syncstate <- function(x, ...) {
  cat("<Automerge Sync State>\n")
  invisible(x)
}
