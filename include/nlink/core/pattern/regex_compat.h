#ifndef NLINK_REGEX_COMPAT_H
#define NLINK_REGEX_COMPAT_H

#if defined(__has_include)
#  if __has_include(<regex.h>)
#    include <regex.h>
#    define NLINK_HAS_POSIX_REGEX 1
#  endif
#endif

#ifndef NLINK_HAS_POSIX_REGEX
#include <stddef.h>
#include <string.h>
#include <fnmatch.h>

/* fnmatch.h: prefer the system header; fall back to the portable shim in
 * include/fnmatch.h (picked up via -I./include) on Windows / bare envs.    */
#if defined(__has_include)
#  if __has_include(<fnmatch.h>)
#    include <fnmatch.h>
#  else
#    include "fnmatch.h"
#  endif
#else
#  include "fnmatch.h"
#endif

#ifndef REG_EXTENDED
#define REG_EXTENDED 0x01
#endif
#ifndef REG_ICASE
#define REG_ICASE 0x02
#endif
#ifndef REG_NOSUB
#define REG_NOSUB 0x04
#endif
#ifndef REG_NEWLINE
#define REG_NEWLINE 0x08
#endif
#ifndef REG_NOMATCH
#define REG_NOMATCH 1
#endif

typedef struct {
    char pattern[256];
    int cflags;
} regex_t;

typedef struct {
    int rm_so;
    int rm_eo;
} regmatch_t;

static inline int regcomp(regex_t* preg, const char* regex, int cflags) {
    if (!preg || !regex) return 1;
    preg->cflags = cflags;
    size_t n = strlen(regex);
    if (n >= sizeof(preg->pattern)) return 1;
    memcpy(preg->pattern, regex, n + 1);
    return 0;
}

static inline int regexec(const regex_t* preg, const char* str, size_t nmatch, regmatch_t pmatch[], int eflags) {
    (void)eflags;
    if (!preg || !str) return REG_NOMATCH;

    if (strpbrk(preg->pattern, "[]^$()+|\\")) {
        return REG_NOMATCH;
    }

    if (strchr(preg->pattern, '*') || strchr(preg->pattern, '?')) {
        int rc = fnmatch(preg->pattern, str, 0);
        if (rc == 0) {
            if (nmatch > 0 && pmatch) {
                pmatch[0].rm_so = 0;
                pmatch[0].rm_eo = (int)strlen(str);
            }
            return 0;
        }
        return REG_NOMATCH;
    }

    const char* hit = strstr(str, preg->pattern);
    if (!hit) return REG_NOMATCH;

    if (nmatch > 0 && pmatch) {
        pmatch[0].rm_so = (int)(hit - str);
        pmatch[0].rm_eo = pmatch[0].rm_so + (int)strlen(preg->pattern);
    }
    return 0;
}

static inline void regfree(regex_t* preg) {
    (void)preg;
}

static inline size_t regerror(int errcode, const regex_t* preg, char* errbuf, size_t errbuf_size) {
    (void)preg;
    const char* msg = (errcode == REG_NOMATCH) ? "No match" : "Regex unavailable";
    size_t len = strlen(msg);
    if (errbuf && errbuf_size) {
        size_t copy = (len >= errbuf_size) ? errbuf_size - 1 : len;
        memcpy(errbuf, msg, copy);
        errbuf[copy] = '\0';
    }
    return len + 1;
}

#endif /* !NLINK_HAS_POSIX_REGEX */

#endif /* NLINK_REGEX_COMPAT_H */
