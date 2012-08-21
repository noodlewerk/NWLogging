//
//  NWLFilePrinter.m
//  NWLogging
//
//  Created by leonard on 6/6/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLFilePrinter.h"
#import "NWLogging.h"
#import "NWLTools.h"


@implementation NWLFilePrinter {
    NSFileHandle *handle;
    dispatch_queue_t serial;
    unsigned long long size;
    NSCalendar *calendar;
}

@synthesize maxLogSize, path;


#pragma mark - Object life cycle

- (id)init
{
    self = [super init];
    if (self) {
        maxLogSize = 100 * 1000; // 100 KB
        serial = dispatch_queue_create("NWLFileLogger", DISPATCH_QUEUE_SERIAL);
        calendar = NSCalendar.currentCalendar;
    }
    return self;
}

- (id)initWithFileName:(NSString *)name
{
    id result = [self init];
    [result openPath:[self.class pathForName:name]];
    return result;
}

- (void)dealloc
{
    if (serial) {
        dispatch_release(serial); serial = nil;
    }
}


#pragma mark - Misc

+ (NSString *)pathForName:(NSString *)name
{
    NSString *result = nil;
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if (cachePaths.count) {
        NSString *file = [NSString stringWithFormat:@"%@.log", name];
        result = [[cachePaths objectAtIndex:0] stringByAppendingPathComponent:file];
    }
    return result;
}

+ (NSFileHandle *)handleForPath:(NSString *)path
{
    NSFileHandle *result = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!result) {
        [NSFileManager.defaultManager createFileAtPath:path contents:[NSData data] attributes:nil];
        result = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    return result;
}


#pragma mark - Logging control

- (void)openPath:(NSString *)_path
{
    dispatch_sync(serial, ^{
        path = _path;
        handle = [self.class handleForPath:path];
        size = [handle seekToEndOfFile];
    });
}

- (void)close
{
    dispatch_sync(serial, ^{
        [handle synchronizeFile];
        handle = nil;
        path = nil;
        size = 0;
    });
}

- (void)sync
{
    dispatch_sync(serial, ^{
        [handle synchronizeFile];
    });
}

- (void)clear
{
    dispatch_sync(serial, ^{
        [NSFileManager.defaultManager createFileAtPath:path contents:[NSData data] attributes:nil];
        handle = [NSFileHandle fileHandleForWritingAtPath:path];
        size = 0;
    });
}

- (NSString *)content
{
    __block NSString *result = nil;
    dispatch_sync(serial, ^{
        [handle synchronizeFile];
        result = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]; // no logging on purpose
    });
    return result;
}


#pragma mark - Logging callbacks

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message
{
    NSString *s = [NWLTools formatTag:tag lib:lib file:file line:line function:function message:message];
    [self logLine:s];
}

- (NSString *)name
{
    return @"file-printer";
}

- (void)logLine:(NSString *)line
{
    dispatch_async(serial, ^{
        // foward to delegates
        
        // file logging
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        size += data.length;
        if (size > maxLogSize) {
            [handle synchronizeFile];
            NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]; // no logging on purpose
            if (fileContent.length > maxLogSize / 2) {
                fileContent = [fileContent substringFromIndex:fileContent.length - maxLogSize / 2];
            }
            [NSFileManager.defaultManager createFileAtPath:path contents:[NSData data] attributes:nil];
            handle = [NSFileHandle fileHandleForWritingAtPath:path];
            data = [fileContent dataUsingEncoding:NSUTF8StringEncoding];
            size = data.length;
        }
        [handle writeData:data];
    });
}

@end
