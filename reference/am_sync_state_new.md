# Create a new sync state

Creates a new synchronization state for managing communication with a
peer. The sync state tracks what changes have been sent and received,
enabling efficient incremental synchronization.

## Usage

``` r
am_sync_state_new()
```

## Value

An external pointer to the sync state with class `"am_syncstate"`.

## Details

**IMPORTANT**: Sync state is document-independent. The same sync state
is used across multiple sync message exchanges with a specific peer. The
document is passed separately to
[`am_sync_encode()`](http://shikokuchuo.net/automerge-r/reference/am_sync_encode.md)
and
[`am_sync_decode()`](http://shikokuchuo.net/automerge-r/reference/am_sync_decode.md).

## Examples

``` r
# Create two documents
doc1 <- am_create()
doc2 <- am_create()

# Create sync states for each peer
sync1 <- am_sync_state_new()
sync2 <- am_sync_state_new()

# Use with am_sync_encode() and am_sync_decode()
```
