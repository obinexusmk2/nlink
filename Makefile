# NexusLink (NLink) Makefile
# Author: Nnamdi Michael Okpala
# Magnetic Osmotic Nexus Linker — Link by Need

# Directory structure
PROJECT_ROOT := $(CURDIR)
SRC_DIR := $(PROJECT_ROOT)/src
INCLUDE_DIR := $(PROJECT_ROOT)/include
BUILD_DIR := $(PROJECT_ROOT)/build
CMAKE_BUILD_DIR := $(BUILD_DIR)/cmake

# Cross-platform detection
ifeq ($(OS),Windows_NT)
  BINARY  := $(CMAKE_BUILD_DIR)/bin/nlink.exe
  RM_RF   := cmd /c "if exist "$(BUILD_DIR)" rd /s /q "$(BUILD_DIR)""
else
  BINARY  := $(CMAKE_BUILD_DIR)/bin/nlink
  RM_RF   := rm -rf $(BUILD_DIR)
endif
MKDIR_P := cmake -E make_directory

# Default options
CMAKE_OPTIONS := -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON

# Default target
.PHONY: all
all: build

# Create build directories
$(BUILD_DIR):
	$(MKDIR_P) $(BUILD_DIR)

$(CMAKE_BUILD_DIR): | $(BUILD_DIR)
	$(MKDIR_P) $(CMAKE_BUILD_DIR)

# Configure with CMake
.PHONY: configure
configure: | $(CMAKE_BUILD_DIR)
	cd $(CMAKE_BUILD_DIR) && cmake $(CMAKE_OPTIONS) $(PROJECT_ROOT)

# Build the project
.PHONY: build
build: configure
	cd $(CMAKE_BUILD_DIR) && cmake --build .

# Build in debug mode
.PHONY: debug
debug:
	$(MAKE) build CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON"

# Build in release mode
.PHONY: release
release:
	$(MAKE) build CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON"

# Dev environment build (strict entropy validation)
.PHONY: dev
dev:
	$(MAKE) build CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DNLINK_ENV=dev -DSHANNON_STRICT_MODE=1"

# Prod environment build (performance-optimised entropy processing)
.PHONY: prod
prod:
	$(MAKE) build CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1"

# Run tests
.PHONY: test
test: build
	cd $(CMAKE_BUILD_DIR) && ctest --output-on-failure

# Run all tests with custom target
.PHONY: run-tests
run-tests: build
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target run_all_tests

# Clean build artifacts
.PHONY: clean
clean:
	$(RM_RF)

# Reset CMake cache (use before switching between Windows and WSL)
.PHONY: cmake-reset
cmake-reset:
	cmake -E rm -f $(CMAKE_BUILD_DIR)/CMakeCache.txt
	cmake -E rm -rf $(CMAKE_BUILD_DIR)/CMakeFiles

# Install the library and headers
.PHONY: install
install: build
	cd $(CMAKE_BUILD_DIR) && cmake --install .

# Generate docs
.PHONY: docs
docs: build
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target docs

# Validate include paths
.PHONY: validate-includes
validate-includes: build
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target validate_includes

# Fix include paths
.PHONY: fix-includes
fix-includes: build
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target fix_includes

# Create packages
.PHONY: package
package: build
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target package

# Create source packages
.PHONY: package-source
package-source: configure
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target package_source

# Complete development cycle
.PHONY: dev-cycle
dev-cycle: build
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target dev_cycle

# Check code style with clang-format
.PHONY: check-style
check-style:
	find $(SRC_DIR) $(INCLUDE_DIR) -name "*.c" -o -name "*.h" | xargs clang-format -i

# Build with coverage instrumentation
.PHONY: coverage
coverage:
	$(MAKE) build CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DENABLE_COVERAGE=ON"
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target coverage

# List all feature modules
.PHONY: features
features:
	@echo "NexusLink Feature Modules:"
	@for comp in $(shell ls $(SRC_DIR)/core); do \
		echo "  $$comp"; \
	done

# ETPS telemetry smoke test (uses debug binary)
.PHONY: etps-test
etps-test: build
	$(BINARY) --etps-test --json

# ETPS telemetry test with config file (uses release binary)
.PHONY: etps-config-test
etps-config-test: build
	$(BINARY) --etps-test --config nlink.conf --json

# TP/TN/FP/FN QA soundness validation
.PHONY: qa-test
qa-test: build
	$(BINARY) --qa-test

# POC + spec validation suite
.PHONY: qa-validate
qa-validate: build
	$(BINARY) --qa-validate

# Run Python bridge / POC integration
.PHONY: poc
poc: build
	$(MAKE) -C $(PROJECT_ROOT)/poc/nlink_enhanced

# Build QA specification framework
.PHONY: spec
spec: build
	cd $(CMAKE_BUILD_DIR) && cmake --build . --target spec || echo "No spec target defined — build first then run spec-run"

# Execute QA specifications
.PHONY: spec-run
spec-run: spec
	$(BINARY) --spec-run

# Show help
.PHONY: help
help:
	@echo "NexusLink Makefile targets:"
	@echo "  all               - Build the project (default)"
	@echo "  configure         - Configure the build system"
	@echo "  build             - Build the project"
	@echo "  debug             - Build in debug mode"
	@echo "  release           - Build in release mode"
	@echo "  dev               - Build with dev env (-DNLINK_ENV=dev -DSHANNON_STRICT_MODE=1)"
	@echo "  prod              - Build with prod env (-DNLINK_ENV=prod -DSHANNON_PERFORMANCE_MODE=1)"
	@echo "  test              - Run tests"
	@echo "  run-tests         - Run all tests (run_all_tests target)"
	@echo "  clean             - Remove all build artifacts"
	@echo "  cmake-reset       - Reset CMake cache (use when switching Windows/WSL)"
	@echo "  install           - Install the library and headers"
	@echo "  docs              - Generate documentation"
	@echo "  validate-includes - Validate include paths"
	@echo "  fix-includes      - Fix include paths"
	@echo "  package           - Create binary packages"
	@echo "  package-source    - Create source packages"
	@echo "  dev-cycle         - Run the complete development cycle"
	@echo "  check-style       - Check code style with clang-format"
	@echo "  coverage          - Build with coverage instrumentation"
	@echo "  features          - List all feature modules"
	@echo "  etps-test         - ETPS telemetry smoke test (JSON output)"
	@echo "  etps-config-test  - ETPS telemetry test with config file"
	@echo "  qa-test           - TP/TN/FP/FN QA soundness validation"
	@echo "  qa-validate       - POC + spec validation suite"
	@echo "  poc               - Run POC enhanced integration build"
	@echo "  spec              - Build QA specification framework"
	@echo "  spec-run          - Execute QA specifications"

# Components
.PHONY: components
components:
	@for comp in $(shell ls $(SRC_DIR)/core); do \
		echo "$$comp"; \
	done
