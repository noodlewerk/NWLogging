//
//  NWLBasicTest.m
//  NWLogging
//
//  Created by leonard on 6/10/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLLineLogger.h"


@interface NWLBasicTest : SenTestCase @end

@implementation NWLBasicTest

- (void)setUp {
    [super setUp];

    NWLRemoveAllActions();
    NWLRemoveAllPrinters();
}

- (void)testNWLLog
{
    [NWLLineLogger start:13];

    NWLog(@"");
    STAssertEqualObjects(NWLLineLogger.message, @"", @"");

    NWLog(@"testNWLLog");
    STAssertEqualObjects(NWLLineLogger.tag, @"", @"");
    STAssertEqualObjects(NWLLineLogger.lib, @"NWLoggingTest", @"");
    STAssertEqualObjects(NWLLineLogger.file, @"NWLBasicTest.m", @"");
    STAssertEquals(NWLLineLogger.line, (NSUInteger)30, @"");
    STAssertEqualObjects(NWLLineLogger.function, @"-[NWLBasicTest testNWLLog]", @"");
    STAssertEqualObjects(NWLLineLogger.message, @"testNWLLog", @"");
    STAssertEquals(NWLLineLogger.info, (NSUInteger)13, @"");
}

- (void)testNWLLogTag
{
    [NWLLineLogger start:14];

    NWLPrintTagInLib("tag", "NWLDemo");
    NWLLogWithFilter(tag, NWLDemo, @"");
    STAssertEqualObjects(NWLLineLogger.message, @"", @"");
    
    NWLLogWithFilter(tag, NWLDemo, @"testNWLLogTag");
    STAssertEqualObjects(NWLLineLogger.tag, @"tag", @"");
    STAssertEqualObjects(NWLLineLogger.lib, @"NWLDemo", @"");
    STAssertEqualObjects(NWLLineLogger.file, @"NWLBasicTest.m", @"");
    STAssertEquals(NWLLineLogger.line, (NSUInteger)48, @"");
    STAssertEqualObjects(NWLLineLogger.function, @"-[NWLBasicTest testNWLLogTag]", @"");
    STAssertEqualObjects(NWLLineLogger.message, @"testNWLLogTag", @"");
    STAssertEquals(NWLLineLogger.info, (NSUInteger)14, @"");
}

- (void)testConfiguring
{
    STAssertEquals(NWLGetFilter0(), kNWLAction_none, @"");
    NWLPrintAll();
    STAssertEquals(NWLGetFilter0(), kNWLAction_print, @"");
    
    STAssertEquals(NWLGetFilter(tag, "info"), kNWLAction_none, @"");
    NWLPrintInfo();
    STAssertEquals(NWLGetFilter(tag, "info"), kNWLAction_print, @"");

    STAssertEquals(NWLGetFilter2(tag, "dbug", file, "NWLBasicTest.m"), kNWLAction_none, @"");
    NWLPrintDbugInFile("NWLBasicTest.m");
    STAssertEquals(NWLGetFilter2(tag, "dbug", file, "NWLBasicTest.m"), kNWLAction_print, @"");
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
    
    NWLLogWithFilter(1, NWLDemo, @"a");
    STAssertEqualObjects(NWLLineLogger.message, @"a", @"");
    
    NWLClearTag("1");
    
    NWLLogWithFilter(1, NWLDemo, @"b");
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

@end
