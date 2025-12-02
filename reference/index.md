# Package index

## Document Lifecycle

Create, save, load, and manage Automerge documents

- [`am_create()`](http://shikokuchuo.net/automerge-r/reference/am_create.md)
  : Create a new Automerge document
- [`am_load()`](http://shikokuchuo.net/automerge-r/reference/am_load.md)
  : Load an Automerge document from binary format
- [`am_save()`](http://shikokuchuo.net/automerge-r/reference/am_save.md)
  : Save an Automerge document to binary format
- [`am_fork()`](http://shikokuchuo.net/automerge-r/reference/am_fork.md)
  : Fork an Automerge document
- [`am_merge()`](http://shikokuchuo.net/automerge-r/reference/am_merge.md)
  : Merge changes from another document
- [`am_commit()`](http://shikokuchuo.net/automerge-r/reference/am_commit.md)
  : Commit pending changes
- [`am_rollback()`](http://shikokuchuo.net/automerge-r/reference/am_rollback.md)
  : Roll back pending operations

## Actor Management

Get and set document actor IDs

- [`am_get_actor()`](http://shikokuchuo.net/automerge-r/reference/am_get_actor.md)
  : Get the actor ID of a document
- [`am_get_actor_hex()`](http://shikokuchuo.net/automerge-r/reference/am_get_actor_hex.md)
  : Get the actor ID as a hex string
- [`am_set_actor()`](http://shikokuchuo.net/automerge-r/reference/am_set_actor.md)
  : Set the actor ID of a document

## Object Operations

Create and manipulate maps, lists, and nested objects

- [`am_put()`](http://shikokuchuo.net/automerge-r/reference/am_put.md) :
  Put a value into an Automerge map or list
- [`am_get()`](http://shikokuchuo.net/automerge-r/reference/am_get.md) :
  Get a value from an Automerge map or list
- [`am_delete()`](http://shikokuchuo.net/automerge-r/reference/am_delete.md)
  : Delete a key from a map or element from a list
- [`am_insert()`](http://shikokuchuo.net/automerge-r/reference/am_insert.md)
  : Insert a value into an Automerge list
- [`am_keys()`](http://shikokuchuo.net/automerge-r/reference/am_keys.md)
  : Get all keys from an Automerge map
- [`am_values()`](http://shikokuchuo.net/automerge-r/reference/am_values.md)
  : Get all values from a map or list
- [`am_length()`](http://shikokuchuo.net/automerge-r/reference/am_length.md)
  : Get the length of an Automerge map or list

## Text Operations

Work with collaborative text objects

- [`am_text()`](http://shikokuchuo.net/automerge-r/reference/am_text.md)
  : Create an Automerge text object
- [`am_text_get()`](http://shikokuchuo.net/automerge-r/reference/am_text_get.md)
  : Get text from a text object
- [`am_text_splice()`](http://shikokuchuo.net/automerge-r/reference/am_text_splice.md)
  : Splice text in a text object
- [`as.character(`*`<am_text>`*`)`](http://shikokuchuo.net/automerge-r/reference/as.character.am_text.md)
  : Convert text object to character string

## Counters

Create and increment CRDT counters

- [`am_counter()`](http://shikokuchuo.net/automerge-r/reference/am_counter.md)
  : Create an Automerge counter
- [`am_counter_increment()`](http://shikokuchuo.net/automerge-r/reference/am_counter_increment.md)
  : Increment a counter value

## Cursors and Marks

Stable positions and text formatting

- [`am_cursor()`](http://shikokuchuo.net/automerge-r/reference/am_cursor.md)
  : Create a cursor at a position in a text object
- [`am_cursor_position()`](http://shikokuchuo.net/automerge-r/reference/am_cursor_position.md)
  : Get the current position of a cursor
- [`am_mark_create()`](http://shikokuchuo.net/automerge-r/reference/am_mark_create.md)
  : Create a mark on a text range
- [`am_marks()`](http://shikokuchuo.net/automerge-r/reference/am_marks.md)
  : Get all marks in a text object
- [`am_marks_at()`](http://shikokuchuo.net/automerge-r/reference/am_marks_at.md)
  : Get marks at a specific position

## Synchronization

Sync documents across peers

- [`am_sync()`](http://shikokuchuo.net/automerge-r/reference/am_sync.md)
  : Bidirectional synchronization
- [`am_sync_state_new()`](http://shikokuchuo.net/automerge-r/reference/am_sync_state_new.md)
  : Create a new sync state
- [`am_sync_encode()`](http://shikokuchuo.net/automerge-r/reference/am_sync_encode.md)
  : Generate a sync message
- [`am_sync_decode()`](http://shikokuchuo.net/automerge-r/reference/am_sync_decode.md)
  : Receive and apply a sync message

## History and Changes

Track document history and changes

- [`am_get_heads()`](http://shikokuchuo.net/automerge-r/reference/am_get_heads.md)
  : Get the current heads of a document
- [`am_get_changes()`](http://shikokuchuo.net/automerge-r/reference/am_get_changes.md)
  : Get changes since specified heads
- [`am_get_history()`](http://shikokuchuo.net/automerge-r/reference/am_get_history.md)
  : Get document history
- [`am_apply_changes()`](http://shikokuchuo.net/automerge-r/reference/am_apply_changes.md)
  : Apply changes to a document
- [`am_get_last_local_change()`](http://shikokuchuo.net/automerge-r/reference/am_get_last_local_change.md)
  : Get the last change made by the local actor
- [`am_get_change_by_hash()`](http://shikokuchuo.net/automerge-r/reference/am_get_change_by_hash.md)
  : Get a specific change by its hash
- [`am_get_changes_added()`](http://shikokuchuo.net/automerge-r/reference/am_get_changes_added.md)
  : Get changes in one document that are not in another

## Type Constructors

Explicit type constructors for objects

- [`am_list()`](http://shikokuchuo.net/automerge-r/reference/am_list.md)
  : Create an Automerge list
- [`am_map()`](http://shikokuchuo.net/automerge-r/reference/am_map.md) :
  Create an Automerge map

## Path-Based Access

Navigate deep nested structures

- [`am_get_path()`](http://shikokuchuo.net/automerge-r/reference/am_get_path.md)
  : Navigate deep structures with path
- [`am_put_path()`](http://shikokuchuo.net/automerge-r/reference/am_put_path.md)
  : Set value at path
- [`am_delete_path()`](http://shikokuchuo.net/automerge-r/reference/am_delete_path.md)
  : Delete value at path

## Conversion Helpers

Convert between R lists and Automerge documents

- [`as_automerge()`](http://shikokuchuo.net/automerge-r/reference/as_automerge.md)
  : Convert R list to Automerge document
- [`from_automerge()`](http://shikokuchuo.net/automerge-r/reference/from_automerge.md)
  : Convert Automerge document to R list

## Constants

Package constants and enumerations

- [`AM_ROOT`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_LIST`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_MAP`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_TEXT`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_NONE`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_BEFORE`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_AFTER`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_BOTH`](http://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  : Automerge Constants

## S3 Methods

R methods for Automerge objects

- [`` `[[`( ``*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/extract-am_doc.md)
  [`` `$`( ``*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/extract-am_doc.md)
  : Extract from Automerge document root
- [`` `[[<-`( ``*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/replace-am_doc.md)
  [`` `$<-`( ``*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/replace-am_doc.md)
  : Replace in Automerge document root
- [`` `[[`( ``*`<am_object>`*`)`](http://shikokuchuo.net/automerge-r/reference/extract-am_object.md)
  [`` `$`( ``*`<am_object>`*`)`](http://shikokuchuo.net/automerge-r/reference/extract-am_object.md)
  : Extract from Automerge object
- [`` `[[<-`( ``*`<am_object>`*`)`](http://shikokuchuo.net/automerge-r/reference/replace-am_object.md)
  [`` `$<-`( ``*`<am_object>`*`)`](http://shikokuchuo.net/automerge-r/reference/replace-am_object.md)
  : Replace in Automerge object
- [`length(`*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/length.am_doc.md)
  : Get length of document root
- [`length(`*`<am_object>`*`)`](http://shikokuchuo.net/automerge-r/reference/length.am_object.md)
  : Get length of Automerge object
- [`names(`*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/names.am_doc.md)
  : Get names from document root
- [`names(`*`<am_map>`*`)`](http://shikokuchuo.net/automerge-r/reference/names.am_map.md)
  : Get names from Automerge map object
- [`print(`*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_doc.md)
  : Print Automerge document
- [`as.list(`*`<am_doc>`*`)`](http://shikokuchuo.net/automerge-r/reference/as.list.am_doc.md)
  : Convert document root to R list
- [`print(`*`<am_object>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_object.md)
  : Print Automerge object (fallback for unknown types)
- [`print(`*`<am_list>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_list.md)
  : Print Automerge list object
- [`print(`*`<am_map>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_map.md)
  : Print Automerge map object
- [`print(`*`<am_text>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_text.md)
  : Print Automerge text object
- [`print(`*`<am_counter>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_counter.md)
  : Print Automerge counter
- [`print(`*`<am_cursor>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_cursor.md)
  : Print Automerge cursor
- [`print(`*`<am_syncstate>`*`)`](http://shikokuchuo.net/automerge-r/reference/print.am_syncstate.md)
  : Print Automerge sync state
