//
//  NWLTools.m
//  NWLogging
//
//  Created by leonard on 6/6/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLTools.h"
#import "NWLPrinter.h"


@implementation NWLTools

+ (NSString *)dateMark
{
    NSString *result = [NSString stringWithFormat:@"==== %@ ====", NSDate.date];
    return result;
}

+ (NSString *)bundleInfo
{
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *name = [info valueForKey:@"CFBundleName"];
    NSString *version = [info valueForKey:@"CFBundleShortVersionString"];
    NSString *build = [info valueForKey:@"CFBundleVersion"];
    NSString *identifier = [info valueForKey:@"CFBundleIdentifier"];
    NSString *result = [NSString stringWithFormat:@"%@ %@b%@ (%@)", name, version, build, identifier];
    return result;
}

+ (NSString *)formatTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message
{
    NSDate *date = NSDate.date;
    static NSCalendar *calendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = NSCalendar.currentCalendar;
    });
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    short hour = [components hour];
    short minute = [components minute];
    short second = [components second];
    NSString *result = nil;
    if (tag.length) {
        result = [NSString stringWithFormat:@"[%02i:%02i:%02i] [%@] %@\n", hour, minute, second, tag, message];
    } else {
        result = [NSString stringWithFormat:@"[%02i:%02i:%02i] %@\n", hour, minute, second, message];
    }
    return result;
}

+ (NSString *)nameForPrinter:(id<NWLPrinter>)printer
{
    if ([printer respondsToSelector:@selector(printerName)]) {
        return [printer printerName];
    }
    return NSStringFromClass(printer.class);
}

@end
