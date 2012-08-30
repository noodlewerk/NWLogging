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

    NWLRemoveAllFilters();
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

- (void)testAbout
{
    NWLRestoreDefaultFilters();
    NWLRestoreDefaultPrinters();
    NWLRestorePrintClock();
    
    NSUInteger aboutLength = 86;
    
    char buffer[256];
    
    // test about length is correct
    NWLAboutString(buffer, sizeof(buffer));
    NSString *s = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    STAssertEquals(s.length, aboutLength, @"");
    
    // test response correct with about-right length
    STAssertEquals(NWLAboutString(buffer, aboutLength - 2), (int)aboutLength, @"");
    STAssertEquals(NWLAboutString(buffer, aboutLength - 1), (int)aboutLength, @"");
    STAssertEquals(NWLAboutString(buffer, aboutLength    ), (int)aboutLength, @""); 
    STAssertEquals(NWLAboutString(buffer, aboutLength + 1), (int)aboutLength, @"");
    STAssertEquals(NWLAboutString(buffer, aboutLength + 2), (int)aboutLength, @"");
    
    // test all possible lengths exactly
    for (NSUInteger size = 0; size < 2 * aboutLength; size++) {
        memset(buffer, 254, sizeof(buffer));
        NSUInteger length = NWLAboutString(buffer, size);
        
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

- (void)xtestDefaultPrinter
{
    NWLContext context = {"tag", "lib", "file", 1, "function"};
    NWLDefaultPrinter(context, NULL, NULL);
    NWLDefaultPrinter(context, CFSTR(""), NULL);
    NWLDefaultPrinter(context, CFSTR("\0"), NULL);
    NWLDefaultPrinter(context, CFSTR("0"), NULL);
    NWLDefaultPrinter(context, CFSTR("\n"), NULL);
    NWLDefaultPrinter(context, CFSTR("ab"), NULL);
    NWLDefaultPrinter(context, CFSTR("01234567891023456789202345678930234567894023456789502345678960234567897023456789802345678990234567891003456789110345678912034567891303456789140345678915034567891603456789170345678918034567891903456789200345678921034567892203456789230345678924034567892503456789260345678927034567892803456789290345678930034567893103456789320345678933034567893403456789350345678936034567893703456789380345678939034567894003456789410345678942034567894303456789440345678945034567894603456789470345678948034567894903456789"), NULL);
    NWLContext empty = {"", "", "", 0, ""};
    NWLDefaultPrinter(empty, CFSTR("empty"), NULL);
    NWLContext nul = {NULL, NULL, NULL, 0, NULL};
    NWLDefaultPrinter(nul, CFSTR("NULL"), NULL);
    NWLContext notag = {"", "lib", "file", 1, "function"};
    NWLDefaultPrinter(notag, CFSTR("no tag"), NULL);
    NWLContext nolib = {"tag", "", "file", 1, "function"};
    NWLDefaultPrinter(nolib, CFSTR("no lib"), NULL);
    NWLContext nofile = {"tag", "lib", "", 1, "function"};
    NWLDefaultPrinter(nofile, CFSTR("no file"), NULL);
    NWLContext nofunction = {"tag", "lib", "file", 1, ""};
    NWLDefaultPrinter(nofunction, CFSTR("no function"), NULL);
}

@end
