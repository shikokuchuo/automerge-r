# Synchronization Functions

#' Create a new sync state
#'
#' Creates a new synchronization state for managing communication with a peer.
#' The sync state tracks what changes have been sent and received, enabling
#' efficient incremental synchronization.
#'
#' **IMPORTANT**: Sync state is document-independent. The same sync state
#' is used across multiple sync message exchanges with a specific peer.
#' The document is passed separately to `am_sync_encode()` and `am_sync_decode()`.
#'
#' @return An external pointer to the sync state with class `"am_syncstate"`.
#'
#' @export
#' @examples
#' # Create two documents
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Create sync states for each peer
#' sync1 <- am_sync_state_new()
#' sync2 <- am_sync_state_new()
#'
#' # Use with am_sync_encode() and am_sync_decode()
am_sync_state_new <- function() {
  .Call(C_am_sync_state_new)
}

#' Generate a sync message
#'
#' Generates a synchronization message to send to a peer. This message contains
#' the changes that the peer needs to bring their document up to date with yours.
#'
#' If the function returns `NULL`, it means there are no more messages to send
#' (synchronization is complete from this side).
#'
#' @param doc An Automerge document
#' @param sync_state A sync state object (created with `am_sync_state_new()`)
#'
#' @return A raw vector containing the encoded sync message, or `NULL` if no
#'   message needs to be sent.
#'
#' @export
#' @examples
#' doc <- am_create()
#' sync_state <- am_sync_state_new()
#'
#' # Generate first sync message
#' msg <- am_sync_encode(doc, sync_state)
#' if (!is.null(msg)) {
#'   # Send msg to peer...
#' }
am_sync_encode <- function(doc, sync_state) {
  .Call(C_am_sync_encode, doc, sync_state)
}

#' Receive and apply a sync message
#'
#' Receives a synchronization message from a peer and applies the changes
#' to the local document. This updates both the document and the sync state
#' to reflect the received changes.
#'
#' @param doc An Automerge document
#' @param sync_state A sync state object (created with `am_sync_state_new()`)
#' @param message A raw vector containing an encoded sync message
#'
#' @return The document `doc` (invisibly, for chaining)
#'
#' @export
#' @examples
#' doc <- am_create()
#' sync_state <- am_sync_state_new()
#'
#' # Receive message from peer
#' # message <- ... (received from network)
#' # am_sync_decode(doc, sync_state, message)
am_sync_decode <- function(doc, sync_state, message) {
  invisible(.Call(C_am_sync_decode, doc, sync_state, message))
}

#' Bidirectional synchronization
#'
#' Automatically synchronizes two documents by exchanging messages until
#' they converge to the same state. This is a high-level convenience function
#' that handles the entire sync protocol automatically.
#'
#' The function exchanges sync messages back and forth between the two documents
#' until both sides report no more messages to send (`am_sync_encode()` returns `NULL`).
#' The Automerge sync protocol is mathematically guaranteed to converge.
#'
#' @param doc1 First Automerge document
#' @param doc2 Second Automerge document
#'
#' @return An integer indicating the number of sync rounds completed (invisibly).
#'   Both documents are modified in place to include each other's changes.
#'
#' @export
#' @examples
#' # Create two documents with different changes
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Make changes in each document
#' am_put(doc1, AM_ROOT, "x", 1)
#' am_put(doc2, AM_ROOT, "y", 2)
#'
#' # Synchronize them (documents modified in place)
#' rounds <- am_sync(doc1, doc2)
#' cat("Synced in", rounds, "rounds\n")
#'
#' # Now both documents have both x and y
am_sync <- function(doc1, doc2) {
  if (!inherits(doc1, "am_doc")) {
    stop("doc1 must be an Automerge document")
  }
  if (!inherits(doc2, "am_doc")) {
    stop("doc2 must be an Automerge document")
  }

  sync1 <- am_sync_state_new()
  sync2 <- am_sync_state_new()

  round <- 0
  repeat {
    round <- round + 1

    msg1 <- am_sync_encode(doc1, sync1)
    msg2 <- am_sync_encode(doc2, sync2)

    if (is.null(msg1) && is.null(msg2)) {
      break
    }

    if (!is.null(msg1)) {
      am_sync_decode(doc2, sync2, msg1)
    }
    if (!is.null(msg2)) {
      am_sync_decode(doc1, sync1, msg2)
    }
  }

  invisible(round)
}

# Change Tracking and History Functions --------------------------------------

#' Get the current heads of a document
#'
#' Returns the current "heads" of the document - the hashes of the most recent
#' changes. These identify the current state of the document and can be used
#' for history operations.
#'
#' @param doc An Automerge document
#'
#' @return A list of raw vectors, each containing a change hash. Usually there
#'   is only one head, but after concurrent edits there may be multiple heads
#'   until they are merged by a subsequent commit.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_commit(doc)
#'
#' heads <- am_get_heads(doc)
#' cat("Document has", length(heads), "head(s)\n")
am_get_heads <- function(doc) {
  .Call(C_am_get_heads, doc)
}

#' Get changes since specified heads
#'
#' Returns all changes that have been made to the document since the specified
#' heads. If `heads` is `NULL`, returns all changes in the document's history.
#'
#' Changes are returned as serialized raw vectors that can be transmitted over
#' the network and applied to other documents using `am_apply_changes()`.
#'
#' @param doc An Automerge document
#' @param heads A list of raw vectors (change hashes) returned by `am_get_heads()`,
#'   or `NULL` to get all changes.
#'
#' @return A list of raw vectors, each containing a serialized change.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_commit(doc)
#'
#' # Get all changes
#' all_changes <- am_get_changes(doc, NULL)
#' cat("Document has", length(all_changes), "change(s)\n")
am_get_changes <- function(doc, heads = NULL) {
  .Call(C_am_get_changes, doc, heads)
}

#' Apply changes to a document
#'
#' Applies a list of changes (obtained from `am_get_changes()`) to a document.
#' This is useful for manually syncing changes or for applying changes received
#' over a custom network protocol.
#'
#' @param doc An Automerge document
#' @param changes A list of raw vectors (serialized changes) from `am_get_changes()`
#'
#' @return The document `doc` (invisibly, for chaining)
#'
#' @export
#' @examples
#' # Create two documents
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Make changes in doc1
#' am_put(doc1, AM_ROOT, "x", 1)
#' am_commit(doc1)
#'
#' # Get changes and apply to doc2
#' changes <- am_get_changes(doc1, NULL)
#' am_apply_changes(doc2, changes)
#'
#' # Now doc2 has the same data as doc1
am_apply_changes <- function(doc, changes) {
  invisible(.Call(C_am_apply_changes, doc, changes))
}

#' Get document history
#'
#' Returns the full change history of the document as a list of change metadata.
#' This provides a simpler interface than `am_get_changes()` for examining
#' document history without needing to work with serialized changes directly.
#'
#' **Note**: A future implementation will add detailed change introspection
#' functions to extract metadata like commit messages, timestamps,
#' actor IDs, etc.
#'
#' @param doc An Automerge document
#'
#' @return A list of raw vectors (serialized changes), one for each change
#'   in the document's history, in chronological order.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_commit(doc, "Initial")
#' am_put(doc, AM_ROOT, "x", 2)
#' am_commit(doc, "Update")
#'
#' history <- am_get_history(doc)
#' cat("Document history contains", length(history), "change(s)\n")
am_get_history <- function(doc) {
  am_get_changes(doc, NULL)
}
