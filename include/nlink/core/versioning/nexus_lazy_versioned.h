#ifndef NEXUS_LAZY_VERSIONED_H
#define NEXUS_LAZY_VERSIONED_H

#include <time.h>
#include <pthread.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include "nlink/core/common/nexus_core.h"
#include "nlink/core/symbols/nexus_versioned_symbols.h"

// Version information structure
typedef struct {
	char* resolved_version;
	char* providing_component;
	bool is_exact_match;
} VersionInfo;

// Function declarations
void nexus_check_unused_versioned_libraries(VersionedSymbolRegistry* registry);
void nexus_print_symbol_version_info(const char* symbol_name, const VersionInfo* info);
const char* nexus_get_component_version_constraint(
	VersionedSymbolRegistry* registry,
	const char* symbol_name,
	const char* component_id,
	const char* default_constraint
);
void nexus_track_symbol_usage_versioned(
	VersionedSymbolRegistry* registry,
	const char* symbol_name,
	const char* version,
	const char* using_component
);

#endif // NEXUS_LAZY_VERSIONED_H
