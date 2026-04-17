/**
 * @file parse.c
 * @brief Implementation of the parse command for NexusLink CLI
 *
 * Defines the `parse_command` global NexusCommand used by
 * command_registration.c to register parse patterns with the router.
 *
 * Copyright © 2025 OBINexus Computing
 */

#include "nlink/core/common/command.h"
#include "nlink/core/common/nexus_core.h"
#include "nlink/core/common/result.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declarations */
static int  parse_execute(NexusContext* ctx, int argc, char** argv);
static void parse_print_help(void);

/* ------------------------------------------------------------------ */
/* Global command object (referenced via extern in command_registration.c) */
/* ------------------------------------------------------------------ */

NexusCommand parse_command = {
    .name               = "parse",
    .short_name         = NULL,
    .description        = "Parse a source file or token stream",
    .help               = NULL,
    .handler            = NULL,
    .handler_with_params= NULL,
    .parse_args         = NULL,
    .print_help         = parse_print_help,
    .execute            = parse_execute,
    .free_data          = NULL,
    .data               = NULL
};

/* ------------------------------------------------------------------ */
/* Implementations                                                      */
/* ------------------------------------------------------------------ */

static int parse_execute(NexusContext* ctx, int argc, char** argv) {
    if (!ctx) {
        fprintf(stderr, "Error: invalid context\n");
        return 1;
    }
    if (argc < 1) {
        fprintf(stderr, "Usage: parse <input> [to <output>]\n");
        return 1;
    }

    const char* input  = argv[0];
    const char* output = (argc >= 3 && strcmp(argv[1], "to") == 0) ? argv[2] : NULL;

    printf("Parsing: %s", input);
    if (output) printf(" -> %s", output);
    printf("\n");

    /* Stub: real implementation would call the parser subsystem */
    return 0;
}

static void parse_print_help(void) {
    printf("Usage: parse <input> [to <output>]\n\n");
    printf("Arguments:\n");
    printf("  input    Path to the input file to parse\n");
    printf("  output   Optional output path for the parse result\n");
    printf("\nExamples:\n");
    printf("  parse myfile.c\n");
    printf("  parse myfile.c to result.json\n");
}
