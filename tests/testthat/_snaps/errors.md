# Automerge errors are caught with error messages

    Code
      am_load(as.raw(c(0, 1, 2)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: not enough data

---

    Code
      am_load(as.raw(sample(0:255, 100, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

# am_load validates input type

    Code
      am_load("not raw")
    Condition
      Error in `am_load()`:
      ! data must be a raw vector

---

    Code
      am_load(123)
    Condition
      Error in `am_load()`:
      ! data must be a raw vector

---

    Code
      am_load(list())
    Condition
      Error in `am_load()`:
      ! data must be a raw vector

---

    Code
      am_load(NULL)
    Condition
      Error in `am_load()`:
      ! data must be a raw vector

# Invalid document pointers are caught

    Code
      am_save("not a document")
    Condition
      Error in `am_save()`:
      ! Expected external pointer for document

---

    Code
      am_fork(123)
    Condition
      Error in `am_fork()`:
      ! Expected external pointer for document

---

    Code
      am_merge("doc1", "doc2")
    Condition
      Error in `am_merge()`:
      ! Expected external pointer for document

# Invalid operations on documents

    Code
      am_set_actor(doc, 123)
    Condition
      Error in `am_set_actor()`:
      ! actor_id must be NULL, a character string (hex), or raw bytes

---

    Code
      am_set_actor(doc, list())
    Condition
      Error in `am_set_actor()`:
      ! actor_id must be NULL, a character string (hex), or raw bytes

---

    Code
      am_merge(doc, "not a doc")
    Condition
      Error in `am_merge()`:
      ! Expected external pointer for document

# Invalid object operations

    Code
      am_get(doc, "not an objid", "key")
    Condition
      Error in `am_get()`:
      ! Expected external pointer for object ID

---

    Code
      am_delete(doc, 123, "key")
    Condition
      Error in `am_delete()`:
      ! Expected external pointer for object ID

# Commit with invalid parameters

    Code
      am_commit(doc, 123)
    Condition
      Error in `am_commit()`:
      ! message must be NULL or a single character string

---

    Code
      am_commit(doc, c("a", "b"))
    Condition
      Error in `am_commit()`:
      ! message must be NULL or a single character string

---

    Code
      am_commit(doc, NULL, "not a time")
    Condition
      Error in `am_commit()`:
      ! time must be NULL or a scalar POSIXct object

---

    Code
      am_commit(doc, NULL, 123)
    Condition
      Error in `am_commit()`:
      ! time must be NULL or a scalar POSIXct object

# Text operations with invalid inputs

    Code
      am_text_splice(map_obj, 0, 0, "text")
    Condition
      Error in `am_text_splice()`:
      ! Automerge error at objects.c:LINE: invalid op for object of type `map`

# Fork and merge error handling

    Code
      am_merge(doc1, NULL)
    Condition
      Error in `am_merge()`:
      ! Expected external pointer for document

# Type constructor validation

    Code
      am_text(123)
    Condition
      Error in `am_text()`:
      ! initial must be a single character string

---

    Code
      am_text(c("a", "b"))
    Condition
      Error in `am_text()`:
      ! initial must be a single character string

---

    Code
      am_text(NULL)
    Condition
      Error in `am_text()`:
      ! initial must be a single character string

# Corrupted document state handling

    Code
      am_load(corrupted)
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: bad checksum

# Error messages include file and line information

    Code
      am_load(as.raw(c(255)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: not enough data

# Multiple error conditions in sequence

    Code
      am_load(as.raw(c(0)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: not enough data

---

    Code
      am_load(as.raw(c(255)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: not enough data

# Resource cleanup after errors

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:LINE: unable to parse chunk: failed to parse header: Invalid magic bytes

# am_sync_decode validates message type

    Code
      am_sync_decode(doc, sync_state, "not raw")
    Condition
      Error in `am_sync_decode()`:
      ! message must be a raw vector

---

    Code
      am_sync_decode(doc, sync_state, 123)
    Condition
      Error in `am_sync_decode()`:
      ! message must be a raw vector

---

    Code
      am_sync_decode(doc, sync_state, list(1, 2, 3))
    Condition
      Error in `am_sync_decode()`:
      ! message must be a raw vector

---

    Code
      am_sync_decode(doc, sync_state, NULL)
    Condition
      Error in `am_sync_decode()`:
      ! message must be a raw vector

# am_sync validates doc1 parameter

    Code
      am_sync("not a doc", doc)
    Condition
      Error in `am_sync()`:
      ! doc1 must be an Automerge document

---

    Code
      am_sync(123, doc)
    Condition
      Error in `am_sync()`:
      ! doc1 must be an Automerge document

---

    Code
      am_sync(NULL, doc)
    Condition
      Error in `am_sync()`:
      ! doc1 must be an Automerge document

# am_sync validates doc2 parameter

    Code
      am_sync(doc, "not a doc")
    Condition
      Error in `am_sync()`:
      ! doc2 must be an Automerge document

---

    Code
      am_sync(doc, 456)
    Condition
      Error in `am_sync()`:
      ! doc2 must be an Automerge document

---

    Code
      am_sync(doc, NULL)
    Condition
      Error in `am_sync()`:
      ! doc2 must be an Automerge document

# am_get_changes validates heads parameter

    Code
      am_get_changes(doc, "not a list")
    Condition
      Error in `am_get_changes()`:
      ! heads must be NULL or a list of raw vectors

---

    Code
      am_get_changes(doc, 123)
    Condition
      Error in `am_get_changes()`:
      ! heads must be NULL or a list of raw vectors

---

    Code
      am_get_changes(doc, raw(5))
    Condition
      Error in `am_get_changes()`:
      ! heads must be NULL or a list of raw vectors

# am_apply_changes validates changes parameter

    Code
      am_apply_changes(doc, "not a list")
    Condition
      Error in `am_apply_changes()`:
      ! changes must be a list of raw vectors

---

    Code
      am_apply_changes(doc, 123)
    Condition
      Error in `am_apply_changes()`:
      ! changes must be a list of raw vectors

---

    Code
      am_apply_changes(doc, raw(5))
    Condition
      Error in `am_apply_changes()`:
      ! changes must be a list of raw vectors

---

    Code
      am_apply_changes(doc, NULL)
    Condition
      Error in `am_apply_changes()`:
      ! changes must be a list of raw vectors

# am_put_path validates with non-existent intermediate and no create

    Code
      am_put_path(doc, c("a", "b", "c"), "value", create_intermediate = FALSE)
    Condition
      Error in `am_put_path()`:
      ! Path component at position 1 does not exist

# am_put_path errors on non-object intermediate path component

    Code
      am_put_path(doc, c("scalar", "nested"), "value")
    Condition
      Error in `am_put_path()`:
      ! Path component at position 1 is not an object

# am_put_path errors when trying to create intermediate list element

    Code
      am_put_path(doc, list("items", 99, "nested"), "value")
    Condition
      Error in `am_put_path()`:
      ! Cannot create intermediate list element at index 99

# am_put with invalid key types for maps

    Code
      am_put(doc, AM_ROOT, 123, "value")
    Condition
      Error in `am_put()`:
      ! Map key must be a single character string

---

    Code
      am_put(doc, AM_ROOT, c("a", "b"), "value")
    Condition
      Error in `am_put()`:
      ! Map key must be a single character string

---

    Code
      am_put(doc, AM_ROOT, list("key"), "value")
    Condition
      Error in `am_put()`:
      ! Map key must be a single character string

# am_put with invalid positions for lists

    Code
      am_put(doc, items, 0, "value")
    Condition
      Error in `am_put()`:
      ! List position must be positive

---

    Code
      am_put(doc, items, -1, "value")
    Condition
      Error in `am_put()`:
      ! List position must be positive

---

    Code
      am_put(doc, items, c(1, 2), "value")
    Condition
      Error in `am_put()`:
      ! List position must be a scalar

# am_put with invalid value types

    Code
      am_put(doc, AM_ROOT, "time", as.POSIXct(c("2024-01-01", "2024-01-02")))
    Condition
      Error in `am_put()`:
      ! Timestamp must be scalar

---

    Code
      am_put(doc, AM_ROOT, "counter", counter)
    Condition
      Error in `am_put()`:
      ! Counter must be a scalar integer

---

    Code
      am_put(doc, AM_ROOT, "text", structure(123, class = "am_text_type"))
    Condition
      Error in `am_put()`:
      ! am_text must be a single character string

---

    Code
      am_put(doc, AM_ROOT, "text", structure(c("a", "b"), class = "am_text_type"))
    Condition
      Error in `am_put()`:
      ! am_text must be a single character string

# am_insert validates list-only operation

    Code
      am_insert(doc, AM_ROOT, 1, "value")
    Condition
      Error in `am_insert()`:
      ! am_insert() can only be used on list objects

---

    Code
      am_insert(doc, map_obj, 1, "value")
    Condition
      Error in `am_insert()`:
      ! am_insert() can only be used on list objects

# am_delete with invalid positions for lists

    Code
      am_delete(doc, items, 0)
    Condition
      Error in `am_delete()`:
      ! List position must be positive

---

    Code
      am_delete(doc, items, -1)
    Condition
      Error in `am_delete()`:
      ! List position must be positive

---

    Code
      am_delete(doc, items, c(1, 2))
    Condition
      Error in `am_delete()`:
      ! List position must be a scalar

# am_text_splice validation errors

    Code
      am_text_splice(text_obj, "not numeric", 0, "")
    Condition
      Error in `am_text_splice()`:
      ! pos must be numeric

---

    Code
      am_text_splice(text_obj, 0, "not numeric", "")
    Condition
      Error in `am_text_splice()`:
      ! del_count must be numeric

---

    Code
      am_text_splice(text_obj, 0, 0, 123)
    Condition
      Error in `am_text_splice()`:
      ! text must be a single character string

---

    Code
      am_text_splice(text_obj, 0, 0, c("a", "b"))
    Condition
      Error in `am_text_splice()`:
      ! text must be a single character string

---

    Code
      am_text_splice(text_obj, -1, 0, "")
    Condition
      Error in `am_text_splice()`:
      ! pos must be non-negative

---

    Code
      am_text_splice(text_obj, 0, -1, "")
    Condition
      Error in `am_text_splice()`:
      ! del_count must be non-negative

# am_counter_increment validation errors

    Code
      am_counter_increment(doc, AM_ROOT, "counter", "not numeric")
    Condition
      Error in `am_counter_increment()`:
      ! Delta must be numeric

---

    Code
      am_counter_increment(doc, AM_ROOT, "counter", c(1, 2))
    Condition
      Error in `am_counter_increment()`:
      ! Delta must be scalar

---

    Code
      am_counter_increment(doc, AM_ROOT, 123, 1)
    Condition
      Error in `am_counter_increment()`:
      ! Map key must be a single character string

---

    Code
      am_counter_increment(doc, AM_ROOT, c("a", "b"), 1)
    Condition
      Error in `am_counter_increment()`:
      ! Map key must be a single character string

---

    Code
      am_counter_increment(doc, text_obj, 0, 1)
    Condition
      Error in `am_counter_increment()`:
      ! Cannot increment counter in text object

# am_counter_increment with list positions

    Code
      am_counter_increment(doc, counters, "not numeric", 1)
    Condition
      Error in `am_counter_increment()`:
      ! List position must be numeric

---

    Code
      am_counter_increment(doc, counters, c(1, 2), 1)
    Condition
      Error in `am_counter_increment()`:
      ! List position must be scalar

---

    Code
      am_counter_increment(doc, counters, 0, 1)
    Condition
      Error in `am_counter_increment()`:
      ! List position must be >= 1 (R uses 1-based indexing)

# am_cursor validation errors

    Code
      am_cursor(text_obj, "not numeric")
    Condition
      Error in `am_cursor()`:
      ! position must be numeric

---

    Code
      am_cursor(text_obj, c(1, 2))
    Condition
      Error in `am_cursor()`:
      ! position must be a scalar

---

    Code
      am_cursor(text_obj, -1)
    Condition
      Error in `am_cursor()`:
      ! position must be non-negative (uses 0-based indexing)

# am_cursor_position validation errors

    Code
      am_cursor_position("not a cursor")
    Condition
      Error in `am_cursor_position()`:
      ! cursor must be an external pointer (am_cursor object)

---

    Code
      am_cursor_position(123)
    Condition
      Error in `am_cursor_position()`:
      ! cursor must be an external pointer (am_cursor object)

# am_mark_create validation errors

    Code
      am_mark_create(text_obj, "not numeric", 5, "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! start must be numeric

---

    Code
      am_mark_create(text_obj, c(0, 1), 5, "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! start must be a scalar

---

    Code
      am_mark_create(text_obj, -1, 5, "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! start must be non-negative (uses 0-based indexing)

---

    Code
      am_mark_create(text_obj, 0, "not numeric", "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! end must be numeric

---

    Code
      am_mark_create(text_obj, 0, c(3, 5), "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! end must be a scalar

---

    Code
      am_mark_create(text_obj, 0, -1, "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! end must be non-negative (uses 0-based indexing)

---

    Code
      am_mark_create(text_obj, 5, 5, "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! end must be greater than start

---

    Code
      am_mark_create(text_obj, 5, 3, "bold", TRUE)
    Condition
      Error in `am_mark_create()`:
      ! end must be greater than start

---

    Code
      am_mark_create(text_obj, 0, 5, 123, TRUE)
    Condition
      Error in `am_mark_create()`:
      ! name must be a single character string

---

    Code
      am_mark_create(text_obj, 0, 5, c("a", "b"), TRUE)
    Condition
      Error in `am_mark_create()`:
      ! name must be a single character string

---

    Code
      am_mark_create(text_obj, 0, 5, "bold", TRUE, expand = "invalid")
    Condition
      Error in `am_mark_create()`:
      ! Invalid expand value: must be "none", "before", "after", or "both"

---

    Code
      am_mark_create(text_obj, 0, 5, "bold", TRUE, expand = 123)
    Condition
      Error in `am_mark_create()`:
      ! expand must be a single character string

---

    Code
      am_mark_create(text_obj, 0, 5, "time", as.POSIXct(c("2024-01-01", "2024-01-02")))
    Condition
      Error in `am_mark_create()`:
      ! Mark value must be scalar

---

    Code
      am_mark_create(text_obj, 0, 5, "counter", counter)
    Condition
      Error in `am_mark_create()`:
      ! Counter must be a scalar integer

# am_marks_at validation errors

    Code
      am_marks_at(text_obj, "not numeric")
    Condition
      Error in `am_marks_at()`:
      ! position must be numeric

---

    Code
      am_marks_at(text_obj, c(0, 1))
    Condition
      Error in `am_marks_at()`:
      ! position must be a scalar

---

    Code
      am_marks_at(text_obj, -1)
    Condition
      Error in `am_marks_at()`:
      ! position must be non-negative (uses 0-based indexing)

# am_create with invalid actor_id types

    Code
      am_create(actor_id = 123)
    Condition
      Error in `am_create()`:
      ! actor_id must be NULL, a character string (hex), or raw bytes

---

    Code
      am_create(actor_id = list("id"))
    Condition
      Error in `am_create()`:
      ! actor_id must be NULL, a character string (hex), or raw bytes

---

    Code
      am_create(actor_id = TRUE)
    Condition
      Error in `am_create()`:
      ! actor_id must be NULL, a character string (hex), or raw bytes

# am_fork with invalid heads parameter

    Code
      am_fork(doc, heads = "not a list")
    Condition
      Error in `am_fork()`:
      ! heads must be NULL or a list of raw vectors

---

    Code
      am_fork(doc, heads = 123)
    Condition
      Error in `am_fork()`:
      ! heads must be NULL or a list of raw vectors

---

    Code
      am_fork(doc, heads = list("not raw"))
    Condition
      Error in `am_fork()`:
      ! All heads must be raw vectors (change hashes)

---

    Code
      am_fork(doc, heads = list(123))
    Condition
      Error in `am_fork()`:
      ! All heads must be raw vectors (change hashes)

# am_get_change_by_hash validation errors

    Code
      am_get_change_by_hash(doc, "not raw")
    Condition
      Error in `am_get_change_by_hash()`:
      ! hash must be a raw vector

---

    Code
      am_get_change_by_hash(doc, 123)
    Condition
      Error in `am_get_change_by_hash()`:
      ! hash must be a raw vector

---

    Code
      am_get_change_by_hash(doc, raw(10))
    Condition
      Error in `am_get_change_by_hash()`:
      ! Change hash must be exactly 32 bytes

---

    Code
      am_get_change_by_hash(doc, raw(50))
    Condition
      Error in `am_get_change_by_hash()`:
      ! Change hash must be exactly 32 bytes

