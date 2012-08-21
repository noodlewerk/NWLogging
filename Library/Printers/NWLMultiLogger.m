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


@interface NWLPrinterEntry : NSObject
@property (nonatomic, strong) id<NWLPrinter> printer;
@property (nonatomic, readonly) char *copy;
@property (nonatomic, readonly) id key;
- (id)initWithPrinter:(id<NWLPrinter>)printer;
+ (NSString *)keyWithPrinter:(id<NWLPrinter>)printer;
@end


@implementation NWLMultiLogger {
    NSMutableDictionary *printerEntries;
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
        printerEntries = [[NSMutableDictionary alloc] init];
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
    if (printer) {
        dispatch_sync(serial, ^{
            [self unsafeRemovePrinter:printer];
            NWLPrinterEntry *entry = [[NWLPrinterEntry alloc] initWithPrinter:printer];
            NSString *key = entry.key;
            [printerEntries setObject:entry forKey:key];
            NWLAddPrinter(entry.copy, NWLMultiLoggerPrinter, (__bridge void *)key);
        });
    }
}

- (void)unsafeRemovePrinter:(id<NWLPrinter>)printer
{
    NSString *key = [NWLPrinterEntry keyWithPrinter:printer];
    NWLPrinterEntry *entry = [printerEntries objectForKey:key];
    if (entry) {
        NWLRemovePrinter(entry.copy);
        [printerEntries removeObjectForKey:key];
    }
}


- (void)removePrinter:(id<NWLPrinter>)printer
{
    if (printer) {
        dispatch_sync(serial, ^{
            [self unsafeRemovePrinter:printer];
        });
    }
}

- (void)removeAllPrinters
{
    dispatch_sync(serial, ^{
        NSArray *printers = [printerEntries.allValues valueForKey:@"printer"];
        for (id<NWLPrinter> printer in printers) {
            [self unsafeRemovePrinter:printer];
        }
    });
}

- (NSUInteger)count
{
    __block NSUInteger result = 0;
    dispatch_sync(serial, ^{
        result = printerEntries.count;
    });
    return result;
}


#pragma mark - Printing

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message name:(NSString *)name
{
    dispatch_async(serial, ^{
        if (name) {
            id<NWLPrinter> printer = [(NWLPrinterEntry *)[printerEntries objectForKey:name] printer];
            [printer printWithTag:tag lib:lib file:file line:line function:function message:message];
        }
    });
}

- (NSString *)name
{
    return @"multi-logger";
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



@implementation NWLPrinterEntry

@synthesize printer, copy, key;

- (id)initWithPrinter:(id<NWLPrinter>)_printer
{
    self = [super init];
    if (self) {
        NSString *_key = [self.class keyWithPrinter:_printer];
        const char *utf8 = _key.UTF8String;
        size_t length = strlen(utf8) + 1;
        char *_copy = calloc(length, sizeof(char));
        memcpy(_copy, utf8, length);
        printer = _printer;
        key = _key;
        copy = _copy;
    }
    return self;
}

- (void)dealloc
{
    if (copy) {
        free(copy); copy = NULL;
    }
}

+ (NSString *)keyWithPrinter:(id<NWLPrinter>)printer
{
    if (printer) {
        NSString *name = nil;
        if ([printer respondsToSelector:@selector(name)]) {
            name = printer.name;
        } else {
            name = NSStringFromClass(printer.class);
        }
        NSString *result = [NSString stringWithFormat:@"multi-logger>%@", name];
        return result;
    }
    return nil;
}

@end
