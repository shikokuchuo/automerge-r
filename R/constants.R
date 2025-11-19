# Automerge Constants and Enumerations

#' Automerge Constants
#'
#' Constants used throughout the automerge package for object types,
#' root references, and mark expansion modes.
#'
#' @name automerge-constants
#' @aliases AM_ROOT AM_OBJ_TYPE_LIST AM_OBJ_TYPE_MAP AM_OBJ_TYPE_TEXT
#'   AM_MARK_EXPAND_NONE AM_MARK_EXPAND_BEFORE AM_MARK_EXPAND_AFTER
#'   AM_MARK_EXPAND_BOTH
#'
#' @section Root Object:
#' \describe{
#'   \item{AM_ROOT}{Reference to the root object of an Automerge document.
#'     Use this as the \code{obj} parameter when operating on the top-level
#'     map. Value is \code{NULL} which maps to the C API's AM_ROOT.}
#' }
#'
#' @section Object Types:
#' String constants for creating Automerge objects:
#' \describe{
#'   \item{AM_OBJ_TYPE_LIST}{Create a list (array) object. Lists are ordered
#'     sequences accessed by numeric index (1-based in R).}
#'   \item{AM_OBJ_TYPE_MAP}{Create a map (object) object. Maps are unordered
#'     key-value collections accessed by string keys.}
#'   \item{AM_OBJ_TYPE_TEXT}{Create a text object for collaborative editing.
#'     Text objects support character-level CRDT operations, cursor stability,
#'     and formatting marks. Use text objects for collaborative document editing
#'     rather than regular strings (which use last-write-wins semantics).}
#' }
#'
#' @section Mark Expansion Modes:
#' Constants for controlling how text marks expand when text is inserted
#' at their boundaries (used with \code{am_mark_create}):
#' \describe{
#'   \item{AM_MARK_EXPAND_NONE}{Mark does not expand when text is inserted
#'     at either boundary.}
#'   \item{AM_MARK_EXPAND_BEFORE}{Mark expands to include text inserted
#'     immediately before its start position.}
#'   \item{AM_MARK_EXPAND_AFTER}{Mark expands to include text inserted
#'     immediately after its end position.}
#'   \item{AM_MARK_EXPAND_BOTH}{Mark expands to include text inserted at
#'     either boundary (before start or after end).}
#' }
#'
#' @export
AM_ROOT <- NULL

#' @rdname automerge-constants
#' @export
AM_OBJ_TYPE_LIST <- structure("list", class = "am_obj_type")

#' @rdname automerge-constants
#' @export
AM_OBJ_TYPE_MAP <- structure("map", class = "am_obj_type")

#' @rdname automerge-constants
#' @export
AM_OBJ_TYPE_TEXT <- structure("text", class = "am_obj_type")

#' @rdname automerge-constants
#' @export
AM_MARK_EXPAND_NONE <- "none"

#' @rdname automerge-constants
#' @export
AM_MARK_EXPAND_BEFORE <- "before"

#' @rdname automerge-constants
#' @export
AM_MARK_EXPAND_AFTER <- "after"

#' @rdname automerge-constants
#' @export
AM_MARK_EXPAND_BOTH <- "both"

# C code uses these maps to convert R string constants to C enums
# Avoids exposing numeric values to R users
.am_obj_type_map <- c(
  "list" = 1L, # AM_OBJ_TYPE_LIST
  "map" = 2L, # AM_OBJ_TYPE_MAP
  "text" = 3L # AM_OBJ_TYPE_TEXT
)

.am_mark_expand_map <- c(
  "none" = 1L, # AM_MARK_EXPAND_NONE
  "before" = 2L, # AM_MARK_EXPAND_BEFORE
  "after" = 3L, # AM_MARK_EXPAND_AFTER
  "both" = 4L # AM_MARK_EXPAND_BOTH
)
