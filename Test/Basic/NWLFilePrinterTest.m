//
//  NWLFilePrinterTest.m
//  NWLoggingTest
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#include "NWLCore.h"
#import "NWLFilePrinter.h"


@interface NWLFilePrinter ()
- (instancetype)initForTesting;
@end

@interface NWLFilePrinterTest : SenTestCase @end

@implementation NWLFilePrinterTest {
    NWLFilePrinter *_printer;
}

- (void)setUp {
    [super setUp];

    _printer = [[NWLFilePrinter alloc] initForTesting];
    NSString *path = [NWLFilePrinter pathForName:@"test"];
    [_printer openPath:path];

    NWLRemoveAllFilters();
    NWLRemoveAllPrinters();
}

- (void)testPrinterOpen
{
    NWLFilePrinter *p = [[NWLFilePrinter alloc] initForTesting];
    p.maxLogSize = 10;
    NSString *path = [NWLFilePrinter pathForName:@"test-open"];
    BOOL opened = [p openPath:path];
    STAssertTrue(opened, @"");
}

- (void)testPrinterBasic
{
    _printer.maxLogSize = 10;
    [_printer clear];

    STAssertEquals((int)_printer.content.length, 0, @"");

    [_printer append:@"test"];
    STAssertEqualObjects(_printer.content, @"test", @"");

    [_printer append:@"test"];
    STAssertEqualObjects(_printer.content, @"testtest", @"");

    [_printer append:@"abc"];
    STAssertEqualObjects(_printer.content, @"ttestabc", @"");
}

- (void)testPrinterSmall
{
    _printer.maxLogSize = 2;
    [_printer clear];
    [_printer append:@""];
    STAssertEqualObjects(_printer.content, @"", @"");
    [_printer append:@"a"];
    STAssertEqualObjects(_printer.content, @"a", @"");
    [_printer append:@"b"];
    STAssertEqualObjects(_printer.content, @"ab", @"");
    [_printer append:@"c"];
    STAssertEqualObjects(_printer.content, @"bc", @"");
    [_printer append:@"de"];
    STAssertEqualObjects(_printer.content, @"de", @"");
    [_printer append:@"fgh"];
    STAssertEqualObjects(_printer.content, @"gh", @"");

    _printer.maxLogSize = 1;
    [_printer clear];
    [_printer append:@""];
    STAssertEqualObjects(_printer.content, @"", @"");
    [_printer append:@"a"];
    STAssertEqualObjects(_printer.content, @"a", @"");
    [_printer append:@"b"];
    STAssertEqualObjects(_printer.content, @"b", @"");
    [_printer append:@"cd"];
    STAssertEqualObjects(_printer.content, @"d", @"");

    _printer.maxLogSize = 0;
    [_printer clear];
    [_printer append:@""];
    STAssertEqualObjects(_printer.content, @"", @"");
    [_printer append:@"a"];
    STAssertEqualObjects(_printer.content, @"a", @"");
    [_printer append:@"bc"];
    STAssertEqualObjects(_printer.content, @"abc", @"");
}

- (void)testPrinterUnicode
{
    NSString *encoded = @"[\\245,\\243,\\u20ac,$,\\242,\\u20a1,\\u20a2,\\u20a3,\\u20a4,\\u20a5,\\u20a6,\\u20a7,\\u20a8,\\u20a9,\\u20aa,\\u20ab,\\u20ad,\\u20ae,\\u20af,\\u20b9,\\u89d2,\\u7530,\\u5bb6,\\ud83c\\udf35]";
    NSString *utf8 = [[NSString alloc] initWithData:[encoded dataUsingEncoding:NSASCIIStringEncoding] encoding:NSNonLossyASCIIStringEncoding];

    _printer.maxLogSize = 10;
    [_printer clear];
    [_printer append:utf8];
    STAssertEquals((int)[_printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 10, @"");
    STAssertEqualObjects(_printer.content, [utf8 substringFromIndex:44], @"");

    _printer.maxLogSize = 9;
    [_printer clear];
    [_printer append:utf8];
    STAssertEquals((int)[_printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 9, @"");
    STAssertEqualObjects(_printer.content, [utf8 substringFromIndex:45], @"");

    _printer.maxLogSize = 6;
    [_printer clear];
    [_printer append:utf8];
    STAssertEquals((int)[_printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 6, @"");
    STAssertEqualObjects(_printer.content, [utf8 substringFromIndex:46], @"");

    _printer.maxLogSize = 1;
    [_printer clear];
    [_printer append:utf8];
    STAssertEquals((int)[_printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 1, @"");
    STAssertEqualObjects(_printer.content, [utf8 substringFromIndex:49], @"");
}

@end
