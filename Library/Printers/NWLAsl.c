//
//  NWLAsl.m
//  NWLogging
//
//  Copyright (c) 2016 leo. All rights reserved.
//

#import "NWLAsl.h"
#include <asl.h>

#pragma mark - Constants and statics

void NWLAslPrinter(NWLContext context, CFStringRef message, void *info) {
    CFRange range = CFRangeMake(0, message ? CFStringGetLength(message) : 0);
    unsigned char messageBuffer[1024];
    CFIndex messageLength = 0;
    CFStringGetBytes(message, range, kCFStringEncodingUTF8, '?', false, messageBuffer, sizeof(messageBuffer), &messageLength);
    asl_log_message(ASL_LEVEL_INFO, "%.*s", (int)messageLength, messageBuffer);
}
