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
    result # Return am_object visibly
  } else {
    invisible(result) # Return doc invisibly
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

# Type Constructors -----------------------------------------------------------

#' Create an Automerge counter
#'
#' Creates a counter value for use with Automerge. Counters are CRDT types
#' that support conflict-free increment and decrement operations.
#'
#' @param value Initial counter value (default 0)
#' @return An \code{am_counter} object
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "score", am_counter(0))
am_counter <- function(value = 0L) {
  structure(as.integer(value), class = "am_counter")
}

#' Create an Automerge list
#'
#' Creates an R list with explicit Automerge list type. Use this when you
#' need to create an empty list or force list type interpretation.
#'
#' @param ... Elements to include in the list
#' @return A list with class \code{am_list_type}
#' @export
#' @examples
#' # Empty list (avoids ambiguity)
#' am_list()
#'
#' # Populated list
#' am_list("a", "b", "c")
am_list <- function(...) {
  structure(list(...), class = c("am_list_type", "list"))
}

#' Create an Automerge map
#'
#' Creates an R list with explicit Automerge map type. Use this when you
#' need to create an empty map or force map type interpretation.
#'
#' @param ... Named elements to include in the map
#' @return A named list with class \code{am_map_type}
#' @export
#' @examples
#' # Empty map (avoids ambiguity)
#' am_map()
#'
#' # Populated map
#' am_map(key1 = "value1", key2 = "value2")
am_map <- function(...) {
  structure(list(...), class = c("am_map_type", "list"))
}

#' Create an Automerge text object
#'
#' Creates a text object for collaborative character-level editing.
#' Unlike regular strings (which use last-write-wins semantics),
#' text objects support character-level CRDT merging of concurrent edits,
#' cursor stability, and marks/formatting.
#'
#' Use text objects for collaborative document editing. Use regular strings
#' for metadata, labels, and IDs (99\% of cases).
#'
#' @param initial Initial text content (default "")
#' @return A character vector with class \code{am_text_type}
#' @export
#' @examples
#' # Empty text object
#' am_text()
#'
#' # Text with initial content
#' am_text("Hello, World!")
am_text <- function(initial = "") {
  if (!is.character(initial) || length(initial) != 1) {
    stop("initial must be a single character string")
  }
  structure(initial, class = c("am_text_type", "character"))
}

# Text Operations -------------------------------------------------------------

#' Splice text in a text object
#'
#' Insert or delete characters in a text object. This is the primary way to
#' edit text CRDT objects.
#'
#' @param doc An Automerge document
#' @param text_obj An Automerge text object ID
#' @param pos Position to start splice (0-based)
#' @param del_count Number of characters to delete
#' @param text Text to insert
#' @return The document \code{doc} (invisibly, for chaining)
#' @export
#' @examples
#' doc <- am_create()
#' text_obj <- am_put(doc, AM_ROOT, "doc", am_text("Hello"))
#'
#' # Insert " World" at position 5
#' am_text_splice(doc, text_obj$obj_id, 5, 0, " World")
#'
#' # Get the full text
#' am_text_get(doc, text_obj$obj_id)  # "Hello World"
am_text_splice <- function(doc, text_obj, pos, del_count, text) {
  invisible(.Call(
    C_am_text_splice,
    doc,
    text_obj,
    as.integer(pos),
    as.integer(del_count),
    as.character(text)
  ))
}

#' Get text from a text object
#'
#' Retrieve the full text content from a text object as a string.
#'
#' @param doc An Automerge document
#' @param text_obj An Automerge text object ID
#' @return Character string with the full text
#' @export
#' @examples
#' doc <- am_create()
#' text_obj <- am_put(doc, AM_ROOT, "doc", am_text("Hello"))
#'
#' text <- am_text_get(doc, text_obj$obj_id)
#' print(text)  # "Hello"
am_text_get <- function(doc, text_obj) {
  .Call(C_am_text_get, doc, text_obj)
}

#' Get all values from a map or list
#'
#' Returns all values from an Automerge map or list as an R list.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID, or \code{AM_ROOT} for the document root
#' @return R list of values
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "a", 1)
#' am_put(doc, AM_ROOT, "b", 2)
#' am_put(doc, AM_ROOT, "c", 3)
#'
#' values <- am_values(doc, AM_ROOT)
#' print(values)  # list(1, 2, 3)
am_values <- function(doc, obj) {
  .Call(C_am_values, doc, obj)
}
