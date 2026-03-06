/*
 * fnmatch.h – portable shim for Windows (MinGW) and minimal POSIX environments
 *
 * Only compiled when the system does NOT provide its own fnmatch.h.
 * On Linux with glibc, the system header takes priority because -I./include
 * is searched after the system path by default; use -iquote./include or
 * -I./include before system paths to force this shim on Linux too.
 *
 * On Windows / MSVC / bare MinGW this file is the only fnmatch available.
 */

#ifndef FNMATCH_H
#define FNMATCH_H

#ifdef __cplusplus
extern "C" {
#endif

/* Return value: 0 = match, FNM_NOMATCH = no match */
#define FNM_NOMATCH   1
#define FNM_NOESCAPE  0x01
#define FNM_PATHNAME  0x02
#define FNM_PERIOD    0x04
#define FNM_CASEFOLD  0x10   /* GNU extension – ignored in this shim */

#include <string.h>

/*
 * Minimal glob-style pattern matcher.
 * Supports:  *  (any sequence),  ?  (any single char)
 * Does NOT support character classes [abc] or escape sequences.
 */
static inline int fnmatch(const char *pattern, const char *string, int flags)
{
    (void)flags;    /* flag processing not implemented in this shim */

    if (!pattern || !string) return FNM_NOMATCH;

    const char *p = pattern;
    const char *s = string;

    while (*p && *s) {
        if (*p == '*') {
            /* Skip consecutive stars */
            while (*(p + 1) == '*') p++;
            if (!*(p + 1)) return 0;          /* trailing * matches everything */
            /* Try matching the rest of the pattern against every suffix */
            while (*s) {
                if (fnmatch(p + 1, s, flags) == 0) return 0;
                s++;
            }
            return FNM_NOMATCH;
        }
        if (*p == '?') {
            p++;
            s++;
            continue;
        }
        if (*p != *s) return FNM_NOMATCH;
        p++;
        s++;
    }

    /* Consume trailing stars in pattern */
    while (*p == '*') p++;

    return (*p == '\0' && *s == '\0') ? 0 : FNM_NOMATCH;
}

#ifdef __cplusplus
}
#endif

#endif /* FNMATCH_H */
