# sync state operations with invalid pointers

    Code
      am_sync_encode(doc1, "not a sync state")
    Condition
      Error in `am_sync_encode()`:
      ! Expected external pointer for sync state

---

    Code
      am_sync_encode(doc1, 123)
    Condition
      Error in `am_sync_encode()`:
      ! Expected external pointer for sync state

---

    Code
      am_sync_encode(doc1, list())
    Condition
      Error in `am_sync_encode()`:
      ! Expected external pointer for sync state

# sync decode with zero-length message

    Code
      am_sync_decode(doc, sync_state, raw(0))
    Condition
      Error in `am_sync_decode()`:
      ! Automerge error at sync.c:LINE: not enough input

# sync decode with malformed message

    Code
      am_sync_decode(doc, sync_state, bad_msg)
    Condition
      Error in `am_sync_decode()`:
      ! Automerge error at sync.c:LINE: expected [66, 67] but found 158

---

    Code
      am_sync_decode(doc, sync_state, as.raw(c(255, 255, 255)))
    Condition
      Error in `am_sync_decode()`:
      ! Automerge error at sync.c:LINE: expected [66, 67] but found 255

# am_fork with invalid heads list elements

    Code
      am_fork(doc, heads = list(123))
    Condition
      Error in `am_fork()`:
      ! All heads must be raw vectors (change hashes)

---

    Code
      am_fork(doc, heads = list("not raw"))
    Condition
      Error in `am_fork()`:
      ! All heads must be raw vectors (change hashes)

---

    Code
      am_fork(doc, heads = list(raw(32), "invalid", raw(32)))
    Condition
      Error in `am_fork()`:
      ! All heads must be raw vectors (change hashes)

# am_apply_changes with empty and invalid lists

    Code
      am_apply_changes(doc, list(123))
    Condition
      Error in `am_apply_changes()`:
      ! All changes must be raw vectors (got type 14 at index 0)

---

    Code
      am_apply_changes(doc, list("not raw"))
    Condition
      Error in `am_apply_changes()`:
      ! All changes must be raw vectors (got type 16 at index 0)

# am_apply_changes with malformed change data

    Code
      am_apply_changes(doc, list(bad_change))
    Condition
      Error in `am_apply_changes()`:
      ! Failed to apply change at index 0: unable to parse chunk: failed to parse header: Invalid magic bytes

# am_get_change_by_hash with wrong size hash

    Code
      am_get_change_by_hash(doc, raw(0))
    Condition
      Error in `am_get_change_by_hash()`:
      ! Change hash must be exactly 32 bytes

---

    Code
      am_get_change_by_hash(doc, raw(31))
    Condition
      Error in `am_get_change_by_hash()`:
      ! Change hash must be exactly 32 bytes

# cursor operations on non-text objects

    Code
      am_cursor(map_obj, 0)
    Condition
      Error in `am_cursor()`:
      ! Automerge error at cursors.c:LINE: invalid op for object of type `map`

# marks on non-text objects

    Code
      am_mark_create(list_obj, 0, 2, "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! Automerge error at cursors.c:LINE: invalid op for object of type `list`

# am_put with very large list position

    Code
      am_put(doc, items, 10000, "last")
    Condition
      Error in `am_put()`:
      ! Automerge error at objects.c:LINE: Invalid pos 9999

# am_delete with out-of-bounds list position

    Code
      am_delete(doc, items, 10)
    Condition
      Error in `am_delete()`:
      ! Automerge error at objects.c:LINE: Invalid pos 9

# cursor at boundary and beyond

    Code
      am_cursor(text_obj, 4)
    Condition
      Error in `am_cursor()`:
      ! Automerge error at cursors.c:LINE: index 4 is out of bounds

---

    Code
      am_cursor(text_obj, 1000)
    Condition
      Error in `am_cursor()`:
      ! Automerge error at cursors.c:LINE: index 1000 is out of bounds

# marks at boundary and beyond

    Code
      am_mark_create(text_obj, 0, 1000, "invalid", "value")
    Condition
      Error in `am_mark_create()`:
      ! Automerge error at cursors.c:LINE: index 1000 is out of bounds

# counter increment on non-existent keys

    Code
      am_counter_increment(doc, AM_ROOT, "nonexistent", 1)
    Condition
      Error in `am_counter_increment()`:
      ! Automerge error at objects.c:LINE: increment operations must be against a counter value

# counter in empty list

    Code
      am_counter_increment(doc, counters, 1, 1)
    Condition
      Error in `am_counter_increment()`:
      ! Automerge error at objects.c:LINE: index 0 is out of bounds

# create with various actor ID types

    Code
      am_create(actor_id = "not-valid-hex")
    Condition
      Error in `am_create()`:
      ! Automerge error at document.c:LINE: invalid actor ID `not-valid-hex`

# sync with malformed state pointer

    Code
      am_sync_encode(doc, list())
    Condition
      Error in `am_sync_encode()`:
      ! Expected external pointer for sync state

---

    Code
      am_sync_encode(doc, raw(10))
    Condition
      Error in `am_sync_encode()`:
      ! Expected external pointer for sync state

# malformed change hashes in fork heads

    Code
      am_fork(doc, heads = list(raw(5)))
    Condition
      Error in `am_fork()`:
      ! Invalid change hash at index 0

---

    Code
      am_fork(doc, heads = list(as.raw(1:50)))
    Condition
      Error in `am_fork()`:
      ! Invalid change hash at index 0

# sync with corrupted message state

    Code
      am_sync_decode(doc2, sync_state, bad_msg)
    Condition
      Error in `am_sync_decode()`:
      ! Automerge error at sync.c:LINE: expected [66, 67] but found 0

# operations with invalid change hashes

    Code
      am_get_changes(doc, list(raw(5)))
    Condition
      Error in `am_get_changes()`:
      ! Invalid change hash

---

    Code
      am_get_changes(doc, list(as.raw(1:50)))
    Condition
      Error in `am_get_changes()`:
      ! Invalid change hash

# text operations with empty text objects

    Code
      am_cursor(text_obj, 0)
    Condition
      Error in `am_cursor()`:
      ! Automerge error at cursors.c:LINE: index 0 is out of bounds

