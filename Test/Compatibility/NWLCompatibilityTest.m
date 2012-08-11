//
//  NWLCompatibilityTest.m
//  NWLogging
//
//  Created by leonard on 6/10/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#include "NWLCTest.h"
#include "NWLCppTest.h"
#include "NWLObjectiveCTest.h"
#include "NWLObjectiveCppTest.h"

#import "NWLLineLogger.h"


@interface NWLCompatibilityTest : SenTestCase @end

@implementation NWLCompatibilityTest {
    NSString *description;
}

- (void)setUp
{
    [super setUp];
    
    NWLRemoveAllPrinters();
    [NWLLineLogger start];
}

- (void)testCompiler
{
    NSString *encoded = @"[\\245,\\243,\\u20ac,$,\\242,\\u20a1,\\u20a2,\\u20a3,\\u20a4,\\u20a5,\\u20a6,\\u20a7,\\u20a8,\\u20a9,\\u20aa,\\u20ab,\\u20ad,\\u20ae,\\u20af,\\u20b9,\\u89d2,\\u7530,\\u5bb6,\\ud83c\\udf35]";
    NSString *utf8 = [[NSString alloc] initWithData:[encoded dataUsingEncoding:NSASCIIStringEncoding] encoding:NSNonLossyASCIIStringEncoding];
    description = utf8;
    
    NWLCTest((__bridge void *)self);
    NWLCppTest((__bridge void *)self);
    NWLObjectiveCTest(self);
    NWLObjectiveCppTest(self);
    [self NWLInObjectTest:self];
    [self.class NWLInClassTest:self];
    
    description = nil;
}

- (void)NWLInObjectTest:(id)object
{
    NWLog(@"NWLInObjectTest");
    STAssertEqualObjects(NWLLineLogger.message, @"NWLInObjectTest", @"");
    NWLog(@"%@=%i %@", @"1", 1, object);
    STAssertEqualObjects(NWLLineLogger.ascii, @"1=1 [U245,U243,U20ac,$,U242,U20a1,U20a2,U20a3,U20a4,U20a5,U20a6,U20a7,U20a8,U20a9,U20aa,U20ab,U20ad,U20ae,U20af,U20b9,U89d2,U7530,U5bb6,Ud83cUdf35]", @"");
    NWLogWarn(@"%@=%i %@", @"1", 1, object);
    STAssertEqualObjects(NWLLineLogger.ascii, @"1=1 [U245,U243,U20ac,$,U242,U20a1,U20a2,U20a3,U20a4,U20a5,U20a6,U20a7,U20a8,U20a9,U20aa,U20ab,U20ad,U20ae,U20af,U20b9,U89d2,U7530,U5bb6,Ud83cUdf35]", @"");
}

+ (void)NWLInClassTest:(id)object
{
    NWLog(@"NWLInObjectTest");
    NSAssert([NWLLineLogger.message isEqualToString:@"NWLInObjectTest"], @"");
    NWLog(@"%@=%i %@", @"1", 1, object);
    NSAssert([NWLLineLogger.ascii isEqualToString:@"1=1 [U245,U243,U20ac,$,U242,U20a1,U20a2,U20a3,U20a4,U20a5,U20a6,U20a7,U20a8,U20a9,U20aa,U20ab,U20ad,U20ae,U20af,U20b9,U89d2,U7530,U5bb6,Ud83cUdf35]"], @"%@", NWLLineLogger.message);
    NWLogWarn(@"%@=%i %@", @"1", 1, object);
    NSAssert([NWLLineLogger.ascii isEqualToString:@"1=1 [U245,U243,U20ac,$,U242,U20a1,U20a2,U20a3,U20a4,U20a5,U20a6,U20a7,U20a8,U20a9,U20aa,U20ab,U20ad,U20ae,U20af,U20b9,U89d2,U7530,U5bb6,Ud83cUdf35]"], @"%@", NWLLineLogger.message);
}

- (NSString *)description
{
    return description ? description : [super description];
}

@end
