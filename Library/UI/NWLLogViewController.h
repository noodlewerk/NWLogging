//
//  NWLLogViewController.h
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLPrinter.h"
#include "TargetConditionals.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

@class NWLFilePrinter, NWLMultiLogger;

@interface NWLLogViewController : UIViewController

- (void)appendText:(NSString *)text;

- (void)addEmailButton:(NSString *)address compressAttachment:(BOOL)compressAttachment;
- (void)addEmailButton:(NSString *)address additionalAttachments:(NSDictionary *)additional compress:(BOOL)compress;
- (void)addClearButton:(void(^)(void))block;
- (void)addDoneButton;
- (void)addAboutButton;

- (void)addDefaultFilters;
- (void)addDefaultFiltersForLib:(const char *)lib;
- (void)addFilterWithTag:(const char *)tag lib:(const char *)lib file:(const char *)file function:(const char *)function;

- (void)configureWithFilePrinter:(NWLFilePrinter *)printer;
- (void)configureWithMultiLogger:(NWLMultiLogger *)logger;

@end

#endif // TARGET_OS_IPHONE