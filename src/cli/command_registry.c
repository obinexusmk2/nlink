/**
 * @file command_registry.c
 * @brief CLI command registry implementation for NexusLink
 *
 * Provides the CliCommandRegistry (simple array-based) and
 * the nlink_command_router_find_commands helper.
 *
 * Note: nlink_command_router_* functions (create, register, execute,
 * destroy) are implemented in command_router.c.
 *
 * Copyright © 2025 OBINexus Computing
 */

#include "nlink/cli/command_registry.h"
#include "nlink/cli/command_params.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ------------------------------------------------------------------ */
/* CliCommandRegistry — simple array-based registry                   */
/* ------------------------------------------------------------------ */

#define CLI_REGISTRY_INITIAL_CAPACITY 16

bool cli_command_registry_init(CliCommandRegistry* registry) {
    if (!registry) return false;

    registry->commands = (NexusCommand**)malloc(
        CLI_REGISTRY_INITIAL_CAPACITY * sizeof(NexusCommand*));
    if (!registry->commands) return false;

    registry->count    = 0;
    registry->capacity = CLI_REGISTRY_INITIAL_CAPACITY;
    return true;
}

bool cli_command_registry_register(CliCommandRegistry* registry, NexusCommand* command) {
    if (!registry || !command) return false;

    /* Grow if needed */
    if (registry->count >= registry->capacity) {
        size_t new_cap = registry->capacity * 2;
        NexusCommand** tmp = (NexusCommand**)realloc(
            registry->commands, new_cap * sizeof(NexusCommand*));
        if (!tmp) return false;
        registry->commands = tmp;
        registry->capacity = new_cap;
    }

    registry->commands[registry->count++] = command;
    return true;
}

NexusCommand* cli_command_registry_find(CliCommandRegistry* registry, const char* name) {
    if (!registry || !name) return NULL;

    for (size_t i = 0; i < registry->count; i++) {
        NexusCommand* cmd = registry->commands[i];
        if (cmd && cmd->name && strcmp(cmd->name, name) == 0) {
            return cmd;
        }
        /* Also check short_name */
        if (cmd && cmd->short_name && strcmp(cmd->short_name, name) == 0) {
            return cmd;
        }
    }
    return NULL;
}

int cli_command_registry_execute(CliCommandRegistry* registry,
                                 NexusContext* ctx,
                                 const char* name,
                                 int argc, char** argv) {
    if (!registry || !ctx || !name) return -1;

    NexusCommand* cmd = cli_command_registry_find(registry, name);
    if (!cmd) {
        fprintf(stderr, "Error: command '%s' not found\n", name);
        return -1;
    }

    if (cmd->execute) {
        return cmd->execute(ctx, argc, argv);
    }
    if (cmd->handler) {
        NexusResult r = cmd->handler(ctx);
        return (r == NEXUS_SUCCESS) ? 0 : (int)r;
    }
    fprintf(stderr, "Error: command '%s' has no handler\n", name);
    return -1;
}

void cli_command_registry_list(CliCommandRegistry* registry) {
    if (!registry) return;

    printf("Registered commands (%zu):\n", registry->count);
    for (size_t i = 0; i < registry->count; i++) {
        NexusCommand* cmd = registry->commands[i];
        if (cmd) {
            printf("  %-15s %s\n",
                   cmd->name        ? cmd->name        : "(unnamed)",
                   cmd->description ? cmd->description : "");
        }
    }
}

void cli_command_registry_cleanup(CliCommandRegistry* registry) {
    if (!registry) return;
    /* Commands are owned by their defining modules; we just free the array */
    free(registry->commands);
    registry->commands = NULL;
    registry->count    = 0;
    registry->capacity = 0;
}

/* ------------------------------------------------------------------ */
/* nlink_command_router_find_commands                                  */
/* ------------------------------------------------------------------ */

size_t nlink_command_router_find_commands(
    struct NlinkCommandRouter* router,
    const char* pattern,
    NexusCommand** commands,
    size_t max_commands)
{
    if (!router || !pattern || !commands || max_commands == 0) {
        return 0;
    }

    for (size_t i = 0; i < max_commands; i++) {
        commands[i] = NULL;
    }

    if (strlen(pattern) == 0) {
        return 0;
    }

    NlinkPatternFlags flags = NLINK_PATTERN_FLAG_CASE_INSENSITIVE;
    if (strchr(pattern, '*') || strchr(pattern, '?')) {
        flags |= NLINK_PATTERN_FLAG_GLOB;
    } else {
        flags |= NLINK_PATTERN_FLAG_REGEX;
    }

    NlinkPatternMatcher* matcher = nlink_pattern_create(pattern, flags);
    if (!matcher) {
        return 0;
    }

    size_t found = 0;
    NlinkCommandRoute* route = router->routes;

    while (route && found < max_commands) {
        NexusCommand* cmd = route->command;
        if (cmd && cmd->name) {
            if (nlink_pattern_match(matcher, cmd->name)) {
                commands[found++] = cmd;
            }
        }
        route = route->next;
    }

    nlink_pattern_destroy(matcher);
    return found;
}
