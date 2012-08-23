//
//  NWLLogView.h
//  NWLogging
//
//  Created by Leo on 8/22/12.
//
//

#import "NWLPrinter.h"

@interface NWLLogView : UITextView <NWLPrinter>

@property (nonatomic, assign) NSUInteger maxLogSize;

- (void)appendAndFollowText:(NSString *)text;
- (void)appendAndScrollText:(NSString *)text;
- (void)safeAppendAndFollowText:(NSString *)text;

- (void)scrollDown;

@end
