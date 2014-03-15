//
//  NWLAppDelegate.m
//  NWLoggingCocoaDemo
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLAppDelegate.h"

@implementation NWLAppDelegate {
    IBOutlet NWLLogView *_logView;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [NWLLogView class];
    [NWLMultiLogger.shared addPrinter:_logView];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [NWLMultiLogger.shared removePrinter:_logView];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
	return YES;
}

- (IBAction)run:(NSButton *)sender
{
    NWLClearAll();

    NWLog(@"       A| Welcome to the logging overview demo.");
    NWLog(@"       B| Let's log some text and see what happens where..");
    NWLog(@"       C| The NWLLog function prints even when no matching rules are active.");

    // printing on default tags info and warn
    NWLogInfo(@"-| This line should not be visible, because info is not yet on");
    NWLPrintInfoInLib(NWL_LIB_STR);

    NWLogInfo(@"D| The 'info' tag is activated, allowing the display of this line.");
    NWLog(@"       E| Now let's activate the 'warn' tag.");
    NWLogWarn(@"-| Obviously this line should not be visible, warn is not yet active");
    NWLPrintWarnInLib(NWL_LIB_STR);
    NWLogWarn(@"F| There we go, let this be a warning!");

    NWLClearInfo();
    NWLClearWarn();

    // custom tags
    NWLogTag(test, @"-| This is logged under tag 'test', which is not active");
    NWLPrintTag("tst1");
    NWLogTag(tst1, @"G| This is logged under tst1");
    NWLPrintTag("tst2");
    NWLogTag(tst2, @"H| This is logged under tst2");
    NWLPrintTag("tst3");
    NWLogTag(tst3, @"I| This is logged under tst3");
    NWLPrintTag("tst4");
    NWLogTag(tst4, @"J| This is logged under tst4");
    NWLog(@"       K| Let's take a look inside the logging facility to see:");
    NWLogAbout();

    NWLClearTag("tst1");
    NWLClearTag("tst2");
    NWLClearTag("tst3");
    NWLClearTag("tst4");

    // logging in C function
    runC();

    NWLogWarn(@"-| And of course this should not print nor break.");
    NWLPrintInfoInLib(NWL_LIB_STR);
    NWLogInfo(@"O| As a final demonstration, let's try out 'break', in 5 seconds.");

    NWLClearInfo();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        NWLBreakWarnInLib(NWL_LIB_STR);
        NWLogWarn(@"P| Tada! Now continue the debugger..");
        NWLPrintWarnInLib(NWL_LIB_STR);
        NWLogWarn(@"Q| That's it for this demo, thanks for watching.");

        // restore printers
        void *view = NWLRemovePrinter("demo-printer");
        CFBridgingRelease(view);
    });
}

static void runC() {
    NWLog(@"       L| This line is printed from a C function.");
    NWLogInfo(@"-| This line should not be visible, because info is not yet on");
    NWLPrintInfoInLib(NWL_LIB_STR);
    NWLogInfo(@"M| We're still in C, logging on 'info'.");
    NWLPrintTagInLib(NWL_LIB_STR, "C");
    NWLogTag(C, @"   N| And on the 'C' tag.");

    NWLClearInfo();
    NWLClearTag("C");
}


@end
