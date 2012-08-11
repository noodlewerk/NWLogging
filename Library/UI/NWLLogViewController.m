//
//  NWLLogViewController.m
//  NWLogging
//
//  Created by leonard on 6/7/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLLogViewController.h"
#import "NWLTools.h"
#import "NWLFilePrinter.h"
#import "NWLMultiLogger.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@implementation NWLLogViewController {
    UITextView *textView;
    dispatch_queue_t serial;
    NSCalendar *calendar;
    NSMutableArray *emailAddresses;
    void(^clearBlock)(void);
    NWLMultiLogger *logger;
}


#pragma mark - View life cycle

- (id)init
{
    self = [super init];
    if (self) {
        calendar = NSCalendar.currentCalendar;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    textView = [[UITextView alloc] initWithFrame:CGRectZero];
    textView.frame = self.view.bounds;
    textView.backgroundColor = UIColor.blackColor;
    textView.textColor = UIColor.whiteColor;
    textView.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10]; // Courier-Bold or CourierNewPS-BoldMT
    textView.editable = NO;
    textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:textView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    textView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [logger addPrinter:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [logger removePrinter:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.presentingViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - Printing

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *s = [NWLTools formatTag:tag lib:lib file:file line:line function:function message:message];
        textView.text = [textView.text stringByAppendingString:s];
        [self performSelector:@selector(follow) withObject:nil afterDelay:0];
    });
}

- (void)addText:(NSString *)text
{
    if (text.length) {
        dispatch_async(dispatch_get_main_queue(), ^{
            textView.text = [textView.text stringByAppendingString:text];
            [self performSelector:@selector(scrollDown) withObject:nil afterDelay:1];
        });
    }
}

- (void)scrollDown
{
    if (textView.contentSize.height) {
        CGRect rect = CGRectMake(0, textView.contentSize.height - 1, 1, 1);
        [textView scrollRectToVisible:rect animated:YES];
    }
}

- (void)follow
{
    NSUInteger offset = textView.contentOffset.y + textView.bounds.size.height;
    NSUInteger size = textView.contentSize.height;
    if (offset >= size - 100) {
        [self scrollDown];
    }
}


#pragma mark - Clear button

- (void)addClearButton:(void (^)(void))block
{
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearLogs)];
    [buttons addObject:item];
    self.navigationItem.rightBarButtonItems = buttons;
    clearBlock = [block copy];
}

- (void)clearLogs
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NWLoggingClear_Title", @"") message:NSLocalizedString(@"NWLoggingClear_Text", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"NWLoggingClear_No", @"") otherButtonTitles:NSLocalizedString(@"NWLoggingClear_Yes", @""), nil];
    alert.tag = 1237;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != alertView.cancelButtonIndex && alertView.tag == 1237){
        textView.text = @"";
        if (clearBlock) clearBlock();
    }
}


#pragma mark - Email button

- (void)addEmailButton:(NSString *)address
{
    if (!emailAddresses.count) {
        NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(emailLogs)];
        [buttons addObject:item];
        self.navigationItem.rightBarButtonItems = buttons;
        emailAddresses = [NSMutableArray array];
    }
    [emailAddresses addObject:[address copy]];
}

- (void)emailLogs
{
    MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
    [mailController setMailComposeDelegate:(id<MFMailComposeViewControllerDelegate>)self];
    [mailController setSubject:NSLocalizedString(@"NWLoggingEmail_Subject", @"")];
    if (emailAddresses.count) {
        [mailController setToRecipients:emailAddresses];
    }
    [mailController setMessageBody:NSLocalizedString(@"NWLoggingEmail_Text", @"") isHTML:NO];
    NSData *data = [textView.text dataUsingEncoding:NSUTF8StringEncoding];
    [mailController addAttachmentData:data mimeType:@"text/plain" fileName:NSLocalizedString(@"NWLoggingEmail_File", @"")];
    [self presentViewController:mailController animated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - Done button

- (void)addDoneButton
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissByDone)];
}

- (void)dismissByDone
{
    [self dismissModalViewControllerAnimated:YES];  
}


#pragma mark - Convenient configuration

- (void)configureWithFilePrinter:(NWLFilePrinter *)printer
{
    if (printer) {
        [self addClearButton:^{
            [printer clear];
        }];
        NSString *text = [NSString stringWithContentsOfFile:printer.path encoding:NSUTF8StringEncoding error:nil];
        [self addText:text];
    }
}

- (void)configureWithMultiLogger:(NWLMultiLogger *)_logger
{
    logger = _logger;
}

@end
