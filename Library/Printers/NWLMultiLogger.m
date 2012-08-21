//
//  NWLMultiLogger.m
//  NWLogging
//
//  Created by leonard on 6/7/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLMultiLogger.h"
#import "NWLCore.h"
#import "NWLPrinter.h"


@implementation NWLMultiLogger {
    NSMutableDictionary *printers;
    NSMutableDictionary *printerNames;
    dispatch_queue_t serial;
}


#pragma mark - Object life cycle

- (id)init
{
    return nil;
}

- (id)initPrivate
{
    self = [super init];
    if (self) {
        serial = dispatch_queue_create("NWLMultiLogger", DISPATCH_QUEUE_SERIAL);
        printers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (serial) {
        dispatch_release(serial); serial = NULL;
    }
}

static NWLMultiLogger *NWLMultiLoggerShared = nil;
+ (NWLMultiLogger *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NWLMultiLoggerShared = [[NWLMultiLogger alloc] initPrivate];
    });
    return NWLMultiLoggerShared;
}


#pragma mark - Configuration

- (void)addPrinter:(id<NWLPrinter>)printer
{
    dispatch_sync(serial, ^{
        [self unsafeRemovePrinter:printer];
        NSString *name = printer.name;
        const char *n = name.UTF8String;
        int length = strlen(n);
        char *copy = calloc(length, sizeof(char));
        memcpy(copy, n, length);
        NSUInteger index = printers.count;
        [printers addObject:printer];
        NWLAddPrinter(copy, NWLMultiLoggerPrinter, CFBridgingRetain(name));
    });
}

- (void)unsafeRemovePrinter:(id<NWLPrinter>)printer
{
    if ([printers objectForKey:printer.name]) {
        NWLRemovePrinter(NWLMultiLoggerPrinter, (void *)(index + 1));
        
        
        [printers removeObjectForKey:printer.name];
    }
    NSUInteger index = [printers indexOfObject:printer];
    if (index != NSNotFound) {
        [printers removeObjectAtIndex:index];
    }
}


- (void)removePrinter:(id<NWLPrinter>)printer
{
    dispatch_sync(serial, ^{
        NSUInteger index = [printers indexOfObject:printer];
        if (index != NSNotFound) {
            [printers removeObjectAtIndex:index];
            NWLRemovePrinter(NWLMultiLoggerPrinter, (void *)(index + 1));
        }
    });
}

- (void)removeAllPrinters
{
    dispatch_sync(serial, ^{
        for (id<NWLPrinter> printer in printers) {
            [self unsafeRemovePrinter:printer];
        }
        for (NSValue *value in printerNames) {
            void *name = value.pointerValue;
            free(name);
            [self unsafeRemovePrinter:printer];
        }
        [printers removeAllObjects];
    });
}

- (NSUInteger)count
{
    __block NSUInteger result = 0;
    dispatch_sync(serial, ^{
        result = printers.count;
    });
    return result;
}


#pragma mark - Printing

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message name:(NSString *)name
{
    dispatch_async(serial, ^{
        if (name) {
            id<NWLPrinter> printer = [printers objectForKey:name];
            [printer printWithTag:tag lib:lib file:file line:line function:function message:message];
        }
    });
}

static void NWLMultiLoggerPrinter(NWLContext context, CFStringRef message, void *info) {
    NSString *tagString = context.tag ? [NSString stringWithCString:context.tag encoding:NSUTF8StringEncoding] : nil;
    NSString *libString = context.lib ? [NSString stringWithCString:context.lib encoding:NSUTF8StringEncoding] : nil;
    NSString *fileString = context.file ? [NSString stringWithCString:context.file encoding:NSUTF8StringEncoding] : nil;
    NSString *functionString = context.function ? [NSString stringWithCString:context.function encoding:NSUTF8StringEncoding] : nil;
    NSString *messageString = (__bridge NSString *)message;
    NSString *name = (__bridge NSString *)info;
    [NWLMultiLoggerShared printWithTag:tagString lib:libString file:fileString line:context.line function:functionString message:messageString name:name];
}


@end

