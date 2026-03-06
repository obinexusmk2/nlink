# =============================================================================
# OBINexus NexusLink - Cross-Platform Build System
# Toolchain : MinGW-w64 / GCC  (Windows)  or  gcc  (Linux / WSL)
# Primary   : ./bin/nlink.exe   (Windows)  or  ./bin/nlink  (Linux)
# =============================================================================

# ── Directory layout  (defined FIRST so TARGET below can reference them) ─────
SRC_DIR := src
BIN_DIR := bin

BUILD_REL_OBJ := build/release/obj
BUILD_REL_LIB := build/release/lib

BUILD_DBG_OBJ := build/debug/obj
BUILD_DBG_LIB := build/debug/lib
BUILD_DBG_BIN := build/debug/bin

# ── Windows path helper (/ -> \) ──────────────────────────────────────────────
winpath = $(subst /,\,$1)

# ── Platform detection ────────────────────────────────────────────────────────
ifeq ($(OS),Windows_NT)
  SHELL        := cmd.exe
  .SHELLFLAGS  := /c
  MKDIR_P       = if not exist "$(call winpath,$1)" md "$(call winpath,$1)"
  RM_RF         = if exist "$(call winpath,$1)" rd /s /q "$(call winpath,$1)"
  EXE_SUFFIX   := .exe
  FEATURES_CMD  = @for %%f in ($(FEATURES)) do @echo   %%f
  POC_COPY      = @copy scripts\python_bridge.py poc\ >nul 2>&1 || echo   (python_bridge.py not found)
  POC_RUN       = python poc\python_bridge.py
else
  SHELL        := /bin/bash
  .SHELLFLAGS  := -c
  MKDIR_P       = mkdir -p "$1"
  RM_RF         = rm -rf "$1"
  EXE_SUFFIX   :=
  FEATURES_CMD  = @for f in $(FEATURES); do echo "  $$f"; done
  POC_COPY      = @cp scripts/python_bridge.py poc/ 2>/dev/null || echo "  (python_bridge.py not found)"
  POC_RUN       = python3 poc/python_bridge.py
endif

# ── Primary targets (deferred = avoids empty-BIN_DIR expansion at parse time) ─
TARGET     = $(BIN_DIR)/nlink$(EXE_SUFFIX)
DBG_TARGET = $(BUILD_DBG_BIN)/nlink$(EXE_SUFFIX)

# ── Toolchain ─────────────────────────────────────────────────────────────────
CC  := gcc
CXX := g++
AR  := ar

# ── Compiler flags ────────────────────────────────────────────────────────────
# -iquote./include : project shim headers (fnmatch.h etc.) win over system ones
# -I./include      : all nlink/core/... public headers (absolute form)
# -I./src/core     : source-local headers (tokenizer.h, parser.h, etc.)
# No -fPIC on Windows (not required for PE/COFF targets)
CFLAGS_COMMON   := -Wall -Wextra -Wpedantic \
                   -iquote./include -I./include -I./src/core \
                   -std=c11
CXXFLAGS_COMMON := -Wall -Wextra -Wpedantic \
                   -iquote./include -I./include -I./src/core \
                   -std=c++17

CFLAGS_DEBUG   := $(CFLAGS_COMMON) -g -O0 -DDEBUG
CFLAGS_RELEASE := $(CFLAGS_COMMON) -O2 -DNDEBUG -ffunction-sections -fdata-sections

CRYPTO_FLAGS := -DSHANNON_ENTROPY_ENABLED=1

# Environment target overrides
dev:  CFLAGS_RELEASE += -DNLINK_ENV=dev  -DSHANNON_STRICT_MODE=1
prod: CFLAGS_RELEASE += -DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1

# ── Feature modules ───────────────────────────────────────────────────────────
FEATURES := semverx parser schema minimizer etps symbols pipeline cli tatit mpsystem spsystem

# ── Source collection ─────────────────────────────────────────────────────────
CORE_SOURCES   := $(foreach f,$(FEATURES),$(wildcard $(SRC_DIR)/core/$(f)/*.c))
CRYPTO_SOURCES := \
    src/core/crypto/shannon_entropy.c \
    src/core/crypto/env_config.c
CLI_MAIN       := $(SRC_DIR)/cli/main.c
CLI_SOURCES    := $(filter-out $(CLI_MAIN),$(wildcard $(SRC_DIR)/cli/*.c))
ALL_SOURCES    := $(CORE_SOURCES) $(CRYPTO_SOURCES) $(CLI_SOURCES) $(CLI_MAIN)

# ── Object file lists ─────────────────────────────────────────────────────────
OBJECTS_REL := $(patsubst $(SRC_DIR)/%.c,$(BUILD_REL_OBJ)/%.o,$(ALL_SOURCES))
OBJECTS_DBG := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DBG_OBJ)/%.o,$(ALL_SOURCES))

# ── Static libraries ──────────────────────────────────────────────────────────
LIB_REL := $(BUILD_REL_LIB)/nlink.a
LIB_DBG := $(BUILD_DBG_LIB)/nlink.a

# ── Phony targets ─────────────────────────────────────────────────────────────
.PHONY: all debug release clean cmake-reset features help dev prod \
        etps-test etps-config-test qa-test qa-validate \
        poc poc-setup spec spec-run

.DEFAULT_GOAL := release

# =============================================================================
# ALL
# =============================================================================
all: debug release

# =============================================================================
# RELEASE  →  ./bin/nlink[.exe]                              [DEFAULT]
# =============================================================================
release: $(TARGET)

$(TARGET): $(BUILD_REL_OBJ)/cli/main.o $(LIB_REL)
	$(call MKDIR_P,$(BIN_DIR))
	$(CC) $(CFLAGS_RELEASE) -o $@ $(BUILD_REL_OBJ)/cli/main.o \
	    -L$(BUILD_REL_LIB) -lnlink -Wl,--gc-sections
	@echo [nlink] Release complete: $@

$(BUILD_REL_OBJ)/%.o: $(SRC_DIR)/%.c
	$(call MKDIR_P,$(dir $@))
	$(CC) $(CFLAGS_RELEASE) $(CRYPTO_FLAGS) -c $< -o $@

$(LIB_REL): $(filter-out $(BUILD_REL_OBJ)/cli/main.o,$(OBJECTS_REL))
	$(call MKDIR_P,$(BUILD_REL_LIB))
	$(AR) rcs $@ $^

# =============================================================================
# DEBUG  →  build/debug/bin/nlink[.exe]
# =============================================================================
debug: $(DBG_TARGET)

$(DBG_TARGET): $(BUILD_DBG_OBJ)/cli/main.o $(LIB_DBG)
	$(call MKDIR_P,$(BUILD_DBG_BIN))
	$(CC) $(CFLAGS_DEBUG) -o $@ $(BUILD_DBG_OBJ)/cli/main.o \
	    -L$(BUILD_DBG_LIB) -lnlink
	@echo [nlink] Debug complete: $@

$(BUILD_DBG_OBJ)/%.o: $(SRC_DIR)/%.c
	$(call MKDIR_P,$(dir $@))
	$(CC) $(CFLAGS_DEBUG) $(CRYPTO_FLAGS) -c $< -o $@

$(LIB_DBG): $(filter-out $(BUILD_DBG_OBJ)/cli/main.o,$(OBJECTS_DBG))
	$(call MKDIR_P,$(BUILD_DBG_LIB))
	$(AR) rcs $@ $^

# =============================================================================
# QA / TESTING
# =============================================================================
qa-test: debug
	@echo [nlink] Running QA Soundness Tests...
	@echo   TP: True Positive  tests
	@echo   TN: True Negative  tests
	@echo   FP: False Positive tests  (MUST BE ZERO)
	@echo   FN: False Negative tests
	$(DBG_TARGET) --qa-validate

etps-test: debug
	@echo [nlink] Testing ETPS Telemetry...
	$(DBG_TARGET) --etps-test --json

etps-config-test: $(TARGET)
	@echo [nlink] Testing ETPS with configuration...
	$(TARGET) --etps-test --config config/nlink.conf --json

qa-validate: poc spec-run
	@echo [nlink] QA validation complete.

# =============================================================================
# POC  (Python bridge)
# =============================================================================
poc-setup:
	@echo [nlink] Setting up POC environment...
	$(call MKDIR_P,poc)
	$(POC_COPY)
	@echo [nlink] POC environment ready.

poc: poc-setup
	@echo [nlink] Running POC integration...
	$(POC_RUN)

# =============================================================================
# SPEC / DOCUMENTATION FRAMEWORK
# =============================================================================
spec:
	@echo [nlink] Building QA specification framework...
	$(MAKE) -C spec all

spec-run: spec
	@echo [nlink] Executing QA specifications...
	$(MAKE) -C spec run

# =============================================================================
# FEATURE LISTING
# =============================================================================
features:
	@echo NexusLink Features:
	$(FEATURES_CMD)

# =============================================================================
# CLEAN
# =============================================================================
clean:
	$(call RM_RF,build)
	$(call RM_RF,bin)
	@echo [nlink] Clean complete.

# cmake-reset: wipe CMake cache — required when switching Windows <-> WSL
cmake-reset:
ifeq ($(OS),Windows_NT)
	@if exist build\CMakeCache.txt del /q build\CMakeCache.txt
	@if exist build\CMakeFiles     rd /s /q build\CMakeFiles
	@if exist CMakeCache.txt       del /q CMakeCache.txt
	@if exist CMakeFiles           rd /s /q CMakeFiles
else
	@rm -f build/CMakeCache.txt CMakeCache.txt
	@rm -rf build/CMakeFiles CMakeFiles
endif
	@echo [nlink] CMake cache cleared.
	@echo [nlink] Windows: cmake -S . -B build -G "MinGW Makefiles"
	@echo [nlink] Linux:   cmake -S . -B build -G "Unix Makefiles"

# =============================================================================
# HELP
# =============================================================================
help:
	@echo
	@echo  OBINexus NexusLink -- Cross-Platform Build System
	@echo  ==================================================
	@echo  Targets:
	@echo    release          Build optimised ./bin/nlink[.exe]   [DEFAULT]
	@echo    debug            Build debug     build/debug/bin/nlink[.exe]
	@echo    all              Build both release and debug
	@echo    clean            Remove build/ and bin/ trees
	@echo    cmake-reset      Wipe CMakeCache (Windows-to-WSL or vice versa)
	@echo    features         List all feature modules
	@echo    etps-test        Run ETPS telemetry smoke-test (debug)
	@echo    etps-config-test Run ETPS test with config file (release)
	@echo    qa-test          Run TP/TN/FP/FN QA validation (debug)
	@echo    qa-validate      Run POC + spec validation suite
	@echo    poc              Run Python POC integration bridge
	@echo    spec             Build QA specification framework
	@echo    spec-run         Execute QA specifications
	@echo
	@echo  Environment variants:
	@echo    make dev         -DNLINK_ENV=dev  -DSHANNON_STRICT_MODE=1
	@echo    make prod        -DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1
	@echo
	@echo  Requirements: gcc, g++, ar on PATH
	@echo    Windows: MinGW-w64  (C:/MinGW/bin or MSYS2)
	@echo    Linux:   sudo apt install build-essential
	@echo
