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

- (void)setup
{
    maxLogSize = 100 * 1000; // 100 KB
    serial = dispatch_queue_create("NWLLogViewController-append", DISPATCH_QUEUE_SERIAL);
    buffer = [[NSMutableString alloc] init];

    self.backgroundColor = UIColor.blackColor;
    self.textColor = UIColor.whiteColor;
    self.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10]; // Courier-Bold or CourierNewPS-BoldMT
    self.editable = NO;
}

- (void)dealloc
{
    if (serial) dispatch_release(serial); serial = NULL;
}

#pragma mark - Printing

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message
{
    NSString *s = [NWLTools formatTag:tag lib:lib file:file line:line function:function message:message];
    dispatch_async(serial, ^{
        if (waitingToPrint) {
            [buffer appendString:s];
        } else {
            [self safeAppendAndFollowText:s];
            waitingToPrint = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2 * NSEC_PER_SEC), serial, ^(void){
                [self safeAppendAndFollowText:buffer];
                buffer = [[NSMutableString alloc] init];
                waitingToPrint = NO;
            });
        }
    });
}

- (NSString *)name
{
    return @"log-view";
}


#pragma mark - Appending

- (void)safeAppendAndFollowText:(NSString *)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendAndFollowText:text];
    });
}

- (void)appendAndFollowText:(NSString *)text
{
    [self append:text];
    [self scrollDown];
}

- (void)appendAndScrollText:(NSString *)text
{
    BOOL scroll = [self isScrollAtEnd];
    [self append:text];
    if (scroll) {
        [self scrollDown];
    }
}

- (void)append:(NSString *)string
{
    NSString *text = [self.text stringByAppendingString:string];
    if (text.length > maxLogSize) {
        text = [text substringFromIndex:text.length - maxLogSize];
    }
    self.text = text;
}


#pragma mark - Scrolling

- (void)scrollDown
{
    [self performSelector:@selector(scrollDownNow) withObject:nil afterDelay:.1];    
}

- (void)scrollDownNow
{
    if (self.contentSize.height) {
        CGRect rect = CGRectMake(0, self.contentSize.height - 1, 1, 1);
        [self scrollRectToVisible:rect animated:YES];
    }
}

- (BOOL)isScrollAtEnd
{
    NSUInteger offset = self.contentOffset.y + self.bounds.size.height;
    NSUInteger size = self.contentSize.height;
    BOOL result = offset >= size - 50;
    return result;
}

@end
