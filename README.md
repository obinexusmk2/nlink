# NexusLink (nlink)

**OBINexus Computing** — Magnetic Osmotic Nexus Linker — Link by Need

NexusLink is a cross-platform, on-demand component linkage and build orchestration system for C. Inspired by *magnetic osmosis* — components are drawn together by declared need, not hard-wired inclusion — NexusLink resolves and links only what is required, when it is required. It ships a tokenizer/parser pipeline, a DFA minimizer (Okpala algorithm), pattern matching, a declarative scripting CLI, and single-pass / multi-pass processing systems, all delivered as a single static library or executable.

---

## Design Philosophy

> **"Link by Need"** — Like osmotic pressure driving molecules across a membrane, NexusLink's lazy versioned loader resolves symbols at the boundary between what is loaded and what is needed. Components declare their dependencies; the runtime draws them in only when — and only as much as — they are actually used. This keeps binaries lean, linking predictable, and component boundaries explicit.

See [`examples/link-by-need/`](examples/link-by-need/README.md) for worked examples and measured size comparisons.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Building on Windows (MSVC)](#building-on-windows-msvc)
3. [Building on Linux / WSL](#building-on-linux--wsl)
4. [Repository Layout](#repository-layout)
5. [CLI Usage](#cli-usage)
6. [Compiling and Linking Your Own Code](#compiling-and-linking-your-own-code)
7. [Include Path Guide](#include-path-guide)
8. [Feature Modules](#feature-modules)
9. [Link-by-Need Examples](#link-by-need-examples)
10. [Environment Variants](#environment-variants)

---

## Prerequisites

### Windows — MSVC (native)

Install [Visual Studio 2022](https://visualstudio.microsoft.com/) Community or higher with the **Desktop development with C++** workload (CMake is bundled). Open a **Developer PowerShell** or **Developer Command Prompt** and run `make` from the repository root.

### Linux / WSL (Ubuntu / Debian)

```bash
sudo apt install build-essential cmake
```

GCC 11+ and CMake 3.16+ are recommended. If you are in WSL, the build tree is written to `build/linux/` and is completely independent from the Windows `build/windows/` tree.

### Windows — MinGW-w64 (alternative)

```bash
# MSYS2 shell
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-cmake make
```

---

## Building on Windows (MSVC)

From a **Developer PowerShell** at the repository root:

```powershell
make          # configure + build (Debug)
make release  # Release build
make clean    # wipe build/windows/
```

The binary is written to:

```
build\windows\bin\nlink.exe
```

Run it:

```powershell
.\build\windows\bin\nlink.exe --help
```

Sample output:

```
Usage: C:\...\nlink.exe [OPTIONS] COMMAND [ARGS...]

A dynamic component linkage system for efficient binary sizes and runtime loading.

Options:
  -h, --help          Show this help message
  -v, --version       Show version information
  -m, --minimal CMD   Use minimal syntax mode
  -i, --interactive   Run in interactive mode
  -e, --execute FILE  Execute commands from script file

Commands:
  help        Display help information
  list        List available components
  stats       Show system statistics
  load        Load a component
  version     Display version information
  minimal     m
  minimize    Minimize a component using state machine minimization
```

---

## Building on Linux / WSL

Use the provided shell script (LF line endings, no `dos2unix` needed):

```bash
bash build-linux.sh            # Debug (default)
bash build-linux.sh --release  # Release
bash build-linux.sh --clean    # Wipe build/linux/ then rebuild
bash build-linux.sh --no-test  # Skip CTest configuration
```

Or use `make` directly:

```bash
make            # Debug build via CMake
make release    # Release build
make clean      # Remove build/linux/
```

The binary is written to:

```
build/linux/bin/nlink
```

> **Switching between Windows and WSL**  
> `make` writes to `build/windows/` on `OS=Windows_NT` and `build/linux/` otherwise. The two trees are independent — switch freely without clearing the cache. To force a CMake reconfigure:
> ```bash
> make cmake-reset
> ```

---

## Repository Layout

```
nlink/
├── Makefile                   # Cross-platform build (auto-detects Windows / Linux)
├── build-linux.sh             # Convenience wrapper for Linux / WSL builds
├── build-windows.ps1          # Convenience wrapper for Windows PowerShell builds
├── CMakeLists.txt             # CMake root
├── cmake/                     # CMake modules (BuildSystem, ComponentSystem, …)
├── include/
│   └── nlink/
│       └── core/
│           ├── common/        # Types, results, core context, JSON utils
│           ├── minimizer/     # DFA minimizer (Okpala algorithm)
│           ├── mpsystem/      # Multi-pass processing system
│           ├── parser/        # Token stream → AST
│           ├── pattern/       # Glob / regex pattern matching
│           ├── pipeline/      # Multi-stage processing pipeline
│           ├── schema/        # Schema validation
│           ├── spsystem/      # Single-pass processing system
│           ├── symbols/       # Symbol table
│           ├── tactic/        # Tactical programming primitives
│           ├── token/         # Token type definitions
│           └── versioning/    # Semantic versioning + lazy loader
├── src/
│   ├── cli/                   # main.c + CLI commands
│   └── core/                  # Component implementations
├── examples/
│   └── link-by-need/          # Worked examples with size comparisons
└── build/
    ├── windows/               # MSVC build tree
    └── linux/                 # GCC/Clang build tree
```

---

## CLI Usage

### Quick reference

```
nlink [OPTIONS] COMMAND [ARGS...]

Options:
  -h, --help           Show help
  -v, --version        Show version
  -m, --minimal CMD    Minimal syntax mode
  -i, --interactive    Interactive REPL
  -e, --execute FILE   Run a .nlink script
```

### Interactive mode

```
$ nlink --interactive

*******************************************
*         NexusLink CLI System            *
*          © OBINexus Computing           *
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
Pipeline executed successfully in 45.23 ms with 1 iteration(s)

nexus> stats
System Statistics:
  Components loaded:    2
  Memory usage:         0.8 MB
  Symbol table entries: 128
  Commands registered:  7
  Pipelines active:     1

nexus> exit
```

### Script mode

```bash
# script.nlink
load tokenizer
load parser
pipeline create mode=single
pipeline add-stage tokenizer
pipeline add-stage parser
pipeline execute
stats
```

```bash
nlink --execute script.nlink
```

### Other targets

```bash
make test               # run CTest suite
make etps-test          # ETPS telemetry smoke test (JSON output)
make qa-test            # TP/TN/FP/FN soundness validation
make qa-validate        # POC + spec validation suite
make features           # list all registered modules
```

---

## Compiling and Linking Your Own Code

### Linux / WSL

Build the library once:

```bash
bash build-linux.sh --release
```

Then compile your application:

```bash
gcc -std=c11 -Wall \
    -I./include \
    my_app.c \
    -L./build/linux/lib \
    -lnlink_common -lnlink_pattern -lnlink_parser \
    -o my_app
```

Only link the components you actually use — that is the link-by-need principle in practice.

### Windows (MSVC / Developer PowerShell)

```powershell
make release
cl /std:c11 /I.\include my_app.c ^
   /link /LIBPATH:.\build\windows\lib\Release ^
   nlink_common.lib nlink_pattern.lib nlink_parser.lib ^
   /OUT:my_app.exe
```

### CMake consumer project

After `cmake --install`:

```cmake
find_package(NexusLink REQUIRED)
target_link_libraries(my_app PRIVATE nlink::nlink_common nlink::nlink_pattern)
```

---

## Include Path Guide

All public headers live under `include/nlink/core/<module>/`. Use the full path from `include/` — never relative paths like `../../pattern/`.

| Module | Header |
|--------|--------|
| Core context | `#include "nlink/core/common/nexus_core.h"` |
| Result / error | `#include "nlink/core/common/result.h"` |
| Types | `#include "nlink/core/common/types.h"` |
| Pattern matching | `#include "nlink/core/pattern/matcher.h"` |
| Pipeline | `#include "nlink/core/pipeline/nlink_pipeline.h"` |
| Minimizer | `#include "nlink/core/minimizer/nexus_minimizer.h"` |
| Symbols | `#include "nlink/core/symbols/nexus_symbols.h"` |
| Versioning | `#include "nlink/core/versioning/nexus_version.h"` |
| Tactic primitives | `#include "nlink/core/tactic/tactic.h"` |
| Single-pass system | `#include "nlink/core/spsystem/sps_pipeline.h"` |
| Multi-pass system | `#include "nlink/core/mpsystem/mps_pipeline.h"` |
| NexusLink init | `#include "nlink/core/versioning/nlink.h"` |

---

## Feature Modules

| Module | Description |
|--------|-------------|
| `common` | Core types, result monad, JSON utils, context |
| `parser` | Token stream → AST parser |
| `pattern` | Glob / POSIX-ERE / literal pattern matching |
| `minimizer` | DFA minimization (Okpala state-equivalence algorithm) |
| `pipeline` | Multi-stage processing pipeline with pass/stage API |
| `symbols` | Symbol table management |
| `tactic` | Functional composition, transformation pipelines |
| `tokenizer` | Lexer producing typed token streams |
| `spsystem` | Single-pass processing system |
| `mpsystem` | Multi-pass processing system with cycle detection |
| `versioning` | Semantic versioning + lazy versioned loader |
| `schema` | Declarative schema validation |
| `metadata` | Component metadata registry |

```bash
make features   # print all registered modules at build time
```

---

## Link-by-Need Examples

See [`examples/link-by-need/README.md`](examples/link-by-need/README.md) for:

- How `nlink.conf` declares component dependencies
- Three worked programs (minimal / pipeline / full) with measured binary size comparisons
- Cross-platform CMakeLists.txt
- Explanation of how the lazy versioned loader pulls in only what each binary actually uses

---

## Environment Variants

```bash
make dev    # -DNLINK_ENV=dev  -DSHANNON_STRICT_MODE=1      strict entropy validation
make prod   # -DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1  performance-optimised
```

Shannon entropy support is always compiled in via `-DSHANNON_ENTROPY_ENABLED=1`.

---

© 2026 OBINexus Computing. All rights reserved.
