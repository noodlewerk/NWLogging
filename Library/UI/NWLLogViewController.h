//
//  NWLLogViewController.h
//  NWLogging
//
//  Created by leonard on 6/7/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLPrinter.h"

@class NWLFilePrinter, NWLMultiLogger;

@interface NWLLogViewController : UIViewController <NWLPrinter>

@property (nonatomic, assign) BOOL compressAttachment;

- (void)addText:(NSString *)text;
- (void)addEmailButton:(NSString *)address;
- (void)addClearButton:(void(^)(void))block;
- (void)addDoneButton;

- (void)configureWithFilePrinter:(NWLFilePrinter *)printer;
- (void)configureWithMultiLogger:(NWLMultiLogger *)logger;

@end
