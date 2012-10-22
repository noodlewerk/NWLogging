//
//  NWLObjectiveCTest.m
//  NWLoggingTest
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#include "NWLObjectiveCTest.h"
#include "NWLCore.h"
#import "NWLLineLogger.h"

void NWLObjectiveCTest(id object) {

    NWLog(@"NWLObjectiveCTest");
    NSCAssert([NWLLineLogger.message isEqualToString:@"NWLObjectiveCTest"], @"%@", NWLLineLogger.message);

    NWLog(@"%@=%i %@", @"1", 1, object);
    NSCAssert([NWLLineLogger.ascii isEqualToString:@"1=1 [U245,U243,U20ac,$,U242,U20a1,U20a2,U20a3,U20a4,U20a5,U20a6,U20a7,U20a8,U20a9,U20aa,U20ab,U20ad,U20ae,U20af,U20b9,U89d2,U7530,U5bb6,Ud83cUdf35]"], @"%@", NWLLineLogger.message);

    NWLogWarn(@"%@=%i %@", @"1", 1, object);
    NSCAssert([NWLLineLogger.ascii isEqualToString:@"1=1 [U245,U243,U20ac,$,U242,U20a1,U20a2,U20a3,U20a4,U20a5,U20a6,U20a7,U20a8,U20a9,U20aa,U20ab,U20ad,U20ae,U20af,U20b9,U89d2,U7530,U5bb6,Ud83cUdf35]"], @"%@", NWLLineLogger.message);
}
