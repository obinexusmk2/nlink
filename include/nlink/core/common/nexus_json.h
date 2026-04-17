// nexus_json.h - Minimal JSON parser for NexusLink
#ifndef NEXUS_JSON_H
#define NEXUS_JSON_H

#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <stdbool.h>

// JSON value types
typedef enum {
    NEXUS_JSON_NULL,
    NEXUS_JSON_BOOL,
    NEXUS_JSON_NUMBER,
    NEXUS_JSON_STRING,
    NEXUS_JSON_ARRAY,
    NEXUS_JSON_OBJECT
} NexusJsonType;

// JSON value structure
typedef struct NexusJsonValue {
    NexusJsonType type;
    union {
        bool boolean;
        double number;
        char* string;
        struct {
            struct NexusJsonValue** items;
            size_t count;
        } array;
        struct {
            char** keys;
            struct NexusJsonValue** values;
            size_t count;
        } object;
    } data;
} NexusJsonValue;

// Function declarations only
// Create JSON values
extern NexusJsonValue* nexus_json_null(void);
extern NexusJsonValue* nexus_json_bool(bool b);
extern NexusJsonValue* nexus_json_number(double n);
extern NexusJsonValue* nexus_json_string(const char* s);
extern NexusJsonValue* nexus_json_array(void);
extern NexusJsonValue* nexus_json_object(void);

// Array and object manipulation
extern void nexus_json_array_add(NexusJsonValue* array, NexusJsonValue* item);
extern void nexus_json_object_add(NexusJsonValue* object, const char* key, NexusJsonValue* value);

// Object access
extern NexusJsonValue* nexus_json_object_get(NexusJsonValue* object, const char* key);
extern const char* nexus_json_object_get_string(NexusJsonValue* object, const char* key, const char* default_value);
extern double nexus_json_object_get_number(NexusJsonValue* object, const char* key, double default_value);
extern bool nexus_json_object_get_bool(NexusJsonValue* object, const char* key, bool default_value);

// Memory management
extern void nexus_json_free(NexusJsonValue* value);

// Parsing
extern const char* nexus_json_skip_whitespace(const char* s);
extern const char* nexus_json_parse_string(const char* s, char** out);
extern const char* nexus_json_parse_number(const char* s, NexusJsonValue** out);
extern const char* nexus_json_parse_array(const char* s, NexusJsonValue** out);
extern const char* nexus_json_parse_object(const char* s, NexusJsonValue** out);
extern const char* nexus_json_parse_value(const char* s, NexusJsonValue** out);
extern NexusJsonValue* nexus_json_parse(const char* json);
extern NexusJsonValue* nexus_json_parse_file(const char* filename);

// Output
#ifndef NEXUS_JSON_IMPLEMENTATION
extern void nexus_json_write_to_string(const NexusJsonValue* value, char** out, size_t* length, size_t* capacity, int indent, int current_indent);
extern char* nexus_json_to_string(const NexusJsonValue* value, bool pretty);
extern bool nexus_json_write_file(const NexusJsonValue* value, const char* filename, bool pretty);
#endif


/* Compatibility aliases for older API used by sps_config and similar callers */
typedef NexusJsonValue NexusJsonDocument;
typedef NexusJsonValue NexusJsonObject;
typedef NexusJsonValue NexusJsonArray;

#define nexus_json_create_object()         nexus_json_object()
#define nexus_json_create_array()          nexus_json_array()
#define nexus_json_array_append(arr, item) nexus_json_array_add((arr), (item))
#define nexus_json_set_string(obj, key, val) \
    nexus_json_object_add((obj), (key), nexus_json_string(val))
#define nexus_json_set_bool(obj, key, val) \
    nexus_json_object_add((obj), (key), nexus_json_bool(val))
#define nexus_json_set_array(obj, key, arr) \
    nexus_json_object_add((obj), (key), (arr))

static inline NexusResult nexus_json_save_file(const NexusJsonValue* value, const char* path) {
    return nexus_json_write_file(value, path, true) ? NEXUS_SUCCESS : NEXUS_IO_ERROR;
}

#endif // NEXUS_JSON_H