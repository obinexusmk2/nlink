#!/usr/bin/env bash
# build-linux.sh
# NexusLink — Linux / WSL GCC build script
# Copyright © 2025 OBINexus Computing
#
# Usage:
#   bash build-linux.sh                   # Debug build (default)
#   bash build-linux.sh --release         # Release build
#   bash build-linux.sh --clean           # Remove build/linux then rebuild
#   bash build-linux.sh --no-build        # Configure only (no compile)
#   bash build-linux.sh --no-test         # Skip test configuration
set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
CONFIG="Debug"
CLEAN=0
NO_BUILD=0
NO_TEST=0

# ── Argument parsing ─────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --release)   CONFIG="Release" ;;
    --debug)     CONFIG="Debug" ;;
    --clean)     CLEAN=1 ;;
    --no-build)  NO_BUILD=1 ;;
    --no-test)   NO_TEST=1 ;;
    -h|--help)
      echo "Usage: $0 [--release|--debug] [--clean] [--no-build] [--no-test]"
      exit 0 ;;
    *)
      echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build/linux"
BIN_PATH="$BUILD_DIR/bin/nlink"

info()  { echo -e "\033[36m[nlink]\033[0m $*"; }
fail()  { echo -e "\033[31mERROR:\033[0m $*" >&2; exit 1; }

# ── Dependency checks ─────────────────────────────────────────────────────────
command -v cmake >/dev/null 2>&1 || fail "cmake not found. Install with: sudo apt install cmake"
command -v cc    >/dev/null 2>&1 || \
  command -v gcc >/dev/null 2>&1 || fail "C compiler (gcc/cc) not found. Install with: sudo apt install build-essential"

# ── Optional clean ────────────────────────────────────────────────────────────
if [ "$CLEAN" -eq 1 ] && [ -d "$BUILD_DIR" ]; then
  info "Removing $BUILD_DIR ..."
  rm -rf "$BUILD_DIR"
fi

# ── Configure ─────────────────────────────────────────────────────────────────
info "Configuring (config=$CONFIG) ..."
TEST_FLAG="ON"
[ "$NO_TEST" -eq 1 ] && TEST_FLAG="OFF"

cmake \
  -S "$SCRIPT_DIR" \
  -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE="$CONFIG" \
  -DBUILD_TESTING="$TEST_FLAG"

# ── Build ─────────────────────────────────────────────────────────────────────
if [ "$NO_BUILD" -eq 0 ]; then
  JOBS=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
  info "Building with $JOBS parallel jobs ..."
  cmake --build "$BUILD_DIR" -- -j"$JOBS"
fi

# ── Report ────────────────────────────────────────────────────────────────────
if [ -f "$BIN_PATH" ]; then
  info "Build succeeded."
  info "Binary: $BIN_PATH"
else
  echo "WARNING: Build finished but nlink was not found at $BIN_PATH — check $BUILD_DIR/bin/" >&2
fi
