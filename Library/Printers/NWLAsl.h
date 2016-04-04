//
//  NWLAsl.h
//  NWLogging
//
//  Copyright (c) 2016 leo. All rights reserved.
//

#import "NWLCore.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#ifndef _NWLASL_H_
#define _NWLASL_H_

/** Formatter based on the Apple System Logger, with format: "[hr:mn:sc:micros Library File:line] [tag] message", to stderr. */
extern void NWLAslPrinter(NWLContext context, CFStringRef message, void *info);

#endif // _NWLASL_H_

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus
