# Generate a sync message

Generates a synchronization message to send to a peer. This message
contains the changes that the peer needs to bring their document up to
date with yours.

## Usage

``` r
am_sync_encode(doc, sync_state)
```

## Arguments

- doc:

  An Automerge document

- sync_state:

  A sync state object (created with
  [`am_sync_state_new()`](http://shikokuchuo.net/automerge-r/reference/am_sync_state_new.md))

## Value

A raw vector containing the encoded sync message, or `NULL` if no
message needs to be sent.

## Details

If the function returns `NULL`, it means there are no more messages to
send (synchronization is complete from this side).

## Examples

``` r
doc <- am_create()
sync_state <- am_sync_state_new()

# Generate first sync message
msg <- am_sync_encode(doc, sync_state)
if (!is.null(msg)) {
  # Send msg to peer...
}
#> NULL
```
