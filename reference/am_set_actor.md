# Set the actor ID of a document

Sets the actor ID for an Automerge document. This should typically be
done before making any changes. Changing the actor ID mid-session is not
recommended as it can complicate change attribution.

## Usage

``` r
am_set_actor(doc, actor_id)
```

## Arguments

- doc:

  An Automerge document

- actor_id:

  The new actor ID. Can be:

  - `NULL` - Generate new random actor ID

  - Character string - Hex-encoded actor ID

  - Raw vector - Binary actor ID bytes

## Value

The document `doc` (invisibly)

## Examples

``` r
doc <- am_create()

# Set custom actor ID from hex string
am_set_actor(doc, "0123456789abcdef0123456789abcdef")

# Generate new random actor ID
am_set_actor(doc, NULL)
```
