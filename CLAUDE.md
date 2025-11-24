# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R package (`automerge`) that provides bindings to the Automerge Conflict-free Replicated Data Type (CRDT) library via its C FFI (Foreign Function Interface). The package is in early development phase with minimal functionality implemented.

**Key Architecture:**
- R package structure with C bindings to Rust-based automerge-c library
- The package wraps the automerge-c C API to expose CRDT functionality to R
- Currently only has package registration and constants defined - no core functionality yet

## Build System

### Build Configuration

The package uses a two-phase build approach controlled by configure scripts:

1. **System Library Detection**: First tries to find system-installed `automerge-c`
   - Searches standard prefixes: `/usr/local`, `/usr`, `/opt/local`, `/opt/homebrew`
   - Falls back to `pkg-config` if available
   - **UTF-32 Verification**: Compiles a test program to verify the system library uses UTF-32 character indexing
   - If system library uses UTF-8 byte indexing, falls back to bundled build
   - Set `AUTOMERGE_LIBS=1` environment variable to force bundled build

2. **Bundled Build**: If system library not found or incompatible, builds automerge-c from source
   - Located in `src/automerge/rust/automerge-c/`
   - Uses CMake with `-DUTF32_INDEXING=ON` flag
   - Requires Rust toolchain >= 1.89.0 and CMake >= 3.25

### Platform-Specific Configuration

- **Unix/macOS**: `configure` script generates `src/Makevars`
  - Links: `-framework Security -framework Foundation` (macOS), `-pthread -ldl -lm -lrt` (Linux)

- **Windows**: `configure.win` script generates `src/Makevars.win`
  - Uses MinGW Makefiles
  - Links: `-lws2_32 -luserenv -lbcrypt -lntdll`
  - CMake included in Rtools43+

### Build Commands

```bash
# Install package (triggers configure + build)
R CMD INSTALL .

# Build package tarball
R CMD build .

# Check package (runs R CMD check)
R CMD check automerge_*.tar.gz

# Clean build artifacts
./cleanup
# Or manually:
rm -f src/Makevars src/Makevars.win src/*.o src/*.so
rm -rf src/automerge/rust/automerge-c/{build,install}
```

### Development Workflow

```r
# Load package for development
devtools::load_all()

# Run tests
devtools::test()
# Or:
testthat::test_local()

# Build documentation
devtools::document()

# Install locally
devtools::install()
```

## Code Structure

### R Layer (`R/`)
- `constants.R`: Exports R constants that map to C enums
  - Object types: `AM_ROOT`, `AM_OBJ_TYPE_LIST`, `AM_OBJ_TYPE_MAP`, `AM_OBJ_TYPE_TEXT`
  - Mark expansion modes: `AM_MARK_EXPAND_NONE/BEFORE/AFTER/BOTH`
  - Internal maps (`.am_obj_type_map`, `.am_mark_expand_map`) convert strings to C enum integers

### C Layer (`src/`)
- `automerge.h`: Main header defining data structures and function declarations
  - Memory-safe wrappers: `am_doc`, `am_syncstate` (track ownership)
  - Finalizers for external pointers
  - Safety limits: `MAX_ERROR_MSG_SIZE=8192`
  - Includes `<automerge-c/automerge.h>` from system or bundled build

- `init.c`: R package registration
  - Currently empty `CallEntries` array (no C functions registered yet)
  - Disables dynamic symbol lookup for security

### Build Templates
- `src/Makevars.in` / `src/Makevars.win.in`: Templates substituted by configure scripts
  - `@PKG_CFLAGS@` and `@PKG_LIBS@` placeholders
  - Currently only compiles `init.o`
  - Comments indicate future object files: `document.o`, `objects.o`, `sync.o`, `conversions.o`, `errors.o`, `memory.o`

## Development Status

**Phase 1 (Current)**: Package infrastructure only
- Basic R package structure
- Build system with bundled automerge-c
- Constants exported to R
- No C function implementations yet

**Planned Implementation** (based on Makevars comments and README):
- Document operations: create, commit, access
- Object operations: maps, lists, text
- Synchronization: bidirectional sync protocols
- Type conversions: R ↔ C ↔ Automerge types
- Error handling and memory management

## Testing

```bash
# Run all tests
Rscript -e 'devtools::test()'

# Or using R CMD check
R CMD check automerge_*.tar.gz

# Current tests (tests/testthat/test-package.R):
# - Package loads successfully
# - Constants are correctly exported
```

## Code style

- Code comments should be made sparingly and only where needed for clarity
- Comments should always address the why, rather than the what

## Important Notes

- **Indexing Conventions**: The package uses different indexing conventions for different operations:

  **1-based indexing (element indices):**
  - List operations: `am_get()`, `am_put()`, `am_delete()`, `am_insert()`
  - List indices work like R vectors: first element is at index 1
  - Counter operations in lists: `am_counter_increment()` with list objects

  **0-based indexing (inter-character positions):**
  - Text operations: `am_text_splice()`
  - Cursor operations: `am_cursor()`, `am_cursor_position()`
  - Mark operations: `am_mark_create()`, `am_marks()`
  - Positions specify locations **between** characters, not the characters themselves
  - Position 0 = before first character, position 1 = between 1st and 2nd character
  - This distinction is necessary because you cannot represent "before the first character" with 1-based indexing

  Example for text "Hello":
  ```
    H e l l o
   0 1 2 3 4 5  <- positions (0-based, between characters)
  ```

- **UTF-32 Character Indexing**: CMake build uses UTF-32 code point indexing (matches R's character semantics)
  - Both text positions and character counts use Unicode code points, not bytes
  - Example: In "Hello😀", the emoji counts as 1 character at position 5
  - This matches R's `nchar()` behavior: `nchar("😀")` returns 1
  - JavaScript Note: JS uses UTF-16, so positions may differ for emoji and some Unicode characters

- **Security Considerations**:
  - Input validation limits defined in `automerge.h`
  - Ownership tracking prevents double-free vulnerabilities
  - Dynamic symbols disabled in registration

- **Dependencies**:
  - Zero R package dependencies (only base R)
  - System requirements: Rust >= 1.89.0, CMake >= 3.25 (if building from source)

- **Licensing**: MIT license with bundled automerge-c (also MIT) - see LICENSE.note
