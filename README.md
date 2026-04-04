# NexusLink (nlink)

**OBINexus Computing** — Magnetic Osmotic Nexus Linker — Link by Need

NexusLink is a cross-platform, on-demand component linkage and build orchestration system for C projects. Inspired by the principle of *magnetic osmosis* — components are drawn together by need rather than forced by configuration — NexusLink resolves and links only what is required, when it is required. It provides a tokenizer/parser pipeline, a minimizer/automaton subsystem, Shannon entropy–based crypto utilities, pattern matching, and a declarative scripting CLI — all linked as a single static library (`libnlink.a`) or executable (`nlink` / `nlink.exe`).

### Design Philosophy

> **"Link by Need"** — NexusLink follows a magnetic osmotic model: components attract each other through declared dependencies, not hard-wired inclusion. Like osmotic pressure driving molecules across a membrane, NexusLink's lazy versioned loader resolves symbols at the boundary between what is loaded and what is needed. This keeps binaries lean, linking predictable, and component boundaries explicit.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Repository Layout](#repository-layout)
3. [Building with Make](#building-with-make)
4. [Building with CMake](#building-with-cmake)
5. [Compiling and Linking Your Own C Code](#compiling-and-linking-your-own-c-code)
6. [Include Path Guide](#include-path-guide)
7. [CLI Usage](#cli-usage)
8. [Feature Modules](#feature-modules)
9. [Environment Variants](#environment-variants)

---

## Prerequisites

### Linux / WSL (Ubuntu / Debian)

```bash
sudo apt install build-essential cmake
```

GCC 9+ and CMake 3.16+ are recommended.

### Windows — MSVC (recommended for native Windows builds)

Install [Visual Studio 2022](https://visualstudio.microsoft.com/) (Community or higher) with the **Desktop development with C++** workload. CMake 3.16+ is included with Visual Studio.

From a **Developer PowerShell** or **Developer Command Prompt** run `make` or invoke CMake directly (see [Building with CMake](#building-with-cmake)).

### Windows — MinGW-w64 (alternative)

Install [MSYS2](https://www.msys2.org/) and then from the MSYS2 shell:

```bash
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-cmake make
```

Or install the standalone [MinGW-w64](https://sourceforge.net/projects/mingw-w64/) toolchain and ensure `gcc`, `g++`, `ar`, and `make` are on your `PATH` (e.g. `C:\MinGW\bin`).

> **Note**: On Windows the build system detects `$(OS) == Windows_NT` automatically. A single `Makefile` handles both platforms — no separate `Makefile.win` is needed.

### POSIX-only features

The **lazy versioned loader** (`src/core/common/nexus_loader.c`) and the **lazy versioning header** (`include/nlink/core/versioning/lazy_versioned.h`) use POSIX threads and `dlopen`/`dlsym`. On Windows these translate to `CRITICAL_SECTION` / `LoadLibrary` respectively. If you are building with MSVC, `dlopen` calls in `nexus_loader.c` will not link; those call-sites require a Windows port or must be excluded from the MSVC build.

---

## Repository Layout

```
nlink/
├── Makefile                  # Cross-platform build (Make)
├── CMakeLists.txt            # CMake root
├── cmake/                    # CMake modules (PackageConfig, ComponentSystem, …)
├── include/
│   ├── fnmatch.h             # Portable fnmatch shim (Windows / bare MinGW)
│   └── nlink/
│       └── core/             # All public headers
│           ├── common/
│           ├── minimizer/
│           ├── mpsystem/
│           ├── parser/
│           ├── pattern/
│           ├── pipeline/
│           ├── schema/
│           ├── spsystem/
│           ├── symbols/
│           ├── tatit/        # Tactic / tactical programming primitives
│           ├── token/        # Token type definitions
│           ├── versioning/
│           └── …
├── src/
│   ├── cli/                  # CLI entry point (main.c) and commands
│   └── core/                 # Component implementation sources
│       ├── common/
│       ├── minimizer/
│       ├── parser/
│       ├── tokenizer/
│       └── …
├── bin/                      # Release executable (created by Make)
└── build/
    ├── windows/              # MSVC build tree  (created by Make on Windows_NT)
    └── linux/                # GCC/Clang build tree (created by Make on WSL/Linux)
```

---

## Building with Make

The `Makefile` in the project root is the primary build driver. It auto-detects Windows vs Linux/WSL.

### Release build (default)

```bash
make              # Linux / WSL
make release      # explicit
```

Produces: `bin/nlink` (Linux) or `bin\nlink.exe` (Windows)

### Debug build

```bash
make debug
```

Produces: `build/debug/bin/nlink` (Linux) or `build\debug\bin\nlink.exe` (Windows)

### Build both

```bash
make all
```

### Clean

```bash
make clean
```

### Environment variants

```bash
make dev    # -DNLINK_ENV=dev  -DSHANNON_STRICT_MODE=1    (strict entropy validation)
make prod   # -DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1 (performance-optimised)
```

### Other targets

```bash
make features          # list all feature modules
make etps-test         # ETPS telemetry smoke test (JSON output)
make etps-config-test  # ETPS test with config file (release binary)
make qa-test           # TP/TN/FP/FN QA soundness validation
make qa-validate       # POC + spec validation suite
make poc               # run POC enhanced integration build
make spec              # build QA specification framework
make spec-run          # execute QA specifications
```

---

## Building with CMake

CMake is required for installation, package generation, and IDE integration.

### Linux / WSL

```bash
cmake -S . -B build -G "Unix Makefiles"
cmake --build build --parallel
```

### Windows (MinGW-w64)

Open a PowerShell or cmd window with MinGW on `PATH`, then:

```powershell
cmake -S . -B build -G "MinGW Makefiles"
cmake --build build --parallel
```

> **Platform-specific build trees**: The `Makefile` writes CMake output to `build/windows/` when run under Windows (`OS=Windows_NT`) and to `build/linux/` under WSL or Linux. The two trees are completely independent, so **you can switch between Windows and WSL at any time without clearing the cache**.
>
> If you ever need to force a full CMake reconfigure for the current platform:
>
> ```bash
> make cmake-reset    # removes CMakeCache.txt and CMakeFiles/ from the active platform tree
> ```

### Install

```bash
cmake --install build --prefix /usr/local   # Linux
cmake --install build --prefix C:/nlink     # Windows
```

---

## Compiling and Linking Your Own C Code

NexusLink exposes its functionality through a static library (`libnlink.a` / `nlink.a`). You include the public headers from `include/` and link against the library produced under `build/release/lib/`.

### Quick example

```c
/* example.c */
#include <stdio.h>

/* Public NexusLink headers — resolved via -I./include */
#include "nlink/core/common/nexus_core.h"
#include "nlink/core/tatit/tactic.h"
#include "nlink/core/token/type.h"

int main(void) {
    /* Initialise the NexusLink core */
    nlink_core_init();

    printf("NexusLink initialised successfully.\n");

    nlink_core_cleanup();
    return 0;
}
```

### Compile and link (Linux / WSL)

Build the library first (one-time):

```bash
make release
```

Then compile your file:

```bash
gcc -std=c11 -Wall \
    -I./include \
    -I./src/core \
    example.c \
    -L./build/release/lib -lnlink \
    -o example
```

Run:

```bash
./example
```

### Compile and link (Windows — MinGW)

```bat
gcc -std=c11 -Wall ^
    -I.\include ^
    -I.\src\core ^
    example.c ^
    -L.\build\release\lib -lnlink ^
    -o example.exe
```

Run:

```bat
example.exe
```

### Compiler flags explained

| Flag | Purpose |
|------|---------|
| `-I./include` | Adds `include/` so headers like `nlink/core/tatit/tactic.h` are found |
| `-I./src/core` | Adds `src/core/` so source-local headers (`tokenizer.h`, `parser.h`) are found when building components that include each other |
| `-iquote./include` | Same as `-I./include` but applies to `#include "..."` (quoted) forms first, ensuring the project shim `fnmatch.h` wins over any system version |
| `-L./build/release/lib` | Tells the linker where `libnlink.a` lives |
| `-lnlink` | Links against `libnlink.a` |

### Using the tokenizer and parser

```c
#include "nlink/core/tatit/tactic.h"
#include "nlink/core/token/type.h"
/* tokenizer.h lives in src/core/tokenizer/ — reachable via -I./src/core */
#include "tokenizer/tokenizer.h"
#include "parser/parser.h"

void run_pipeline(const char *input_text) {
    /* 1. Tokenise */
    nlink_tokenizer_context *tok = nlink_tokenizer_create(input_text, NULL);
    nlink_token **tokens = nlink_tokenizer_tokenize(tok);

    /* 2. Parse into AST */
    nlink_parser_context *parser = nlink_parser_create(tokens, NULL);
    nlink_ast_node *ast = nlink_parser_parse(parser);

    /* 3. Traverse / transform the AST */
    nlink_ast_traverse(ast, my_visitor, NULL);

    /* 4. Cleanup */
    nlink_ast_node_free(ast);
    nlink_parser_free(parser);
    nlink_tokenizer_free(tok);
}
```

Compile:

```bash
gcc -std=c11 -Wall \
    -I./include \
    -I./src/core \
    my_pipeline.c \
    -L./build/release/lib -lnlink \
    -o my_pipeline
```

### Linking against the CMake-installed library

After `cmake --install build --prefix /usr/local`:

```bash
gcc -std=c11 my_app.c \
    -I/usr/local/include/nlink \
    -L/usr/local/lib -lnlink \
    -o my_app
```

Or use `find_package` in your own CMake project:

```cmake
find_package(NexusLink REQUIRED)
target_link_libraries(my_app PRIVATE nlink::nlink_static)
```

---

## Include Path Guide

All public headers live under `include/nlink/core/<module>/`. Always use the **absolute** form from `include/` as the root — never relative paths like `../tactic/`.

| Module | Correct include |
|--------|----------------|
| Tactic primitives | `#include "nlink/core/tatit/tactic.h"` |
| Token type enum | `#include "nlink/core/token/type.h"` |
| Pattern / regex compat | `#include "nlink/core/pattern/regex_compat.h"` |
| Common core | `#include "nlink/core/common/nexus_core.h"` |
| Result / error types | `#include "nlink/core/common/nexus_result.h"` |
| Pipeline | `#include "nlink/core/pipeline/nlink_pipeline.h"` |
| Symbols | `#include "nlink/core/symbols/symbols.h"` |
| Versioning | `#include "nlink/core/versioning/nexus_version.h"` |
| MP system | `#include "nlink/core/mpsystem/mps_pipeline.h"` |
| SP system | `#include "nlink/core/spsystem/sps_pipeline.h"` |
| Minimizer | `#include "nlink/core/minimizer/nexus_minimizer.h"` |

Source-local headers (used only inside the library sources) are reached via `-I./src/core`:

```c
#include "tokenizer/tokenizer.h"   /* src/core/tokenizer/tokenizer.h */
#include "parser/parser.h"         /* src/core/parser/parser.h       */
```

---

## CLI Usage

### Interactive mode

```
$ nlink --interactive

*******************************************
*         NexusLink CLI System           *
*          © OBINexus Computing          *
*******************************************
Type 'help' for available commands, 'exit' to quit

nexus> load tokenizer
Loading component 'tokenizer'...
Successfully loaded component 'tokenizer'

nexus> load parser
Loading component 'parser'...
Successfully loaded component 'parser'

nexus> pipeline create mode=single
Created pipeline in single-pass mode with optimization enabled

nexus> pipeline add-stage tokenizer
Added stage 'tokenizer' to pipeline

nexus> pipeline add-stage parser
Added stage 'parser' to pipeline

nexus> pipeline execute
Running pipeline optimizations...
Executing pipeline...
Pipeline executed successfully in 45.23 ms with 1 iteration(s)

nexus> stats
System Statistics:
-----------------
  Components loaded: 2
  Memory usage: 0.8 MB
  Heap allocations: 73
  Peak memory: 1.2 MB
  Symbol table entries: 128
  Commands registered: 7
  Pipelines active: 1

nexus> exit
```

### Script execution

Save a `.nlink` script file:

```
# script.nlink - Tokenizer/Parser single pass pipeline
load tokenizer
load parser
pipeline create mode=single
pipeline add-stage tokenizer
pipeline add-stage parser
pipeline execute
stats
```

Run it:

```bash
nlink --execute script.nlink
```

### Other CLI flags

```bash
nlink --etps-test --json          # ETPS telemetry (JSON output)
nlink --etps-test --config nlink.conf --json
nlink --qa-validate               # QA soundness validation
nlink --help                      # Full flag reference
```

See `docs/cli/` for the full CLI reference and command hierarchy.

---

## Feature Modules

| Module | Description |
|--------|-------------|
| `semverx` | Semantic version extended parsing |
| `parser` | Token stream → AST parser |
| `schema` | Schema validation system |
| `minimizer` | Automaton / DFA minimization (Okpala algorithm) |
| `etps` | Error telemetry and pipeline statistics |
| `symbols` | Symbol table management |
| `pipeline` | Multi-stage processing pipeline |
| `cli` | Command-line interface and script runner |
| `tatit` | Tactical programming primitives (tactic, transform, consumer) |
| `mpsystem` | Multi-pass processing system |
| `spsystem` | Single-pass processing system |

List all at any time:

```bash
make features
```

---

## Environment Variants

Two build-time environment profiles control runtime behaviour:

```bash
make dev    # -DNLINK_ENV=dev  -DSHANNON_STRICT_MODE=1
            # Enables strict entropy validation for development

make prod   # -DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1
            # Enables performance-optimised entropy processing
```

Shannon entropy support is always compiled in via `-DSHANNON_ENTROPY_ENABLED=1`.

---

© 2026 OBINexus Computing. All rights reserved.
