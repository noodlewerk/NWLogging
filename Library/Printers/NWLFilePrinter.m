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
        serial = dispatch_queue_create("NWLFilePrinter", DISPATCH_QUEUE_SERIAL);
        calendar = NSCalendar.currentCalendar;
    }
    return self;
}

- (id)initForTesting
{
    self = [self init];
    serial = nil;
    return self;
}

- (id)initAndOpenName:(NSString *)name
{
    self = [self init];
    NSString *_path = [self.class pathForName:name];
    [self unsafeOpenPath:_path];
    return self;
}

- (id)initAndOpenPath:(NSString *)_path
{
    self = [self init];
    [self unsafeOpenPath:_path];
    return self;
}

- (void)dealloc
{
    if (serial) {
        dispatch_release(serial); serial = nil;
    }
}


#pragma mark - Helpers

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
        [[NSData data] writeToFile:path atomically:NO];
        result = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    return result;
}

+ (NSData *)utf8SubdataFromIndex:(NSUInteger)index data:(NSData *)data
{
    if (index < data.length) {
        NSUInteger length = data.length < index + 6 ? data.length - index : 6;
        unsigned char buffer[6] = {0, 0, 0, 0, 0, 0};
        [data getBytes:buffer range:NSMakeRange(index, length)];
        for (NSUInteger i = 0; i < length; i++) {
            BOOL isBeginUTF8Char = (buffer[i] & 0xC0) != 0x80;
            if (isBeginUTF8Char) {
                NSRange range = NSMakeRange(index + i, data.length - index - i);
                NSData *result = [data subdataWithRange:range];
                return result;
            }
        }
        NSData *result = [data subdataWithRange:NSMakeRange(index, data.length - index)];
        return result;
    }
    return [NSData data];
}

- (void)trimForAppendingLength:(NSUInteger)length
{
    if (size + length > maxLogSize) {
        [handle synchronizeFile];
        NSData *data = [NSData dataWithContentsOfFile:path options:0 error:nil]; // no logging on purpose
        NSUInteger keep = maxLogSize / 2 > length ? maxLogSize / 2 : (maxLogSize > length ? maxLogSize - length : 0);
        NSUInteger index = data.length > keep ? data.length - keep : 0;
        if (index) {
            data = [self.class utf8SubdataFromIndex:index data:data];
        }
        [data writeToFile:path atomically:NO];
        handle = [NSFileHandle fileHandleForWritingAtPath:path];
        size = [handle seekToEndOfFile];
    }
}


#pragma mark - Logging control

- (BOOL)openPath:(NSString *)_path
{
    __block BOOL result = NO;
    void(^b)(void) = ^{
        result = [self unsafeOpenPath:_path];
    };
    if (serial) dispatch_sync(serial, b); else b();
    return result;
}

- (BOOL)unsafeOpenPath:(NSString *)_path
{
    path = _path;
    handle = [self.class handleForPath:path];
    size = [handle seekToEndOfFile];
    BOOL result = !!handle;
    return result;
}

- (void)close
{
    void(^b)(void) = ^{
        [handle synchronizeFile];
        handle = nil;
        path = nil;
        size = 0;
    };
    if (serial) dispatch_sync(serial, b); else b();
}

- (void)sync
{
    void(^b)(void) = ^{
        [handle synchronizeFile];
    };
    if (serial) dispatch_sync(serial, b); else b();
}

- (void)clear
{
    void(^b)(void) = ^{
        [[NSData data] writeToFile:path atomically:NO];
        handle = [NSFileHandle fileHandleForWritingAtPath:path];
        size = [handle seekToEndOfFile];
    };
    if (serial) dispatch_sync(serial, b); else b();
}

- (NSString *)content
{
    __block NSString *result = nil;
    void(^b)(void) = ^{
        [handle synchronizeFile];
        result = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]; // no logging on purpose
    };
    if (serial) dispatch_sync(serial, b); else b();
    return result;
}

- (NSData *)contentData
{
    __block NSData *result = nil;
    void(^b)(void) = ^{
        [handle synchronizeFile];
        result = [NSData dataWithContentsOfFile:path];
    };
    if (serial) dispatch_sync(serial, b); else b();
    return result;
}

#pragma mark - Logging callbacks

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message
{
    NSString *s = [NWLTools formatTag:tag lib:lib file:file line:line function:function message:message];
    [self appendAsync:s];
}

- (NSString *)printerName
{
    return @"file-printer";
}

- (void)append:(NSString *)string
{
    void(^b)(void) = ^{
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self unsafeAppend:data];
    };
    if (serial) dispatch_sync(serial, b); else b();
}

- (void)appendAsync:(NSString *)string
{
    void(^b)(void) = ^{
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self unsafeAppend:data];
    };
    if (serial) dispatch_async(serial, b); else b();
}

- (void)appendData:(NSData *)data
{
    void(^b)(void) = ^{
        [self unsafeAppend:data];
    };
    if (serial) dispatch_sync(serial, b); else b();
}

- (void)appendDataAsync:(NSData *)data
{
    void(^b)(void) = ^{
        [self unsafeAppend:data];
    };
    if (serial) dispatch_async(serial, b); else b();
}

- (void)unsafeAppend:(NSData *)data
{
    [self trimForAppendingLength:data.length];
    NSUInteger remaining = maxLogSize > size ? maxLogSize - size : 0;
    if (data.length > remaining) {
        data = [self.class utf8SubdataFromIndex:data.length - remaining data:data];
    }
    [handle writeData:data];
    size += data.length;
}

@end
