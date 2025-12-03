
<!-- README.md is generated from README.Rmd. Please edit that file -->

# automerge

<!-- badges: start -->

[![R-universe
version](https://shikokuchuo.r-universe.dev/automerge/badges/version)](https://shikokuchuo.r-universe.dev/automerge)
[![R-CMD-check](https://github.com/shikokuchuo/automerge-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/shikokuchuo/automerge-r/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/shikokuchuo/automerge-r/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/automerge-r)
<!-- badges: end -->

> Conflict-free data synchronization for R

`automerge` brings [Automerge](https://automerge.org/) CRDTs
(Conflict-free Replicated Data Types) to R, enabling automatic merging
of concurrent changes across distributed systems without conflicts. Work
offline, collaborate in real-time, or sync across platforms—changes
merge automatically.

## Why Automerge?

Traditional approaches to distributed data either require a central
server to coordinate changes or force developers to write complex
conflict resolution logic. Automerge’s CRDT technology automatically
merges concurrent changes with mathematical guarantees, eliminating the
need for coordination and making distributed systems dramatically
simpler.

## Quick Example

``` r
library(automerge)

# Two researchers working independently
alice <- am_create()
alice$experiment <- "trial_001"
alice$temperature <- 23.5
am_commit(alice, "Alice's data")

bob <- am_create()
bob$experiment <- "trial_002"
bob$humidity <- 65
am_commit(bob, "Bob's data")

# Later, sync with zero conflicts
am_sync(alice, bob)
alice
#> <Automerge Document>
#> Actor: c23764d2a11f6f0cef5d28a1eb2c4c75 
#> Root keys: 3 
#> Keys: experiment, humidity, temperature
bob
#> <Automerge Document>
#> Actor: 4bbc9fe0f47d3a0bce040be08a414851 
#> Root keys: 3 
#> Keys: experiment, humidity, temperature
```

## Key Features

- **Familiar R syntax**: Work with CRDT documents like regular R lists
- **Rich data types**: Maps, lists, text objects, counters, and
  timestamps
- **Collaborative text editing**: Cursors and marks for rich text
  applications
- **Bidirectional sync**: High-level `am_sync()` or low-level protocol
  access
- **Offline-first**: Make changes offline, merge when connected
- **Cross-platform**: Interoperates with JavaScript and other Automerge
  implementations
- **Zero dependencies**: Only base R required at runtime

## Installation

``` r
install.packages("automerge", repos = "https://shikokuchuo.r-universe.dev")
```

Building from source requires Rust \>= 1.89.0
([rustup.rs](https://rustup.rs/)) and CMake \>= 3.25 (included in
Rtools43+ on Windows).

## Documentation

- [Getting
  Started](https://shikokuchuo.net/automerge-r/articles/automerge.html):
  Introduction and basic usage
- [Quick
  Reference](https://shikokuchuo.net/automerge-r/articles/quick-reference.html):
  Function reference organized by task
- [CRDT
  Concepts](https://shikokuchuo.net/automerge-r/articles/crdt-concepts.html):
  Understanding conflict-free data types
- [Sync
  Protocol](https://shikokuchuo.net/automerge-r/articles/sync-protocol.html):
  Low-level synchronization details
- [Cross-Platform
  Synchronization](https://shikokuchuo.net/automerge-r/articles/cross-platform.html):
  Interoperability with JavaScript and other platforms
- [Function
  Reference](https://shikokuchuo.net/automerge-r/reference/index.html):
  Complete API documentation

## Status

**Under Active Development**: This package is in initial development and
functionality may change at any time

## External Resources

- [Automerge Website](https://automerge.org/) - Official Automerge
  documentation and guides
- [Automerge GitHub](https://github.com/automerge/automerge) - Automerge
  source code
- [Local-first software](https://www.inkandswitch.com/local-first/) -
  The philosophy behind Automerge

## License

MIT License. See [LICENSE](LICENSE) for details. This package includes
the [automerge-c](https://github.com/automerge/automerge) library (also
MIT licensed)
