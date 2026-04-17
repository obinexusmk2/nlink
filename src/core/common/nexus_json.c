/**
 * @file nexus_json.c
 * @brief Minimal JSON parser implementation for NexusLink
 *
 * Ported from poc/nlink_enhanced/src/nexus_json.c
 * Copyright © 2025 OBINexus Computing
 */
#include "nlink/core/common/nexus_json.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

/* ------------------------------------------------------------------ */
/* Construction helpers                                                 */
/* ------------------------------------------------------------------ */

NexusJsonValue* nexus_json_null(void) {
    NexusJsonValue* v = (NexusJsonValue*)calloc(1, sizeof(NexusJsonValue));
    if (v) v->type = NEXUS_JSON_NULL;
    return v;
}

NexusJsonValue* nexus_json_bool(bool b) {
    NexusJsonValue* v = (NexusJsonValue*)calloc(1, sizeof(NexusJsonValue));
    if (!v) return NULL;
    v->type = NEXUS_JSON_BOOL;
    v->data.boolean = b;
    return v;
}

NexusJsonValue* nexus_json_number(double n) {
    NexusJsonValue* v = (NexusJsonValue*)calloc(1, sizeof(NexusJsonValue));
    if (!v) return NULL;
    v->type = NEXUS_JSON_NUMBER;
    v->data.number = n;
    return v;
}

NexusJsonValue* nexus_json_string(const char* s) {
    NexusJsonValue* v = (NexusJsonValue*)calloc(1, sizeof(NexusJsonValue));
    if (!v) return NULL;
    v->type = NEXUS_JSON_STRING;
    v->data.string = s ? strdup(s) : NULL;
    return v;
}

NexusJsonValue* nexus_json_array(void) {
    NexusJsonValue* v = (NexusJsonValue*)calloc(1, sizeof(NexusJsonValue));
    if (!v) return NULL;
    v->type = NEXUS_JSON_ARRAY;
    return v;
}

NexusJsonValue* nexus_json_object(void) {
    NexusJsonValue* v = (NexusJsonValue*)calloc(1, sizeof(NexusJsonValue));
    if (!v) return NULL;
    v->type = NEXUS_JSON_OBJECT;
    return v;
}

/* ------------------------------------------------------------------ */
/* Mutation helpers                                                     */
/* ------------------------------------------------------------------ */

void nexus_json_array_add(NexusJsonValue* array, NexusJsonValue* item) {
    if (!array || array->type != NEXUS_JSON_ARRAY || !item) return;
    size_t n = array->data.array.count + 1;
    NexusJsonValue** tmp = (NexusJsonValue**)realloc(array->data.array.items,
                                                     n * sizeof(NexusJsonValue*));
    if (!tmp) return;
    array->data.array.items = tmp;
    array->data.array.items[array->data.array.count++] = item;
}

void nexus_json_object_add(NexusJsonValue* object, const char* key, NexusJsonValue* value) {
    if (!object || object->type != NEXUS_JSON_OBJECT || !key || !value) return;
    size_t n = object->data.object.count + 1;
    char** ks = (char**)realloc(object->data.object.keys, n * sizeof(char*));
    NexusJsonValue** vs = (NexusJsonValue**)realloc(object->data.object.values,
                                                     n * sizeof(NexusJsonValue*));
    if (!ks || !vs) return;
    object->data.object.keys   = ks;
    object->data.object.values = vs;
    object->data.object.keys[object->data.object.count]   = strdup(key);
    object->data.object.values[object->data.object.count] = value;
    object->data.object.count++;
}

/* ------------------------------------------------------------------ */
/* Object accessors                                                     */
/* ------------------------------------------------------------------ */

NexusJsonValue* nexus_json_object_get(NexusJsonValue* object, const char* key) {
    if (!object || object->type != NEXUS_JSON_OBJECT || !key) return NULL;
    for (size_t i = 0; i < object->data.object.count; i++) {
        if (strcmp(object->data.object.keys[i], key) == 0)
            return object->data.object.values[i];
    }
    return NULL;
}

const char* nexus_json_object_get_string(NexusJsonValue* object, const char* key, const char* dflt) {
    NexusJsonValue* v = nexus_json_object_get(object, key);
    return (v && v->type == NEXUS_JSON_STRING) ? v->data.string : dflt;
}

double nexus_json_object_get_number(NexusJsonValue* object, const char* key, double dflt) {
    NexusJsonValue* v = nexus_json_object_get(object, key);
    return (v && v->type == NEXUS_JSON_NUMBER) ? v->data.number : dflt;
}

bool nexus_json_object_get_bool(NexusJsonValue* object, const char* key, bool dflt) {
    NexusJsonValue* v = nexus_json_object_get(object, key);
    return (v && v->type == NEXUS_JSON_BOOL) ? v->data.boolean : dflt;
}

/* ------------------------------------------------------------------ */
/* Memory management                                                    */
/* ------------------------------------------------------------------ */

void nexus_json_free(NexusJsonValue* value) {
    if (!value) return;
    switch (value->type) {
        case NEXUS_JSON_STRING:
            free(value->data.string);
            break;
        case NEXUS_JSON_ARRAY:
            for (size_t i = 0; i < value->data.array.count; i++)
                nexus_json_free(value->data.array.items[i]);
            free(value->data.array.items);
            break;
        case NEXUS_JSON_OBJECT:
            for (size_t i = 0; i < value->data.object.count; i++) {
                free(value->data.object.keys[i]);
                nexus_json_free(value->data.object.values[i]);
            }
            free(value->data.object.keys);
            free(value->data.object.values);
            break;
        default:
            break;
    }
    free(value);
}

/* ------------------------------------------------------------------ */
/* Parsing                                                              */
/* ------------------------------------------------------------------ */

const char* nexus_json_skip_whitespace(const char* s) {
    while (s && isspace((unsigned char)*s)) s++;
    return s;
}

const char* nexus_json_parse_string(const char* s, char** out) {
    if (!s || *s != '"') return NULL;
    s++;
    const char* start = s;
    size_t len = 0;
    while (*s && *s != '"') { if (*s == '\\') { s++; if (!*s) return NULL; } s++; len++; }
    if (!*s) return NULL;
    *out = (char*)malloc(len + 1);
    if (!*out) return NULL;
    char* d = *out;
    s = start;
    while (*s && *s != '"') {
        if (*s == '\\') {
            s++;
            switch (*s) {
                case 'n':  *d++ = '\n'; break;
                case 'r':  *d++ = '\r'; break;
                case 't':  *d++ = '\t'; break;
                case '\\': *d++ = '\\'; break;
                case '"':  *d++ = '"';  break;
                default:   *d++ = *s;   break;
            }
        } else { *d++ = *s; }
        s++;
    }
    *d = '\0';
    return s + 1;
}

const char* nexus_json_parse_number(const char* s, NexusJsonValue** out) {
    char* end;
    double n = strtod(s, &end);
    if (end == s) return NULL;
    *out = nexus_json_number(n);
    return end;
}

/* Forward declarations for mutual recursion */
const char* nexus_json_parse_value(const char* s, NexusJsonValue** out);

const char* nexus_json_parse_array(const char* s, NexusJsonValue** out) {
    if (!s || *s != '[') return NULL;
    s++;
    *out = nexus_json_array();
    if (!*out) return NULL;
    s = nexus_json_skip_whitespace(s);
    if (*s == ']') return s + 1;
    while (1) {
        NexusJsonValue* item = NULL;
        s = nexus_json_skip_whitespace(s);
        s = nexus_json_parse_value(s, &item);
        if (!s) { nexus_json_free(*out); *out = NULL; return NULL; }
        nexus_json_array_add(*out, item);
        s = nexus_json_skip_whitespace(s);
        if (*s == ']') return s + 1;
        if (*s != ',') { nexus_json_free(*out); *out = NULL; return NULL; }
        s++;
    }
}

const char* nexus_json_parse_object(const char* s, NexusJsonValue** out) {
    if (!s || *s != '{') return NULL;
    s++;
    *out = nexus_json_object();
    if (!*out) return NULL;
    s = nexus_json_skip_whitespace(s);
    if (*s == '}') return s + 1;
    while (1) {
        s = nexus_json_skip_whitespace(s);
        char* key = NULL;
        s = nexus_json_parse_string(s, &key);
        if (!s) { nexus_json_free(*out); *out = NULL; return NULL; }
        s = nexus_json_skip_whitespace(s);
        if (*s != ':') { free(key); nexus_json_free(*out); *out = NULL; return NULL; }
        s++;
        NexusJsonValue* val = NULL;
        s = nexus_json_skip_whitespace(s);
        s = nexus_json_parse_value(s, &val);
        if (!s) { free(key); nexus_json_free(*out); *out = NULL; return NULL; }
        nexus_json_object_add(*out, key, val);
        free(key);
        s = nexus_json_skip_whitespace(s);
        if (*s == '}') return s + 1;
        if (*s != ',') { nexus_json_free(*out); *out = NULL; return NULL; }
        s++;
    }
}

const char* nexus_json_parse_value(const char* s, NexusJsonValue** out) {
    s = nexus_json_skip_whitespace(s);
    if (!s || !*s) return NULL;
    switch (*s) {
        case 'n': if (strncmp(s,"null",4)==0){*out=nexus_json_null();return s+4;} return NULL;
        case 't': if (strncmp(s,"true",4)==0){*out=nexus_json_bool(true);return s+4;} return NULL;
        case 'f': if (strncmp(s,"false",5)==0){*out=nexus_json_bool(false);return s+5;} return NULL;
        case '"': { char* sv=NULL; const char* n=nexus_json_parse_string(s,&sv);
                    if(!n)return NULL; *out=nexus_json_string(sv); free(sv); return n; }
        case '[': return nexus_json_parse_array(s,out);
        case '{': return nexus_json_parse_object(s,out);
        default:  return nexus_json_parse_number(s,out);
    }
}

NexusJsonValue* nexus_json_parse(const char* json) {
    NexusJsonValue* result = NULL;
    const char* end = nexus_json_parse_value(json, &result);
    if (!end || *nexus_json_skip_whitespace(end) != '\0') {
        nexus_json_free(result);
        return NULL;
    }
    return result;
}

NexusJsonValue* nexus_json_parse_file(const char* filename) {
    FILE* f = fopen(filename, "r");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* buf = (char*)malloc((size_t)sz + 1);
    if (!buf) { fclose(f); return NULL; }
    size_t rd = fread(buf, 1, (size_t)sz, f);
    fclose(f);
    buf[rd] = '\0';
    NexusJsonValue* v = nexus_json_parse(buf);
    free(buf);
    return v;
}

/* ------------------------------------------------------------------ */
/* Output                                                               */
/* ------------------------------------------------------------------ */

#define NEXUS_JSON_IMPLEMENTATION
void nexus_json_write_to_string(const NexusJsonValue* value, char** out, size_t* length,
                                size_t* capacity, int indent, int current_indent) {
    if (!value || !out || !length || !capacity) return;
    if (*length + 256 > *capacity) {
        *capacity = *capacity * 2 + 256;
        *out = (char*)realloc(*out, *capacity);
    }
    char* buf = *out + *length;
    size_t rem = *capacity - *length;
    int w = 0;
    switch (value->type) {
        case NEXUS_JSON_NULL:   w += snprintf(buf+w,(int)(rem-w),"null"); break;
        case NEXUS_JSON_BOOL:   w += snprintf(buf+w,(int)(rem-w),value->data.boolean?"true":"false"); break;
        case NEXUS_JSON_NUMBER:
            if (value->data.number == (long long)value->data.number)
                 w += snprintf(buf+w,(int)(rem-w),"%lld",(long long)value->data.number);
            else w += snprintf(buf+w,(int)(rem-w),"%g",value->data.number);
            break;
        case NEXUS_JSON_STRING:
            w += snprintf(buf+w,(int)(rem-w),"\"");
            for (const char* p=value->data.string; *p; p++) {
                if (*length+w+8>*capacity){*length+=w;*capacity=*capacity*2+256;
                    *out=(char*)realloc(*out,*capacity);buf=*out+*length;rem=*capacity-*length;w=0;}
                if (*p=='"')  w+=snprintf(buf+w,(int)(rem-w),"\\\"");
                else if(*p=='\\')w+=snprintf(buf+w,(int)(rem-w),"\\\\");
                else if(*p=='\n')w+=snprintf(buf+w,(int)(rem-w),"\\n");
                else buf[w++]=*p;
            }
            w += snprintf(buf+w,(int)(rem-w),"\"");
            break;
        case NEXUS_JSON_ARRAY:
            w += snprintf(buf+w,(int)(rem-w),"[");
            *length += w; w=0;
            for (size_t i=0; i<value->data.array.count; i++) {
                nexus_json_write_to_string(value->data.array.items[i],out,length,capacity,indent,current_indent+indent);
                if (i+1<value->data.array.count){buf=*out+*length;rem=*capacity-*length;w=0;
                    w+=snprintf(buf+w,(int)(rem-w),",");*length+=w;w=0;}
            }
            buf=*out+*length;rem=*capacity-*length;w=0;
            w+=snprintf(buf+w,(int)(rem-w),"]");
            break;
        case NEXUS_JSON_OBJECT:
            w += snprintf(buf+w,(int)(rem-w),"{");
            *length += w; w=0;
            for (size_t i=0; i<value->data.object.count; i++) {
                buf=*out+*length;rem=*capacity-*length;w=0;
                w+=snprintf(buf+w,(int)(rem-w),"\"%s\":",value->data.object.keys[i]);
                *length+=w;
                nexus_json_write_to_string(value->data.object.values[i],out,length,capacity,indent,current_indent+indent);
                if (i+1<value->data.object.count){buf=*out+*length;rem=*capacity-*length;w=0;
                    w+=snprintf(buf+w,(int)(rem-w),",");*length+=w;w=0;}
            }
            buf=*out+*length;rem=*capacity-*length;w=0;
            w+=snprintf(buf+w,(int)(rem-w),"}");
            break;
    }
    *length += w;
}

char* nexus_json_to_string(const NexusJsonValue* value, bool pretty) {
    size_t len=0, cap=256;
    char* buf=(char*)malloc(cap);
    if (!buf) return NULL;
    nexus_json_write_to_string(value,&buf,&len,&cap,pretty?2:0,0);
    if (len+1>cap){ cap=len+1; buf=(char*)realloc(buf,cap); }
    buf[len]='\0';
    return buf;
}

bool nexus_json_write_file(const NexusJsonValue* value, const char* filename, bool pretty) {
    if (!value || !filename) return false;
    char* s = nexus_json_to_string(value, pretty);
    if (!s) return false;
    FILE* f = fopen(filename, "w");
    if (!f) { free(s); return false; }
    fprintf(f, "%s", s);
    fclose(f);
    free(s);
    return true;
}
