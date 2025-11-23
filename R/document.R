# Document Lifecycle Functions

#' Create a new Automerge document
#'
#' Creates a new Automerge document with an optional custom actor ID.
#' If no actor ID is provided, a random one is generated.
#'
#' @param actor_id Optional actor ID. Can be:
#'   \itemize{
#'     \item `NULL` (default) - Generate random actor ID
#'     \item Character string - Hex-encoded actor ID
#'     \item Raw vector - Binary actor ID bytes
#'   }
#'
#' @return An external pointer to the Automerge document with class
#'   `c("am_doc", "automerge")`.
#'
#' @section Thread Safety:
#' The automerge package is NOT thread-safe. Do not access the same document
#' from multiple R threads concurrently. Each thread should create its own
#' document with `am_create()` and synchronize changes via
#' `am_sync_*()` functions after thread completion.
#'
#' @export
#' @examples
#' # Create document with random actor ID
#' doc <- am_create()
#'
#' # Create with custom hex actor ID
#' doc2 <- am_create("0123456789abcdef0123456789abcdef")
#'
#' # Create with raw bytes actor ID
#' actor_bytes <- as.raw(1:16)
#' doc3 <- am_create(actor_bytes)
am_create <- function(actor_id = NULL) {
  .Call(C_am_create, actor_id)
}

#' Save an Automerge document to binary format
#'
#' Serializes an Automerge document to the standard binary format,
#' which can be saved to disk or transmitted over a network.
#' The binary format is compatible across all Automerge implementations
#' (JavaScript, Rust, etc.).
#'
#' @param doc An Automerge document (created with `am_create()` or `am_load()`)
#'
#' @return A raw vector containing the serialized document
#'
#' @export
#' @examples
#' doc <- am_create()
#' bytes <- am_save(doc)
#'
#' # Save to file
#' \dontrun{
#' writeBin(am_save(doc), "document.automerge")
#' }
am_save <- function(doc) {
  .Call(C_am_save, doc)
}

#' Load an Automerge document from binary format
#'
#' Deserializes an Automerge document from the standard binary format.
#' The binary format is compatible across all Automerge implementations
#' (JavaScript, Rust, etc.).
#'
#' @param data A raw vector containing a serialized Automerge document
#'
#' @return An external pointer to the Automerge document with class
#'   `c("am_doc", "automerge")`.
#'
#' @export
#' @examples
#' # Create, save, and reload
#' doc1 <- am_create()
#' bytes <- am_save(doc1)
#' doc2 <- am_load(bytes)
#'
#' # Load from file
#' \dontrun{
#' doc <- am_load(readBin("document.automerge", "raw", 1e7))
#' }
am_load <- function(data) {
  .Call(C_am_load, data)
}

#' Fork an Automerge document
#'
#' Creates a fork of an Automerge document at the current heads or
#' at a specific point in history. The forked document shares history
#' with the original up to the fork point but can diverge afterwards.
#'
#' @param doc An Automerge document
#' @param heads Optional list of change hashes to fork at.
#'   If `NULL` (default), forks at current heads.
#'   Forking at specific heads is not yet implemented (Phase 5).
#'
#' @return A new Automerge document (fork of the original)
#'
#' @export
#' @examples
#' doc1 <- am_create()
#' doc2 <- am_fork(doc1)
#'
#' # Now doc1 and doc2 can diverge independently
am_fork <- function(doc, heads = NULL) {
  .Call(C_am_fork, doc, heads)
}

#' Merge changes from another document
#'
#' Merges all changes from another Automerge document into this one.
#' This is a one-way merge: changes flow from `other` into `doc`,
#' but `other` is not modified. For bidirectional synchronization,
#' use `am_sync_bidirectional()` (Phase 5).
#'
#' @param doc Target document (will receive changes)
#' @param other Source document (provides changes)
#'
#' @return The target document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Make changes in each document
#' # am_put(doc1, AM_ROOT, "x", 1)
#' # am_put(doc2, AM_ROOT, "y", 2)
#'
#' # Merge doc2's changes into doc1
#' am_merge(doc1, doc2)
#' # Now doc1 has both x and y
am_merge <- function(doc, other) {
  invisible(.Call(C_am_merge, doc, other))
}

#' Get the actor ID of a document
#'
#' Returns the actor ID of an Automerge document as a raw vector.
#' The actor ID uniquely identifies the editing session that created
#' changes in the document.
#'
#' For a hex string representation, use [am_get_actor_hex()].
#'
#' @param doc An Automerge document
#'
#' @return A raw vector containing the actor ID bytes
#'
#' @export
#' @examples
#' doc <- am_create()
#' actor <- am_get_actor(doc)
#'
#' # Use am_get_actor_hex() for display
#' actor_hex <- am_get_actor_hex(doc)
#' cat("Actor ID:", actor_hex, "\n")
am_get_actor <- function(doc) {
  .Call(C_am_get_actor, doc)
}

#' Get the actor ID as a hex string
#'
#' Returns the actor ID of an Automerge document as a hex-encoded string.
#' This is more efficient than converting the raw bytes returned by
#' [am_get_actor()] using R-level string operations.
#'
#' @param doc An Automerge document
#'
#' @return A character string containing the hex-encoded actor ID
#'
#' @export
#' @examples
#' doc <- am_create()
#' actor_hex <- am_get_actor_hex(doc)
#' cat("Actor ID:", actor_hex, "\n")
am_get_actor_hex <- function(doc) {
  .Call(C_am_get_actor_hex, doc)
}

#' Set the actor ID of a document
#'
#' Sets the actor ID for an Automerge document. This should typically
#' be done before making any changes. Changing the actor ID mid-session
#' is not recommended as it can complicate change attribution.
#'
#' @param doc An Automerge document
#' @param actor_id The new actor ID. Can be:
#'   \itemize{
#'     \item `NULL` - Generate new random actor ID
#'     \item Character string - Hex-encoded actor ID
#'     \item Raw vector - Binary actor ID bytes
#'   }
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#'
#' # Set custom actor ID from hex string
#' am_set_actor(doc, "0123456789abcdef0123456789abcdef")
#'
#' # Generate new random actor ID
#' am_set_actor(doc, NULL)
am_set_actor <- function(doc, actor_id) {
  invisible(.Call(C_am_set_actor, doc, actor_id))
}

#' Commit pending changes
#'
#' Commits all pending operations in the current transaction,
#' creating a new change in the document's history. Commits can
#' include an optional message (like a git commit message) and
#' timestamp.
#'
#' @param doc An Automerge document
#' @param message Optional commit message (character string)
#' @param time Optional timestamp (POSIXct). If `NULL`, uses current time.
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' # am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add initial data")
#'
#' # Commit with specific timestamp
#' am_commit(doc, "Update", Sys.time())
am_commit <- function(doc, message = NULL, time = NULL) {
  invisible(.Call(C_am_commit, doc, message, time))
}

#' Roll back pending operations
#'
#' Cancels all pending operations in the current transaction without
#' committing them. This allows you to discard changes since the last
#' commit.
#'
#' @param doc An Automerge document
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' # am_put(doc, AM_ROOT, "key", "value")
#' # Changed my mind, discard the put
#' am_rollback(doc)
am_rollback <- function(doc) {
  invisible(.Call(C_am_rollback, doc))
}
