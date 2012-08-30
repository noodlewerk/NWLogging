//
//  NWLPerformanceViewController.m
//  NWLogging
//
//  Created by leonard on 4/25/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLPerformanceViewController.h"


@implementation NWLPerformanceViewController {
    NWLLogView *logView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Performance";
    
    UITextView *about = [[UITextView alloc] init];
    about.textAlignment = UITextAlignmentLeft;
    about.font = [UIFont systemFontOfSize:10];
    about.editable = NO;
    about.text = @"The performance demo puts NWLogging to the test of handling concurrent logging and configuration. After pressing 'Run', eight concurrent operations are started which all perform random operations on NWLogging. These operations include the adding and removing of filters and printers, and of course actual logging. This stress test does not attempt to mimic average use, but instead that it doesn't easily crash :).\n \nKeep an eye on the console output to see what is actually happening. Press 'Run' multiple times to run multiple tests concurrently.";
    CGFloat height = [about.text sizeWithFont:about.font constrainedToSize:CGSizeMake(self.view.bounds.size.width - 20, 1000) lineBreakMode:UILineBreakModeWordWrap].height + 10;
    about.frame = CGRectMake(10, 10, self.view.bounds.size.width - 20, height);
    [self.view addSubview:about];

    UIButton *timeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    timeButton.frame = CGRectMake(10, 20 + height, self.view.bounds.size.width / 2 - 20, 40);
    [timeButton setTitle:@"Timing" forState:UIControlStateNormal];
    [timeButton addTarget:self action:@selector(runTimingAsync) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:timeButton];    
    
    UIButton *randButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    randButton.frame = CGRectMake(self.view.bounds.size.width / 2 + 10, 20 + height, self.view.bounds.size.width / 2 - 20, 40);
    [randButton setTitle:@"Concurrency" forState:UIControlStateNormal];
    [randButton addTarget:self action:@selector(runRandomAsync) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:randButton];    
    
    logView = [[NWLLogView alloc] init];
    logView.frame = CGRectMake(10, 70 + height, self.view.bounds.size.width - 20, self.view.bounds.size.height - 130 - height);
    [self.view addSubview:logView];
}

- (void)runTimingAsync
{
    [logView safeAppendAndFollowText:@"\n == Logging Time Demo == \n\n"];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        [self runTiming:1];
    }];
}

- (void)appendLine:(NSString *)line
{
    [logView safeAppendAndFollowText:[line stringByAppendingString:@"\n"]];
}

#define LOG_Empty @""
#define LOG_String @"This is a medium-size string with a length of 60 characters."
#define LOG_Format @"This is a medium-size string with a length of %i %@.", 60, @"characters"

#define LOG_TEST(_a, _b) {\
        NSTimeInterval i = 0;\
        NSUInteger k = 0;\
        while (i < span) {\
            i -= [NSDate.date timeIntervalSince1970];\
            for (NSUInteger j = 0; j < 1000; j++) _a(LOG_##_b);\
            k += 1000;\
            i += [NSDate.date timeIntervalSince1970];\
        }\
        [self appendLine:[NSString stringWithFormat:@"%10s %6s: %6.2fus", #_a, #_b, i * 1000000 / k]];\
    }

- (void)runTiming:(NSTimeInterval)span
{
    
    NWLRemoveAllFilters();
    NWLRemoveAllPrinters();

    [self appendLine:[NSString stringWithFormat:@"Deativated all filters and printers.\n"]];

    LOG_TEST(NWLog, Empty);
    LOG_TEST(NWLog, String);
    LOG_TEST(NWLog, Format);
    
    [self appendLine:@""];
    
    LOG_TEST(NWLogWarn, Empty);
    LOG_TEST(NWLogWarn, String);
    LOG_TEST(NWLogWarn, Format);

    NWLRestoreDefaultFilters();
    [self appendLine:[NSString stringWithFormat:@"\nActivated 'warn' filter, but no printers.\n"]];
    
    LOG_TEST(NWLog, Empty);
    LOG_TEST(NWLog, String);
    LOG_TEST(NWLog, Format);
    
    [self appendLine:@""];
    
    LOG_TEST(NWLogWarn, Empty);
    LOG_TEST(NWLogWarn, String);
    LOG_TEST(NWLogWarn, Format);
    
    NWLRestoreDefaultPrinters();
    [self appendLine:[NSString stringWithFormat:@"\nActivated 'warn' filter and console printer.\n"]];
    
    LOG_TEST(NWLog, Empty);
    LOG_TEST(NWLog, String);
    LOG_TEST(NWLog, Format);
    
    [self appendLine:@""];
    
    span /= 10; // to reduce console flooding
    
    LOG_TEST(NWLogWarn, Empty);
    LOG_TEST(NWLogWarn, String);
    LOG_TEST(NWLogWarn, Format);
    
    [self appendLine:[NSString stringWithFormat:@"\nFin.\n"]];
}

- (void)runRandomAsync
{
    [logView safeAppendAndFollowText:@"\n == Logging Concurrency Demo == \n\n"];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        [self runRandom:1];
    }];
}

- (void)runRandom:(NSTimeInterval)span
{
    [self appendLine:[NSString stringWithFormat:@"Keep an eye on the console output..."]];

    static const NSUInteger indicesSize = 23; // see also switch case below
    NSUInteger indicesBuffer[indicesSize];
    memset(indicesBuffer, 0, sizeof(indicesBuffer));
    NSUInteger *indices = indicesBuffer;
    __block NSUInteger indicesCount = indicesSize;
    __block BOOL stop = NO;
    __block NSUInteger total = 0;
    void(^block)(void) = ^{
        NSUInteger count = 0;
        for (;!stop; count++) {
            static NSUInteger x = INT_MAX;
            if (x++ > 300) {
                x = 0;
#define RAND(__a) (NSUInteger)((__a) * (1.f * rand() / RAND_MAX))
                indicesCount = RAND(indicesSize - (indicesSize / 2)) + (indicesSize / 2);
                for (NSUInteger i = 0; i < indicesCount; i++) {
                    indices[i] = RAND(indicesSize);
                }
            }
            NSUInteger index = indices[RAND(indicesCount)];
            switch (index) {
                case 0: NWLClearAll(); break;
                case 1: NWLPrintInfoInLib(NWL_LIB_STR); break;
                case 2: NWLPrintDbugInLib(NWL_LIB_STR); break;
                case 3: NWLPrintWarnInLib(NWL_LIB_STR); break;
                case 4: NWLPrintDbugInFile("NWLPerformanceViewController.m"); break;
                case 5: NWLPrintDbugInFunction("-[NWLPerformanceViewController runRandom:]"); break;
                case 6: NWLogInfo(@"%@", @"NWLLogInfo"); break;
                case 7: NWLogWarn(@"%@", @"NWLLogWarn"); break;
                case 8: NWLPrintTagInLib(NWL_LIB_STR, "a"); break;
                case 9: NWLPrintTagInLib(NWL_LIB_STR, "b"); break;
                case 10: NWLPrintTagInLib(NWL_LIB_STR, "c"); break;
                case 11: NWLPrintTagInLib(NWL_LIB_STR, "d"); break;
                case 12: NWLogTag(a, @"%@", @"a"); break;
                case 13: NWLogTag(b, @"%@", @"b"); break;
                case 14: NWLogTag(c, @"%@", @"c"); break;
                case 15: NWLogTag(d, @"%@", @"d"); break;
                case 16: NWLogInfo(@"%@", @"NWLLogInfo"); break;
                case 17: NWLogWarn(@"%@", @"NWLLogWarn"); break;
                case 18: NWLogInfo(@"%@", @"NWLLogInfo"); break;
                case 19: NWLogWarn(@"%@", @"NWLLogWarn"); break;
                case 20: NWLResetPrintClock(); break;
                case 21: NWLRestorePrintClock(); break;
                case 22: NWLogAbout(); break;
                default: abort(); // see also declaration of indicesSize
            }
        }
        total += count;
    };
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:block];
    [queue addOperationWithBlock:block];
    [queue addOperationWithBlock:block];
    [queue addOperationWithBlock:block];
    [queue addOperationWithBlock:block];
    [queue addOperationWithBlock:block];
    [queue addOperationWithBlock:block];
    [queue addOperationWithBlock:block];
    [NSThread sleepForTimeInterval:span];
    stop = YES;
    [NSThread sleepForTimeInterval:.1];
    
    [self appendLine:[NSString stringWithFormat:@"\n.. done, that's about %u concurrent operations per second.\n", ((NSUInteger)(total / span) / 1000) * 1000]];
}

@end
