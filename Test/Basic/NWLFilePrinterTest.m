//
//  NWLFilePrinterTest.m
//  NWLogging
//
//  Created by leonard on 6/10/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

@interface NWLFilePrinter ()
- (id)initForTesting;
@end

@interface NWLFilePrinterTest : SenTestCase @end

@implementation NWLFilePrinterTest {
    NWLFilePrinter *printer;
}

- (void)setUp {
    [super setUp];

    printer = [[NWLFilePrinter alloc] initForTesting];
    NSString *path = [NWLFilePrinter pathForName:@"test"];
    [printer openPath:path];

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
    printer.maxLogSize = 10;
    [printer clear];
    
    STAssertEquals((int)printer.content.length, 0, @"");
    
    [printer append:@"test"];
    STAssertEqualObjects(printer.content, @"test", @"");
    
    [printer append:@"test"];
    STAssertEqualObjects(printer.content, @"testtest", @"");
    
    [printer append:@"abc"];
    STAssertEqualObjects(printer.content, @"ttestabc", @"");
}

- (void)testPrinterSmall
{
    printer.maxLogSize = 2;
    [printer clear];
    [printer append:@""];
    STAssertEqualObjects(printer.content, @"", @"");
    [printer append:@"a"];
    STAssertEqualObjects(printer.content, @"a", @"");
    [printer append:@"b"];
    STAssertEqualObjects(printer.content, @"ab", @"");
    [printer append:@"c"];
    STAssertEqualObjects(printer.content, @"bc", @"");
    [printer append:@"de"];
    STAssertEqualObjects(printer.content, @"de", @"");
    [printer append:@"fgh"];
    STAssertEqualObjects(printer.content, @"gh", @"");

    printer.maxLogSize = 1;
    [printer clear];
    [printer append:@""];
    STAssertEqualObjects(printer.content, @"", @"");
    [printer append:@"a"];
    STAssertEqualObjects(printer.content, @"a", @"");
    [printer append:@"b"];
    STAssertEqualObjects(printer.content, @"b", @"");
    [printer append:@"cd"];
    STAssertEqualObjects(printer.content, @"d", @"");

    printer.maxLogSize = 0;
    [printer clear];
    [printer append:@""];
    STAssertEqualObjects(printer.content, @"", @"");
    [printer append:@"a"];
    STAssertEqualObjects(printer.content, @"", @"");
    [printer append:@"bc"];
    STAssertEqualObjects(printer.content, @"", @"");
}

- (void)testPrinterUnicode
{
    NSString *encoded = @"[\\245,\\243,\\u20ac,$,\\242,\\u20a1,\\u20a2,\\u20a3,\\u20a4,\\u20a5,\\u20a6,\\u20a7,\\u20a8,\\u20a9,\\u20aa,\\u20ab,\\u20ad,\\u20ae,\\u20af,\\u20b9,\\u89d2,\\u7530,\\u5bb6,\\ud83c\\udf35]";
    NSString *utf8 = [[NSString alloc] initWithData:[encoded dataUsingEncoding:NSASCIIStringEncoding] encoding:NSNonLossyASCIIStringEncoding];
    
    printer.maxLogSize = 10;
    [printer clear];
    [printer append:utf8];
    STAssertEquals((int)[printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 10, @"");
    STAssertEqualObjects(printer.content, [utf8 substringFromIndex:44], @"");

    printer.maxLogSize = 9;
    [printer clear];
    [printer append:utf8];
    STAssertEquals((int)[printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 9, @"");
    STAssertEqualObjects(printer.content, [utf8 substringFromIndex:45], @"");

    printer.maxLogSize = 6;
    [printer clear];
    [printer append:utf8];
    STAssertEquals((int)[printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 6, @"");
    STAssertEqualObjects(printer.content, [utf8 substringFromIndex:46], @"");

    printer.maxLogSize = 1;
    [printer clear];
    [printer append:utf8];
    STAssertEquals((int)[printer.content dataUsingEncoding:NSUTF8StringEncoding].length, 1, @"");
    STAssertEqualObjects(printer.content, [utf8 substringFromIndex:49], @"");
}

@end
