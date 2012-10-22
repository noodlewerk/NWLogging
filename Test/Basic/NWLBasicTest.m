//
//  NWLBasicTest.m
//  NWLoggingTest
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#include "NWLCore.h"
#import "NWLLineLogger.h"


@interface NWLBasicTest : SenTestCase @end

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
    STAssertEqualObjects(NWLLineLogger.message, @"", @"");

    NWLog(@"testNWLLog");
    STAssertEqualObjects(NWLLineLogger.tag, NULL, @"");
    STAssertEqualObjects(NWLLineLogger.lib, @"NWLoggingTest", @"");
    STAssertEqualObjects(NWLLineLogger.file, @"NWLBasicTest.m", @"");
    STAssertEquals(NWLLineLogger.line, (NSUInteger)31, @"");
    STAssertEqualObjects(NWLLineLogger.function, @"-[NWLBasicTest testNWLLog]", @"");
    STAssertEqualObjects(NWLLineLogger.message, @"testNWLLog", @"");
    STAssertEquals(NWLLineLogger.info, (NSUInteger)13, @"");
}

- (void)testNWLLogTag
{
    [NWLLineLogger start:14];

    NWLPrintTagInLib("tag", "NWLDemo");
    NWLLogWithFilter("tag", "NWLDemo", @"");
    STAssertEqualObjects(NWLLineLogger.message, @"", @"");

    NWLLogWithFilter("tag", "NWLDemo", @"testNWLLogTag");
    STAssertEqualObjects(NWLLineLogger.tag, @"tag", @"");
    STAssertEqualObjects(NWLLineLogger.lib, @"NWLDemo", @"");
    STAssertEqualObjects(NWLLineLogger.file, @"NWLBasicTest.m", @"");
    STAssertEquals(NWLLineLogger.line, (NSUInteger)49, @"");
    STAssertEqualObjects(NWLLineLogger.function, @"-[NWLBasicTest testNWLLogTag]", @"");
    STAssertEqualObjects(NWLLineLogger.message, @"testNWLLogTag", @"");
    STAssertEquals(NWLLineLogger.info, (NSUInteger)14, @"");
}

- (void)testConfiguring
{
    STAssertEquals(NWLHasFilter(NULL, NULL, NULL, NULL), kNWLAction_none, @"");
    NWLPrintAll();
    STAssertEquals(NWLHasFilter(NULL, NULL, NULL, NULL), kNWLAction_print, @"");

    STAssertEquals(NWLHasFilter("info", NULL, NULL, NULL), kNWLAction_none, @"");
    NWLPrintInfo();
    STAssertEquals(NWLHasFilter("info", NULL, NULL, NULL), kNWLAction_print, @"");

    STAssertEquals(NWLHasFilter("dbug", NULL, "NWLBasicTest.m", NULL), kNWLAction_none, @"");
    NWLPrintDbugInFile("NWLBasicTest.m");
    STAssertEquals(NWLHasFilter("dbug", NULL, "NWLBasicTest.m", NULL), kNWLAction_print, @"");
}

- (void)testPrinter
{
    [NWLLineLogger start];

    NWLog(@"a");
    STAssertEqualObjects(NWLLineLogger.message, @"a", @"");

    [NWLLineLogger stop];

    NWLog(@"b");
    STAssertEqualObjects(NWLLineLogger.message, @"a", @"");

    [NWLLineLogger start];

    NWLog(@"c");
    STAssertEqualObjects(NWLLineLogger.message, @"c", @"");

    NWLRemoveAllPrinters();

    NWLog(@"d");
    STAssertEqualObjects(NWLLineLogger.message, @"c", @"");

    [NWLLineLogger start];

    NWLog(@"e");
    STAssertEqualObjects(NWLLineLogger.message, @"e", @"");
}

- (void)testFilterTag
{
    [NWLLineLogger start];

    NWLPrintTag("1");

    NWLLogWithFilter("1", "NWLDemo", @"a");
    STAssertEqualObjects(NWLLineLogger.message, @"a", @"");

    NWLClearTag("1");

    NWLLogWithFilter("1", "NWLDemo", @"b");
    STAssertEqualObjects(NWLLineLogger.message, @"a", @"");

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
    STAssertEqualObjects(NWLLineLogger.message, s, @"");
}

- (void)testAbout
{
    NWLRestore();

    int aboutLength = 86;

    char buffer[256];

    // test about length is correct
    NWLAboutString(buffer, sizeof(buffer));
    NSString *s = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    STAssertEquals((int)s.length, aboutLength, @"");

    // test response correct with about-right length
    STAssertEquals(NWLAboutString(buffer, aboutLength - 2), (int)aboutLength, @"");
    STAssertEquals(NWLAboutString(buffer, aboutLength - 1), (int)aboutLength, @"");
    STAssertEquals(NWLAboutString(buffer, aboutLength    ), (int)aboutLength, @"");
    STAssertEquals(NWLAboutString(buffer, aboutLength + 1), (int)aboutLength, @"");
    STAssertEquals(NWLAboutString(buffer, aboutLength + 2), (int)aboutLength, @"");

    // test all possible lengths exactly
    for (int size = 0; size < 2 * aboutLength; size++) {
        memset(buffer, 254, sizeof(buffer));
        int length = NWLAboutString(buffer, size);

        STAssertEquals(length, aboutLength, @"");

        for (NSUInteger i = 0; i < sizeof(buffer); i++) {
            if (i < MIN(size, aboutLength + 1)) {
                STAssertFalse(buffer[i] == 254, @"");
            } else {
                STAssertEquals(buffer[i], (char)254, @"");
            }
        }
    }
}

@end
