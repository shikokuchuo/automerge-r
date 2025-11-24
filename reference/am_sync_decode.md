# Receive and apply a sync message

Receives a synchronization message from a peer and applies the changes
to the local document. This updates both the document and the sync state
to reflect the received changes.

## Usage

``` r
am_sync_decode(doc, sync_state, message)
```

## Arguments

- doc:

  An Automerge document

- sync_state:

  A sync state object (created with
  [`am_sync_state_new()`](http://shikokuchuo.net/automerge-r/reference/am_sync_state_new.md))

- message:

  A raw vector containing an encoded sync message

## Value

The document `doc` (invisibly, for chaining)

## Examples

``` r
doc <- am_create()
sync_state <- am_sync_state_new()

# Receive message from peer
# message <- ... (received from network)
# am_sync_decode(doc, sync_state, message)
```
