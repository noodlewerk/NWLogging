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

@property (nonatomic, assign) NSUInteger maxLogSize;
@property (nonatomic, assign) BOOL compressAttachment;

- (void)addText:(NSString *)text;
- (void)addEmailButton:(NSString *)address;
- (void)addClearButton:(void(^)(void))block;
- (void)addDoneButton;
- (void)addAboutButton;

- (void)addDefaultFilters;
- (void)addDefaultFiltersForLib:(const char *)lib;
- (void)addFilterWithTag:(const char *)tag lib:(const char *)lib file:(const char *)file function:(const char *)function;

- (void)configureWithFilePrinter:(NWLFilePrinter *)printer;
- (void)configureWithMultiLogger:(NWLMultiLogger *)logger;

@end
