//
//  NWLBasicTest.m
//  NWLoggingTest
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "NWLCore.h"
#import "NWLLineLogger.h"


@interface NWLBasicTest : XCTestCase @end

@implementation NWLBasicTest

- (void)setUp {
    [super setUp];

    NWLRemoveAllFilters();
    NWLRemoveAllPrinters();
}

- (void)testNWLLog
{
    [NWLLineLogger start:13];

    NWLog(@"");
    XCTAssertEqualObjects(NWLLineLogger.message, @"", @"");

    NWLog(@"testNWLLog");
    XCTAssertEqualObjects(NWLLineLogger.tag, NULL, @"");
    XCTAssertEqualObjects(NWLLineLogger.lib, @"NWLoggingTest", @"");
    XCTAssertEqualObjects(NWLLineLogger.file, @"NWLBasicTest.m", @"");
    XCTAssertEqual(NWLLineLogger.line, (NSUInteger)31, @"");
    XCTAssertEqualObjects(NWLLineLogger.function, @"-[NWLBasicTest testNWLLog]", @"");
    XCTAssertEqualObjects(NWLLineLogger.message, @"testNWLLog", @"");
    XCTAssertEqual(NWLLineLogger.info, (NSUInteger)13, @"");
}

- (void)testNWLLogTag
{
    [NWLLineLogger start:14];

    NWLPrintTagInLib("tag", "NWLDemo");
    NWLLogWithFilter("tag", "NWLDemo", @"");
    XCTAssertEqualObjects(NWLLineLogger.message, @"", @"");

    NWLLogWithFilter("tag", "NWLDemo", @"testNWLLogTag");
    XCTAssertEqualObjects(NWLLineLogger.tag, @"tag", @"");
    XCTAssertEqualObjects(NWLLineLogger.lib, @"NWLDemo", @"");
    XCTAssertEqualObjects(NWLLineLogger.file, @"NWLBasicTest.m", @"");
    XCTAssertEqual(NWLLineLogger.line, (NSUInteger)49, @"");
    XCTAssertEqualObjects(NWLLineLogger.function, @"-[NWLBasicTest testNWLLogTag]", @"");
    XCTAssertEqualObjects(NWLLineLogger.message, @"testNWLLogTag", @"");
    XCTAssertEqual(NWLLineLogger.info, (NSUInteger)14, @"");
}

- (void)testConfiguring
{
    XCTAssertEqual(NWLHasFilter(NULL, NULL, NULL, NULL), kNWLAction_none, @"");
    NWLPrintAll();
    XCTAssertEqual(NWLHasFilter(NULL, NULL, NULL, NULL), kNWLAction_print, @"");

    XCTAssertEqual(NWLHasFilter("info", NULL, NULL, NULL), kNWLAction_none, @"");
    NWLPrintInfo();
    XCTAssertEqual(NWLHasFilter("info", NULL, NULL, NULL), kNWLAction_print, @"");

    XCTAssertEqual(NWLHasFilter("dbug", NULL, "NWLBasicTest.m", NULL), kNWLAction_none, @"");
    NWLPrintDbugInFile("NWLBasicTest.m");
    XCTAssertEqual(NWLHasFilter("dbug", NULL, "NWLBasicTest.m", NULL), kNWLAction_print, @"");
}

- (void)testPrinter
{
    [NWLLineLogger start];

    NWLog(@"a");
    XCTAssertEqualObjects(NWLLineLogger.message, @"a", @"");

    [NWLLineLogger stop];

    NWLog(@"b");
    XCTAssertEqualObjects(NWLLineLogger.message, @"a", @"");

    [NWLLineLogger start];

    NWLog(@"c");
    XCTAssertEqualObjects(NWLLineLogger.message, @"c", @"");

    NWLRemoveAllPrinters();

    NWLog(@"d");
    XCTAssertEqualObjects(NWLLineLogger.message, @"c", @"");

    [NWLLineLogger start];

    NWLog(@"e");
    XCTAssertEqualObjects(NWLLineLogger.message, @"e", @"");
}

- (void)testFilterTag
{
    [NWLLineLogger start];

    NWLPrintTag("1");

    NWLLogWithFilter("1", "NWLDemo", @"a");
    XCTAssertEqualObjects(NWLLineLogger.message, @"a", @"");

    NWLClearTag("1");

    NWLLogWithFilter("1", "NWLDemo", @"b");
    XCTAssertEqualObjects(NWLLineLogger.message, @"a", @"");

    // TODO: to be continued...
}

- (void)testBadCharacters
{
    [NWLLineLogger start];

    NSString *encoded = @"\\ud83c\\udf35";
    NSString *utf8 = [[NSString alloc] initWithData:[encoded dataUsingEncoding:NSASCIIStringEncoding] encoding:NSNonLossyASCIIStringEncoding];
    NSString *bad = [utf8 substringToIndex:1];

    NWLog(@"*%@*", bad);
    NSString *s = [NSString stringWithFormat:@"*%@*", bad];
    XCTAssertEqualObjects(NWLLineLogger.message, s, @"");
}

- (void)testAbout
{
    NWLRestore();

    int aboutLength = 86;

    char buffer[256];

    // test about length is correct
    NWLAboutString(buffer, sizeof(buffer));
    NSString *s = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    XCTAssertEqual((int)s.length, aboutLength, @"");

    // test response correct with about-right length
    XCTAssertEqual(NWLAboutString(buffer, aboutLength - 2), (int)aboutLength, @"");
    XCTAssertEqual(NWLAboutString(buffer, aboutLength - 1), (int)aboutLength, @"");
    XCTAssertEqual(NWLAboutString(buffer, aboutLength    ), (int)aboutLength, @"");
    XCTAssertEqual(NWLAboutString(buffer, aboutLength + 1), (int)aboutLength, @"");
    XCTAssertEqual(NWLAboutString(buffer, aboutLength + 2), (int)aboutLength, @"");

    // test all possible lengths exactly
    for (int size = 0; size < 2 * aboutLength; size++) {
        memset(buffer, 254, sizeof(buffer));
        int length = NWLAboutString(buffer, size);

        XCTAssertEqual(length, aboutLength, @"");

        for (NSUInteger i = 0; i < sizeof(buffer); i++) {
            if (i < MIN(size, aboutLength + 1)) {
                XCTAssertFalse(buffer[i] == (char)254, @"");
            } else {
                XCTAssertEqual(buffer[i], (char)254, @"");
            }
        }
    }
}

@end
