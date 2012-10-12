//
//  NWLNonTest.m
//  NWLoggingTest
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#include "NWLCore.h"

//#define RUN_NON_TESTS 1


@interface NWLNonTest : SenTestCase @end

@implementation NWLNonTest

- (void)testDefaultPrinter
{
#if !RUN_NON_TESTS
    return;
#endif
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

- (void)testFormatWarnings
{
#if RUN_NON_TESTS
    return;
    
    NWLLogWithoutFilter(tag, lib, @"No warnings: %@ %i %f %lli", @"", 1, .1, 1LL);
    NWLLogWithoutFilter(tag, lib, @"Too many arguments: %@", @"", @"");
    NWLLogWithoutFilter(tag, lib, @"Too many arguments: %i", 1, 1);
    NWLLogWithoutFilter(tag, lib, @"Too many arguments: ", 0);
    NWLLogWithoutFilter(tag, lib, @"Too few arguments: %@ %@", @"");
    NWLLogWithoutFilter(tag, lib, @"Too few arguments: %i %i", 1);
    NWLLogWithoutFilter(tag, lib, @"Too few arguments: %i");
    NWLLogWithoutFilter(tag, lib, @"String is no int: %i", @"");
    NWLLogWithoutFilter(tag, lib, @"int is no String: %@", 1);
    NWLLogWithoutFilter(tag, lib, @"double is no int: %i", .1);
    NWLLogWithoutFilter(tag, lib, @"int is no double: %f", 1);
    NWLLogWithoutFilter(tag, lib, @"long long is no int: %i", 1LL);
    NWLLogWithoutFilter(tag, lib, @"int is no long long: %lli", 1);
    
    NWLLogWithFilter(tag, lib, @"No warnings: %@ %i %f %lli", @"", 1, .1, 1LL);
    NWLLogWithFilter(tag, lib, @"Too many arguments: %@", @"", @"");
    NWLLogWithFilter(tag, lib, @"Too many arguments: %i", 1, 1);
    NWLLogWithFilter(tag, lib, @"Too many arguments: ", 0);
    NWLLogWithFilter(tag, lib, @"Too few arguments: %@ %@", @"");
    NWLLogWithFilter(tag, lib, @"Too few arguments: %i %i", 1);
    NWLLogWithFilter(tag, lib, @"Too few arguments: %i");
    NWLLogWithFilter(tag, lib, @"String is no int: %i", @"");
    NWLLogWithFilter(tag, lib, @"int is no String: %@", 1);
    NWLLogWithFilter(tag, lib, @"double is no int: %i", .1);
    NWLLogWithFilter(tag, lib, @"int is no double: %f", 1);
    NWLLogWithFilter(tag, lib, @"long long is no int: %i", 1LL);
    NWLLogWithFilter(tag, lib, @"int is no long long: %lli", 1);
    
#endif
}

- (void)testDump
{
#if !RUN_NON_TESTS
    return;
#endif
    NWLRemoveAllFilters();
    NWLRemoveAllPrinters();
    NWLPrintInfo();
    NWLBreakWarn();
    NWLAddDefaultPrinter();
    NWLDump();
}

@end
