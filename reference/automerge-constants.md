# Automerge Constants

Constants used throughout the automerge package for object types, root
references, and mark expansion modes.

## Usage

``` r
AM_ROOT

AM_OBJ_TYPE_LIST

AM_OBJ_TYPE_MAP

AM_OBJ_TYPE_TEXT

AM_MARK_EXPAND_NONE

AM_MARK_EXPAND_BEFORE

AM_MARK_EXPAND_AFTER

AM_MARK_EXPAND_BOTH
```

## Format

An object of class `NULL` of length 0.

An object of class `am_obj_type` of length 1.

An object of class `am_obj_type` of length 1.

An object of class `am_obj_type` of length 1.

An object of class `character` of length 1.

An object of class `character` of length 1.

An object of class `character` of length 1.

An object of class `character` of length 1.

## Root Object

- AM_ROOT:

  Reference to the root object of an Automerge document. Use this as the
  `obj` parameter when operating on the top-level map. Value is `NULL`
  which maps to the C API's AM_ROOT.

## Object Types

String constants for creating Automerge objects:

- AM_OBJ_TYPE_LIST:

  Create a list (array) object. Lists are ordered sequences accessed by
  numeric index (1-based in R).

- AM_OBJ_TYPE_MAP:

  Create a map (object) object. Maps are unordered key-value collections
  accessed by string keys.

- AM_OBJ_TYPE_TEXT:

  Create a text object for collaborative editing. Text objects support
  character-level CRDT operations, cursor stability, and formatting
  marks. Use text objects for collaborative document editing rather than
  regular strings (which use last-write-wins semantics).

## Mark Expansion Modes

Constants for controlling how text marks expand when text is inserted at
their boundaries (used with `am_mark_create`):

- AM_MARK_EXPAND_NONE:

  Mark does not expand when text is inserted at either boundary.

- AM_MARK_EXPAND_BEFORE:

  Mark expands to include text inserted immediately before its start
  position.

- AM_MARK_EXPAND_AFTER:

  Mark expands to include text inserted immediately after its end
  position.

- AM_MARK_EXPAND_BOTH:

  Mark expands to include text inserted at either boundary (before start
  or after end).
