# Object Operations

#' Put a value into an Automerge map or list
#'
#' Inserts or updates a value in an Automerge map or list. The function
#' automatically dispatches to the appropriate operation based on the object
#' type and key/position type.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (from nested object), or \code{AM_ROOT}
#'   for the document root
#' @param key For maps: character string key. For lists: numeric position
#'   (1-based) or \code{"end"} to append
#' @param value The value to store. Supported types:
#'   \itemize{
#'     \item \code{NULL} - stores null
#'     \item Logical - stores boolean (must be scalar)
#'     \item Integer - stores integer (must be scalar)
#'     \item Numeric - stores double (must be scalar)
#'     \item Character - stores string (must be scalar)
#'     \item Raw - stores bytes
#'     \item \code{AM_OBJ_TYPE_LIST/MAP/TEXT} - creates nested object
#'   }
#'
#' @return When creating a nested object (value is \code{AM_OBJ_TYPE_*}),
#'   returns an \code{am_object} representing the new object. Otherwise,
#'   returns the document \code{doc} (invisibly, for chaining).
#'
#' @export
#' @examples
#' doc <- am_create()
#'
#' # Put values in root map (returns doc invisibly)
#' am_put(doc, AM_ROOT, "name", "Alice")
#' am_put(doc, AM_ROOT, "age", 30L)
#' am_put(doc, AM_ROOT, "active", TRUE)
#'
#' # Create nested list (returns am_object)
#' items <- am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
am_put <- function(doc, obj, key, value) {
  result <- .Call(C_am_put, doc, obj, key, value)
  if (inherits(result, "am_object")) {
    result  # Return am_object visibly
  } else {
    invisible(result)  # Return doc invisibly
  }
}

#' Get a value from an Automerge map or list
#'
#' Retrieves a value from an Automerge map or list. Returns \code{NULL}
#' if the key or position doesn't exist.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (from nested object), or \code{AM_ROOT}
#'   for the document root
#' @param key For maps: character string key. For lists: numeric position
#'   (1-based)
#'
#' @return The value at the specified key/position, or \code{NULL} if not found.
#'   Nested objects are returned as \code{am_object} instances.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "name", "Alice")
#'
#' name <- am_get(doc, AM_ROOT, "name")
#' print(name)  # "Alice"
am_get <- function(doc, obj, key) {
  .Call(C_am_get, doc, obj, key)
}

#' Delete a key from a map or position from a list
#'
#' Removes a key-value pair from a map or an element from a list.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (from nested object), or \code{AM_ROOT}
#'   for the document root
#' @param key For maps: character string key to delete. For lists: numeric
#'   position (1-based) to delete
#'
#' @return The document \code{doc} (invisibly, for chaining)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "temp", "value")
#' am_delete(doc, AM_ROOT, "temp")
am_delete <- function(doc, obj, key) {
  invisible(.Call(C_am_delete, doc, obj, key))
}

#' Get all keys from an Automerge map
#'
#' Returns a character vector of all keys in a map.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (must be a map), or \code{AM_ROOT}
#'   for the document root
#'
#' @return Character vector of keys (empty if map is empty)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "a", 1)
#' am_put(doc, AM_ROOT, "b", 2)
#'
#' keys <- am_keys(doc, AM_ROOT)
#' print(keys)  # c("a", "b")
am_keys <- function(doc, obj) {
  .Call(C_am_keys, doc, obj)
}

#' Get the length of an Automerge map or list
#'
#' Returns the number of key-value pairs in a map or elements in a list.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID, or \code{AM_ROOT} for the document root
#'
#' @return Integer length/size
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "a", 1)
#' am_put(doc, AM_ROOT, "b", 2)
#'
#' len <- am_length(doc, AM_ROOT)
#' print(len)  # 2
am_length <- function(doc, obj) {
  .Call(C_am_length, doc, obj)
}

#' Insert a value into an Automerge list
#'
#' This is an alias for \code{am_put()} with insert semantics for lists.
#' For lists, \code{am_put()} with a numeric position replaces the element
#' at that position, while \code{am_insert()} shifts elements to make room.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (must be a list)
#' @param pos Numeric position (1-based) where to insert, or \code{"end"}
#'   to append
#' @param value The value to insert
#'
#' @return The document \code{doc} (invisibly, for chaining)
#'
#' @export
#' @examples
#' doc <- am_create()
#' # Create a list
#' am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
#' items <- am_get(doc, AM_ROOT, "items")
#'
#' # Insert items
#' # am_insert(doc, items$obj_id, "end", "first")
#' # am_insert(doc, items$obj_id, "end", "second")
am_insert <- function(doc, obj, pos, value) {
  invisible(.Call(C_am_insert, doc, obj, pos, value))
}
