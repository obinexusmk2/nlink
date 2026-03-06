# =============================================================================
# OBINexus NexusLink - Windows Build System
# Toolchain : MinGW-w64 / GCC  (MSYS2 or standalone MinGW on PATH)
# Shell     : cmd.exe  (GNU Make for Windows)
# Primary   : ./bin/nlink.exe
# =============================================================================

SHELL       := cmd.exe
.SHELLFLAGS := /c

# ── Toolchain ─────────────────────────────────────────────────────────────────
CC  := gcc
CXX := g++
AR  := ar

# ── Compiler flags (no -fPIC on Windows) ─────────────────────────────────────
CFLAGS_COMMON   := -Wall -Wextra -Wpedantic -I./include -std=c11
CXXFLAGS_COMMON := -Wall -Wextra -Wpedantic -I./include -std=c++17

CFLAGS_DEBUG   := $(CFLAGS_COMMON) -g -O0 -DDEBUG
CFLAGS_RELEASE := $(CFLAGS_COMMON) -O2 -DNDEBUG -ffunction-sections -fdata-sections

CRYPTO_FLAGS := -DSHANNON_ENTROPY_ENABLED=1

# Environment target overrides
dev:  CFLAGS_RELEASE += -DNLINK_ENV=dev  -DSHANNON_STRICT_MODE=1
prod: CFLAGS_RELEASE += -DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1

# ── Directory layout ──────────────────────────────────────────────────────────
SRC_DIR := src
BIN_DIR := bin

BUILD_REL_OBJ := build/release/obj
BUILD_REL_LIB := build/release/lib

BUILD_DBG_OBJ := build/debug/obj
BUILD_DBG_LIB := build/debug/lib
BUILD_DBG_BIN := build/debug/bin

# ── Primary Windows target ────────────────────────────────────────────────────
TARGET := $(BIN_DIR)/nlink.exe

# ── Feature modules ───────────────────────────────────────────────────────────
FEATURES := semverx parser schema minimizer etps symbols pipeline cli tatit mpsystem spsystem

# ── Source collection ─────────────────────────────────────────────────────────
CORE_SOURCES   := $(foreach f,$(FEATURES),$(wildcard $(SRC_DIR)/core/$(f)/*.c))
CRYPTO_SOURCES := \
    src/core/crypto/shannon_entropy.c \
    src/core/crypto/env_config.c
CLI_SOURCES    := $(wildcard $(SRC_DIR)/cli/*.c)
ALL_SOURCES    := $(CORE_SOURCES) $(CRYPTO_SOURCES) $(CLI_SOURCES) $(SRC_DIR)/main.c

# ── Object file lists ─────────────────────────────────────────────────────────
OBJECTS_REL := $(patsubst $(SRC_DIR)/%.c,$(BUILD_REL_OBJ)/%.o,$(ALL_SOURCES))
OBJECTS_DBG := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DBG_OBJ)/%.o,$(ALL_SOURCES))

# ── Static libraries ──────────────────────────────────────────────────────────
LIB_REL := $(BUILD_REL_LIB)/nlink.a
LIB_DBG := $(BUILD_DBG_LIB)/nlink.a

# ── Windows path helper (/ -> \) ──────────────────────────────────────────────
winpath = $(subst /,\,$1)

# ── Phony targets ─────────────────────────────────────────────────────────────
.PHONY: all debug release clean features help dev prod \
        etps-test etps-config-test qa-test qa-validate \
        poc poc-setup spec spec-run

.DEFAULT_GOAL := release

# =============================================================================
# ALL
# =============================================================================
all: debug release

# =============================================================================
# RELEASE  →  ./bin/nlink.exe                               [DEFAULT]
# =============================================================================
release: $(TARGET)

$(TARGET): $(BUILD_REL_OBJ)/main.o $(LIB_REL)
	@if not exist "$(call winpath,$(BIN_DIR))" md "$(call winpath,$(BIN_DIR))"
	$(CC) $(CFLAGS_RELEASE) -o $@ $(BUILD_REL_OBJ)/main.o \
	    -L$(BUILD_REL_LIB) -lnlink -Wl,--gc-sections
	@echo [nlink] Release complete: $@

# Release objects
$(BUILD_REL_OBJ)/%.o: $(SRC_DIR)/%.c
	@if not exist "$(call winpath,$(dir $@))" md "$(call winpath,$(dir $@))"
	$(CC) $(CFLAGS_RELEASE) $(CRYPTO_FLAGS) -c $< -o $@

# Release static library
$(LIB_REL): $(filter-out $(BUILD_REL_OBJ)/main.o,$(OBJECTS_REL))
	@if not exist "$(call winpath,$(BUILD_REL_LIB))" md "$(call winpath,$(BUILD_REL_LIB))"
	$(AR) rcs $@ $^

# =============================================================================
# DEBUG  →  build/debug/bin/nlink.exe
# =============================================================================
debug: $(BUILD_DBG_BIN)/nlink.exe

$(BUILD_DBG_BIN)/nlink.exe: $(BUILD_DBG_OBJ)/main.o $(LIB_DBG)
	@if not exist "$(call winpath,$(BUILD_DBG_BIN))" md "$(call winpath,$(BUILD_DBG_BIN))"
	$(CC) $(CFLAGS_DEBUG) -o $@ $(BUILD_DBG_OBJ)/main.o \
	    -L$(BUILD_DBG_LIB) -lnlink
	@echo [nlink] Debug complete: $@

# Debug objects
$(BUILD_DBG_OBJ)/%.o: $(SRC_DIR)/%.c
	@if not exist "$(call winpath,$(dir $@))" md "$(call winpath,$(dir $@))"
	$(CC) $(CFLAGS_DEBUG) $(CRYPTO_FLAGS) -c $< -o $@

# Debug static library
$(LIB_DBG): $(filter-out $(BUILD_DBG_OBJ)/main.o,$(OBJECTS_DBG))
	@if not exist "$(call winpath,$(BUILD_DBG_LIB))" md "$(call winpath,$(BUILD_DBG_LIB))"
	$(AR) rcs $@ $^

# =============================================================================
# QA / TESTING
# =============================================================================

# QA soundness validation (TP / TN / FP / FN)
qa-test: debug
	@echo [nlink] Running QA Soundness Tests...
	@echo   TP: True Positive  tests
	@echo   TN: True Negative  tests
	@echo   FP: False Positive tests  (MUST BE ZERO)
	@echo   FN: False Negative tests
	$(BUILD_DBG_BIN)/nlink.exe --qa-validate

# ETPS telemetry smoke-test
etps-test: debug
	@echo [nlink] Testing ETPS Telemetry...
	$(BUILD_DBG_BIN)/nlink.exe --etps-test --json

# ETPS telemetry with config file
etps-config-test: $(TARGET)
	@echo [nlink] Testing ETPS with configuration...
	$(TARGET) --etps-test --config config/nlink.conf --json

# Combined QA validation
qa-validate: poc spec-run
	@echo [nlink] QA validation complete.

# =============================================================================
# POC  (Python bridge — requires python on PATH)
# =============================================================================
poc-setup:
	@echo [nlink] Setting up POC environment...
	@if not exist poc md poc
	@copy scripts\python_bridge.py poc\ >nul 2>&1 || echo   (python_bridge.py not found)
	@echo [nlink] POC environment ready.

poc: poc-setup
	@echo [nlink] Running POC integration...
	python poc\python_bridge.py

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
	@for %%f in ($(FEATURES)) do @echo   %%f

# =============================================================================
# CLEAN
# =============================================================================
clean:
	@if exist build rd /s /q build
	@if exist bin   rd /s /q bin
	@echo [nlink] Clean complete.

# =============================================================================
# HELP
# =============================================================================
help:
	@echo.
	@echo  OBINexus NexusLink -- Windows Build System (MinGW-w64 / GCC)
	@echo  ==============================================================
	@echo  Targets:
	@echo    release        Build optimised  .\bin\nlink.exe        [DEFAULT]
	@echo    debug          Build debug      build\debug\bin\nlink.exe
	@echo    all            Build both release and debug
	@echo    clean          Remove build\ and bin\ trees
	@echo    features       List all feature modules
	@echo    etps-test      Run ETPS telemetry smoke-test (debug)
	@echo    etps-config-test  Run ETPS test with config file (release)
	@echo    qa-test        Run TP/TN/FP/FN QA validation (debug)
	@echo    qa-validate    Run POC + spec validation suite
	@echo    poc            Run Python POC integration bridge
	@echo    spec           Build QA specification framework
	@echo    spec-run       Execute QA specifications
	@echo.
	@echo  Environment variants:
	@echo    make dev       dev  flags  (-DNLINK_ENV=dev  -DSHANNON_STRICT_MODE=1)
	@echo    make prod      prod flags  (-DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1)
	@echo.
	@echo  Requirements: MinGW-w64 gcc, g++, ar  on PATH
	@echo.
