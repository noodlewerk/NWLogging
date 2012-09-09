//
//  NWLLogView.m
//  NWLogging
//
//  Created by Leo on 8/22/12.
//
//

#import "NWLLogView.h"
#import "NWLTools.h"

@implementation NWLLogView {
    NSMutableString *buffer;
    BOOL waitingToPrint;
    dispatch_queue_t serial;
}

@synthesize maxLogSize;

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    maxLogSize = 100 * 1000; // 100 KB
    serial = dispatch_queue_create("NWLLogViewController-append", DISPATCH_QUEUE_SERIAL);
    buffer = [[NSMutableString alloc] init];

#if TARGET_OS_IPHONE
    self.backgroundColor = UIColor.blackColor;
    self.textColor = UIColor.whiteColor;
    self.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10];
#else
    self.backgroundColor = NSColor.blackColor;
    self.textColor = NSColor.whiteColor;
    self.font = [NSFont fontWithName:@"Courier" size:10];
#endif
    self.editable = NO;
}

- (void)dealloc
{
    if (serial) dispatch_release(serial); serial = NULL;
}


#pragma mark - Printing

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message
{
    NSString *text = [NWLTools formatTag:tag lib:lib file:file line:line function:function message:message];
    [self safeAppendAndFollowText:text];
}

- (NSString *)name
{
    return @"log-view";
}


#pragma mark - Appending

- (void)safeAppendAndFollowText:(NSString *)text
{
    dispatch_async(serial, ^{
        if (waitingToPrint) {
            [buffer appendString:text];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self appendAndFollowText:text];
            });
            waitingToPrint = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2 * NSEC_PER_SEC), serial, ^(void){
                NSString *b = buffer;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self appendAndFollowText:b];
                });
                buffer = [[NSMutableString alloc] init];
                waitingToPrint = NO;
            });
        }
    });
}

- (void)appendAndScrollText:(NSString *)text
{
    [self append:text];
    [self scrollDown];
}

- (void)appendAndFollowText:(NSString *)text
{
    BOOL follow = [self isScrollAtEnd];
    [self append:text];
    if (follow) {
        [self scrollDown];
    }
}

- (void)append:(NSString *)string
{
#if TARGET_OS_IPHONE
    NSString *text = self.text;
#else
    NSString *text = self.string;
#endif
    text = [text stringByAppendingString:string];
    if (text.length > maxLogSize) {
        text = [text substringFromIndex:text.length - maxLogSize];
    }
#if TARGET_OS_IPHONE
    self.text = text;
#else
    self.string = text;
#endif
}


#pragma mark - Scrolling

- (void)scrollDown
{
    [self performSelector:@selector(scrollDownNow) withObject:nil afterDelay:.1];
}

- (void)scrollDownNow
{
#if TARGET_OS_IPHONE
    if (self.contentSize.height) {
        CGRect rect = CGRectMake(0, self.contentSize.height - 1, 1, 1);
        [self scrollRectToVisible:rect animated:YES];
    }
#endif
}

- (BOOL)isScrollAtEnd
{
#if TARGET_OS_IPHONE
    NSUInteger offset = self.contentOffset.y + self.bounds.size.height;
    NSUInteger size = self.contentSize.height;
    BOOL result = offset >= size - 50;
    return result;
#endif
    return NO;
}

@end
