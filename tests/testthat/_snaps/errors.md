# Automerge errors are caught with error messages

    Code
      am_load(as.raw(c(0, 1, 2)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: not enough data

---

    Code
      am_load(as.raw(sample(0:255, 100, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

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
      am_text_splice(doc, map_obj$obj_id, 0, 0, "text")
    Condition
      Error in `am_text_splice()`:
      ! Automerge error at objects.c:670: invalid op for object of type `map`

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
      ! Automerge error at document.c:127: bad checksum

# Error messages include file and line information

    Code
      am_load(as.raw(c(255)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: not enough data

# Multiple error conditions in sequence

    Code
      am_load(as.raw(c(0)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: not enough data

---

    Code
      am_load(as.raw(c(255)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: not enough data

# Resource cleanup after errors

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

---

    Code
      am_load(as.raw(sample(0:255, 50, replace = TRUE)))
    Condition
      Error in `am_load()`:
      ! Automerge error at document.c:127: unable to parse chunk: failed to parse header: Invalid magic bytes

