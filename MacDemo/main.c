//
//  main.c
//  NWLoggingMacDemo
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include "NWLogging.h"


void demo(void)
{
    NWLClearAll();

    NWLog("       A| Welcome to the logging overview demo.");
    NWLog("       B| Let's log some text and see what happens where..");
    NWLog("       C| The NWLLog function prints even when no matching rules are active.");

    // printing on default tags info and warn
    NWLogInfo("-| This line should not be visible, because info is not yet on");
    NWLPrintInfoInLib(NWL_LIB_STR);

    NWLogInfo("D| The 'info' tag is activated, allowing the display of this line.");
    NWLog("       E| Now let's activate the 'warn' tag.");
    NWLogWarn("-| Obviously this line should not be visible, warn is not yet active");
    NWLPrintWarnInLib(NWL_LIB_STR);
    NWLogWarn("F| There we go, let this be a warning!");

    NWLClearInfo();
    NWLClearWarn();

    // custom tags
    NWLogTag(test, "-| This is logged under tag 'test', which is not active");
    NWLPrintTag("tst1");
    NWLogTag(tst1, "G| This is logged under tst1");
    NWLPrintTag("tst2");
    NWLogTag(tst2, "H| This is logged under tst2");
    NWLPrintTag("tst3");
    NWLogTag(tst3, "I| This is logged under tst3");
    NWLPrintTag("tst4");
    NWLogTag(tst4, "J| This is logged under tst4");
    NWLog("       K| Let's take a look inside the logging facility to see:");
    NWLogAbout();

    NWLClearTag("tst1");
    NWLClearTag("tst2");
    NWLClearTag("tst3");
    NWLClearTag("tst4");

    NWLogWarn("-| And of course this should not print nor break.");
    NWLPrintInfoInLib(NWL_LIB_STR);
    NWLogInfo("L| As a final demonstration, let's try out 'break', in 5 seconds.");

    NWLClearInfo();

    sleep(5);

    NWLBreakWarnInLib(NWL_LIB_STR);
    NWLogWarn("M| Tada! Now continue the debugger..");
    NWLPrintWarnInLib(NWL_LIB_STR);
    NWLogWarn("N| That's it for this demo, thanks for watching.");
}

int main(int argc, const char * argv[])
{
    demo();
    return 0;
}
