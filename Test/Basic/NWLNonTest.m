//
//  NWLNonTest.m
//  NWLoggingTest
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "NWLCore.h"

//#define RUN_NON_TESTS 1


@interface NWLNonTest : XCTestCase @end

@implementation NWLNonTest

- (void)testStderrPrinter
{
#if RUN_NON_TESTS
    NWLContext context = {"tag", "lib", "file", 1, "function", NWLTime()};
    NWLStderrPrinter(context, NULL, NULL);
    NWLStderrPrinter(context, CFSTR(""), NULL);
    NWLStderrPrinter(context, CFSTR("\0"), NULL);
    NWLStderrPrinter(context, CFSTR("0"), NULL);
    NWLStderrPrinter(context, CFSTR("\n"), NULL);
    NWLStderrPrinter(context, CFSTR("ab"), NULL);
    NWLStderrPrinter(context, CFSTR("01234567891023456789202345678930234567894023456789502345678960234567897023456789802345678990234567891003456789110345678912034567891303456789140345678915034567891603456789170345678918034567891903456789200345678921034567892203456789230345678924034567892503456789260345678927034567892803456789290345678930034567893103456789320345678933034567893403456789350345678936034567893703456789380345678939034567894003456789410345678942034567894303456789440345678945034567894603456789470345678948034567894903456789"), NULL);
    NWLContext empty = {"", "", "", 0, "", NWLTime()};
    NWLStderrPrinter(empty, CFSTR("empty"), NULL);
    NWLContext nul = {NULL, NULL, NULL, 0, NULL, NWLTime()};
    NWLStderrPrinter(nul, CFSTR("NULL"), NULL);
    NWLContext notag = {"", "lib", "file", 1, "function", NWLTime()};
    NWLStderrPrinter(notag, CFSTR("no tag"), NULL);
    NWLContext nolib = {"tag", "", "file", 1, "function", NWLTime()};
    NWLStderrPrinter(nolib, CFSTR("no lib"), NULL);
    NWLContext nofile = {"tag", "lib", "", 1, "function", NWLTime()};
    NWLStderrPrinter(nofile, CFSTR("no file"), NULL);
    NWLContext nofunction = {"tag", "lib", "file", 1, "", NWLTime()};
    NWLStderrPrinter(nofunction, CFSTR("no function"), NULL);
#endif // RUN_NON_TESTS
}

- (void)testFormatWarnings
{
#if RUN_NON_TESTS
    return;

    NWLLogWithoutFilter("tag", "lib", @"No warnings: %@ %i %f %lli", @"", 1, .1, 1LL);
    NWLLogWithoutFilter("tag", "lib", @"Too many arguments: %@", @"", @"");
    NWLLogWithoutFilter("tag", "lib", @"Too many arguments: %i", 1, 1);
    NWLLogWithoutFilter("tag", "lib", @"Too many arguments: ", 0);
    NWLLogWithoutFilter("tag", "lib", @"Too few arguments: %@ %@", @"");
    NWLLogWithoutFilter("tag", "lib", @"Too few arguments: %i %i", 1);
    NWLLogWithoutFilter("tag", "lib", @"Too few arguments: %i");
    NWLLogWithoutFilter("tag", "lib", @"String is no int: %i", @"");
    NWLLogWithoutFilter("tag", "lib", @"int is no String: %@", 1);
    NWLLogWithoutFilter("tag", "lib", @"double is no int: %i", .1);
    NWLLogWithoutFilter("tag", "lib", @"int is no double: %f", 1);
    NWLLogWithoutFilter("tag", "lib", @"long long is no int: %i", 1LL);
    NWLLogWithoutFilter("tag", "lib", @"int is no long long: %lli", 1);

    NWLLogWithFilter("tag", "lib", @"No warnings: %@ %i %f %lli", @"", 1, .1, 1LL);
    NWLLogWithFilter("tag", "lib", @"Too many arguments: %@", @"", @"");
    NWLLogWithFilter("tag", "lib", @"Too many arguments: %i", 1, 1);
    NWLLogWithFilter("tag", "lib", @"Too many arguments: ", 0);
    NWLLogWithFilter("tag", "lib", @"Too few arguments: %@ %@", @"");
    NWLLogWithFilter("tag", "lib", @"Too few arguments: %i %i", 1);
    NWLLogWithFilter("tag", "lib", @"Too few arguments: %i");
    NWLLogWithFilter("tag", "lib", @"String is no int: %i", @"");
    NWLLogWithFilter("tag", "lib", @"int is no String: %@", 1);
    NWLLogWithFilter("tag", "lib", @"double is no int: %i", .1);
    NWLLogWithFilter("tag", "lib", @"int is no double: %f", 1);
    NWLLogWithFilter("tag", "lib", @"long long is no int: %i", 1LL);
    NWLLogWithFilter("tag", "lib", @"int is no long long: %lli", 1);

#endif // RUN_NON_TESTS
}

- (void)testDump
{
#if RUN_NON_TESTS
    NWLRestore();
    NWLDump();
#endif // RUN_NON_TESTS
}

- (void)testAssert
{
#if RUN_NON_TESTS
    NWLRestore();
    BOOL yes = YES;
    NWAssert(yes == NO);
    NWAssertQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), com.apple.root.default-priority);
#endif // RUN_NON_TESTS
}

@end
