//
//  NWLCore.m
//  NWLogging
//
//  Created by leonard on 4/25/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLCore.h"
#include <stdio.h>
#include <string.h>
#include <math.h>
#import <CoreFoundation/CFDate.h>

#pragma mark - Constants and statics

static const int kNWLFilterListSize = 16;
static const int kNWLPrinterListSize = 8;

typedef struct {
    const char *properties[kNWLProperty_count];
    NWLAction action;
} NWLFilter;

typedef struct {
    int count;
    NWLFilter elements[kNWLFilterListSize];
} NWLFilterList;

typedef struct {
    void(*func)(NWLContext, CFStringRef, void *);
    void *info;
} NWLPrinter;

typedef struct {
    int count;
    NWLPrinter elements[kNWLPrinterListSize];
} NWLPrinterList;

static NWLFilterList NWLFilters = {1, {NULL, "warn", NULL, NULL, NULL, kNWLAction_print}};
static NWLPrinterList NWLPrinters = {1, {NULL, NULL}};
static CFTimeInterval NWLTimeOffset = 0;


#pragma mark - Printing

void NWLForwardToPrinters(NWLContext context, CFStringRef message) {
    for (int i = 0; i < NWLPrinters.count; i++) {
        NWLPrinter *printer = &NWLPrinters.elements[i];
        void(*func)(NWLContext, CFStringRef, void *) = printer->func;
        void *info = printer->info;
        char buffer[100];
        memset(buffer, 0, sizeof(buffer));
        if (func) {
            func(context, message, info);
        } else {
            NWLDefaultPrinter(context, message, info);
        }
    }
}

int NWLAddPrinter(void(*func)(NWLContext, CFStringRef, void *), void *info) {
    int count = NWLPrinters.count ;
    if (count < kNWLPrinterListSize) {
        NWLPrinters.elements[count].func = func;
        NWLPrinters.elements[count].info = info;
        NWLPrinters.count = count + 1;
        return true;
    }
    return false;
}

int NWLRemovePrinter(void(*func)(NWLContext, CFStringRef, void *), void *info) {
    for (int i = 0; i < NWLPrinters.count; i++) {
        NWLPrinter *printer = &NWLPrinters.elements[i];
        int funcMatch = !func || printer->func == func;
        int infoMatch = !info || printer->info == info;
        if (funcMatch && infoMatch) {
            int count = NWLPrinters.count;
            if (count > 0) {
                NWLPrinters.count = count - 1;
                NWLPrinters.elements[i] = NWLPrinters.elements[count - 1];
                return true;
            }
        }
    }
    return false;
}

void NWLRemoveAllPrinters(void) {
    NWLPrinters.count = 0;
}

void NWLRestoreDefaultPrinters(void) {
    NWLPrinters.elements[0].func = NULL;
    NWLPrinters.elements[0].info = NULL;
    NWLPrinters.count = 1;
}

void NWLAddDefaultPrinter(void) {
    NWLAddPrinter(NULL, NULL);
}

void NWLDefaultPrinter(NWLContext context, CFStringRef message, void *info) {
    // compose time
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent() + NWLTimeOffset;
    int hour = (int)(time / 3600) % 24;
    int minute = (int)(time / 60) % 60;
    int second = (int)time % 60;
    int micro = (int)((time - floor(time)) * 1000000) % 1000000;
    // prepare tags
    int hasLib = context.lib && *context.lib;
    int hasFile = context.file && context.line;
    int hasTag = context.tag && *context.tag;
    char lineBuffer[6];
    if (context.line < 1000) {
        snprintf(lineBuffer, 6, "%03u", context.line);
    } else {
        snprintf(lineBuffer, 6, "%06u", context.line);
    }
    // convert to cstring
    unsigned char buffer[256];
    CFIndex used = 0;
    CFRange range = CFRangeMake(0, CFStringGetLength(message));
    CFIndex done = CFStringGetBytes(message, range, kCFStringEncodingUTF8, '?', false, buffer, sizeof(buffer), &used);
    // print log line
    fprintf(stderr, "[%02i:%02i:%02i.%06i%s%s%s%s%s%s%s%s] %.*s%s", 
            //                           %s%s = " lib"
            //                               %s%s%s%s = " file:line"
            //                                       %s%s = "] [tag"
            hour, minute, second, micro, 
            (hasLib ? " " : ""), (hasLib ? context.lib : ""), 
            (hasFile ? " " : ""), (hasFile ? context.file : ""), (hasFile ? ":" : ""), (hasFile ? lineBuffer : ""), 
            (hasTag ? "] [" : ""), (hasTag ? context.tag : ""), 
            (int)used, buffer, done >= range.length ? "\n" : (done ? "" : "~\n"));
    // while string exceeded buffer, print remaining chunks
    while (done && done < range.length) {
        range.location += done;
        range.length -= done;
        done = CFStringGetBytes(message, range, kCFStringEncodingUTF8, '?', false, buffer, sizeof(buffer), &used);
        fprintf(stderr, "%.*s%s", (int)used, buffer, done >= range.length ? "\n" : (done ? "" : "~\n"));
    }
}


#pragma mark - Filtering

NWLAction NWLActionForContext(NWLContext context) {
    NWLAction result = kNWLAction_none;
    int bestScore = 0;
    for (int i = 0; i < NWLFilters.count; i++) {
        NWLFilter *filter = &NWLFilters.elements[i];
        if (result < filter->action) {
            int score = 0;
            const char *s = NULL;
#define _NWL_FIND_(_prop) s = filter->properties[kNWLProperty_##_prop]; if (s && context._prop) {if (strcasecmp(s, context._prop)) {continue;} else {score++;}}
            _NWL_FIND_(tag)
            _NWL_FIND_(lib)
            _NWL_FIND_(file)
            _NWL_FIND_(function)
            if (bestScore <= score) {
                bestScore = score;
                result = filter->action;
            }
        }
    }
    return result;
}

static int NWLRemoveActionsWithProperties(NWLFilter *filter) {
    int result = 0;
    for (int i = 0; i < NWLFilters.count; i++) {
        NWLFilter *m = &NWLFilters.elements[i];
        int j = 1;
        for (; j < kNWLProperty_count; j++) {
            const char *a = filter->properties[j];
            const char *b = m->properties[j];
            if (a && (!b || strcasecmp(a, b))) break;
        }
        int count = NWLFilters.count;
        if (j == kNWLProperty_count && count > 0) {
            NWLFilters.count = count - 1;
            NWLFilters.elements[i--] = NWLFilters.elements[count - 1];
            result++;
        }
    }
    return result;
}

static int NWLAddActionAndProperties(NWLFilter *filter) {
    if (filter->action != kNWLAction_none) {
        int count = NWLFilters.count;
        if (count < kNWLFilterListSize) {
            NWLFilters.elements[count] = *filter;
            NWLFilters.count = count + 1;
            return true;
        }
    }
    return false;
}

int NWLAddActionForContextProperties(NWLProperty property1, const char *value1, NWLProperty property2, const char *value2, NWLProperty property3, const char *value3, NWLAction action) {
    NWLFilter filter;
    memset(&filter, 0, sizeof(NWLFilter));
    filter.properties[property3] = value3;
    filter.properties[property2] = value2;
    filter.properties[property1] = value1;
    filter.action = action;
    NWLRemoveActionsWithProperties(&filter);
    int result = NWLAddActionAndProperties(&filter);
    return result;
}

NWLAction NWLActionForContextProperties(NWLProperty property1, const char *value1, NWLProperty property2, const char *value2, NWLProperty property3, const char *value3) {
    NWLFilter filter;
    memset(&filter, 0, sizeof(NWLFilter));
    filter.properties[property3] = value3;
    filter.properties[property2] = value2;
    filter.properties[property1] = value1;
    for (int i = 0; i < NWLFilters.count; i++) {
        NWLFilter *m = &NWLFilters.elements[i];
        int j = 1;
        for (; j < kNWLProperty_count; j++) {
            const char *a = filter.properties[j];
            const char *b = m->properties[j];
            if (a != b && (!a || !b || strcasecmp(a, b))) break;
        }
        if (j == kNWLProperty_count) {
            return true;
        }
    }
    return false;
}

void NWLRemoveAllActions(void) {
    NWLFilters.count = 0;
}

void NWLRestoreDefaultActions(void) {
    NWLFilters.elements[0].action = kNWLAction_print;
    NWLFilters.elements[0].properties[0] = "warn";
    NWLFilters.count = 1;
}



#pragma mark - Clock

void NWLResetPrintClock(void) {
    NWLTimeOffset = -CFAbsoluteTimeGetCurrent();
}

void NWLRestorePrintClock(void) {
    NWLTimeOffset = 0;
}


#pragma mark - About

#define _NWL_PRINT_(_buffer, _size, _fmt, ...) do {\
        if (_size > 0) {\
            int p = snprintf(_buffer, _size, _fmt, ##__VA_ARGS__);\
            if (p > _size) p = _size;\
            if (p > 0) {_buffer += p; _size -= p;}\
            }\
    } while (0)

void NWLAboutString(char *buffer, int size) {
    _NWL_PRINT_(buffer, size, "About NWLogging");
    _NWL_PRINT_(buffer, size, "\n   #printers:%u", NWLPrinters.count);
    for (int i = 0; i < NWLFilters.count; i++) {
        NWLFilter *filter = &NWLFilters.elements[i];
#define _NWL_ABOUT_ACTION_(_action) do {if (filter->action == kNWLAction_##_action) {_NWL_PRINT_(buffer, size, "\n   action:"#_action);}} while (0)
        _NWL_ABOUT_ACTION_(print);
        _NWL_ABOUT_ACTION_(break);
        _NWL_ABOUT_ACTION_(raise);
        _NWL_ABOUT_ACTION_(assert);
        const char *value = NULL;
#define _NWL_ABOUT_PROP_(_prop) do {if ((value = filter->properties[kNWLProperty_##_prop])) {_NWL_PRINT_(buffer, size, " "#_prop":%s", value);}} while (0)
        _NWL_ABOUT_PROP_(tag);
        _NWL_ABOUT_PROP_(lib);
        _NWL_ABOUT_PROP_(file);
        _NWL_ABOUT_PROP_(function);
    }
    _NWL_PRINT_(buffer, size, "\n   time-offset:%f", NWLTimeOffset);
}


#pragma mark - Macro wrappers

void NWLPrintInfo() {
    NWLAddFilter(tag, "info", print);
}

void NWLPrintWarn() {
    NWLAddFilter(tag, "warn", print);
}

void NWLPrintDbug() {
    NWLAddFilter(tag, "dbug", print);
}

void NWLPrintTag(const char *tag) {
    NWLAddFilter(tag, tag, print);
}

void NWLPrintAll() {
    NWLAddFilter0(print);
}



void NWLPrintInfoInLib(const char *lib) {
    NWLAddFilter2(lib, lib, tag, "info", print);
}

void NWLPrintWarnInLib(const char *lib) {
    NWLAddFilter2(lib, lib, tag, "warn", print);
}

void NWLPrintDbugInLib(const char *lib) {
    NWLAddFilter2(lib, lib, tag, "dbug", print);
}

void NWLPrintTagInLib(const char *tag, const char *lib) {
    NWLAddFilter2(lib, lib, tag, tag, print);
}

void NWLPrintAllInLib(const char *lib) {
    NWLAddFilter(lib, lib, print);
}



void NWLPrintDbugInFile(const char *file) {
    NWLAddFilter2(tag, "dbug", file, file, print);
}

void NWLPrintDbugInFunction(const char *function) {
    NWLAddFilter2(tag, "dbug", function, function, print);
}



void NWLBreakWarn() {
    NWLAddFilter(tag, "warn", break);
}

void NWLBreakWarnInLib(const char *lib) {
    NWLAddFilter2(lib, lib, tag, "warn", break);
}

void NWLBreakTag(const char *tag) {
    NWLAddFilter(tag, tag, break);
}

void NWLBreakTagInLib(const char *tag, const char *lib) {
    NWLAddFilter2(lib, lib, tag, tag, break);
}



void NWLClearInfo() {
    NWLAddFilter(tag, "info", none);
}

void NWLClearWarn() {
    NWLAddFilter(tag, "warn", none);
}

void NWLClearDbug() {
    NWLAddFilter(tag, "dbug", none);
}

void NWLClearTag(const char *tag) {
    NWLAddFilter(tag, tag, none);
}

void NWLClearAllInLib(const char *lib) {
    NWLAddFilter(lib, lib, none);
}

void NWLClearAll(void) {
    NWLRemoveAllActions();
}



void NWLAbout(void) {
    char buffer[256];
    NWLAboutString(buffer, sizeof(buffer));
    NWLLogWithoutFilter(, NWLogging, "%s", buffer);
}

void NWLDump(void) {
    char buffer[256];
    NWLAboutString(buffer, sizeof(buffer));
    fprintf(stderr, "%s\n", buffer);
}
