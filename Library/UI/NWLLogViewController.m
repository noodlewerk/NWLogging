//
//  NWLLogViewController.m
//  NWLogging
//
//  Created by leonard on 6/7/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLLogViewController.h"
#import "NWLCore.h"
#import "NWLTools.h"
#import "NWLFilePrinter.h"
#import "NWLMultiLogger.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#include <zlib.h>

@interface NWLFilter : NSObject
@property (nonatomic, assign) const char *tag;
@property (nonatomic, assign) const char *lib;
@property (nonatomic, assign) const char *file;
@property (nonatomic, assign) const char *function;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, readonly) NSString *text;
@end

@interface NWLFilterViewController : UITableViewController
- (void)loadFilters:(NSArray *)filters;
@end


@implementation NWLLogViewController {
    UITextView *textView;
    dispatch_queue_t serial;
    NSCalendar *calendar;
    NSMutableArray *emailAddresses;
    void(^clearBlock)(void);
    NWLMultiLogger *logger;
    NSMutableArray *filters;
}

@synthesize compressAttachment;


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
    return YES;
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
    
    // attach file
    NSData *data = [textView.text dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filename = NSLocalizedString(@"NWLoggingEmail_File", @"");
    NSString *mime = @"text/plain";
    if (compressAttachment) {
        NSData *compressed = [self.class compress:data];
        if (compressed.length) {
            data = compressed;
            filename = [filename stringByAppendingString:@".gzip"];
            mime = @"application/gzip";
        }
    }
    [mailController addAttachmentData:data mimeType:mime fileName:filename];
    
    [self presentViewController:mailController animated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

+ (NSData *)compress:(NSData *)data
{
    if (data.length) {
        z_stream stream;
        memset(&stream, 0, sizeof(z_stream));
        stream.next_in = (Bytef *)data.bytes;
        stream.avail_in = data.length;
        int status = deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY);
        if (status == Z_OK) {
            NSMutableData *result = [[NSMutableData alloc] initWithLength:data.length * 1.01 + 12];
            while (status == Z_OK) {
                stream.next_out = result.mutableBytes + stream.total_out;
                stream.avail_out = result.length - stream.total_out;
                status = deflate(&stream, Z_FINISH);
            }
            deflateEnd(&stream);
            if (status == Z_STREAM_END) {
                result.length = stream.total_out;
                return result;
            }
        }
    }
    return nil;
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


#pragma mark - About button

- (void)addAboutButton
{
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(printAbout)];
    [buttons addObject:item];
    self.navigationItem.rightBarButtonItems = buttons;
}

- (void)printAbout
{
    NWLAbout();
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


#pragma mark - Filtering

- (void)addFilterWithTag:(const char *)tag lib:(const char *)lib file:(const char *)file function:(const char *)function
{
    NWLFilter *filter = [[NWLFilter alloc] init];
    filter.tag = tag;
    filter.lib = lib;
    filter.file = file;
    filter.function = function;
    if (!filters) {
        filters = [[NSMutableArray alloc] init];
        [self addFilterButton];
    }
    [filters addObject:filter];
}

- (void)addFilterButton
{
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showFilters)];
    [buttons addObject:item];
    self.navigationItem.rightBarButtonItems = buttons;
}

- (void)showFilters
{
    NWLFilterViewController *controller = [[NWLFilterViewController alloc] initWithStyle:UITableViewStylePlain];
    [controller loadFilters:filters];
    controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:controller action:@selector(dismissModalViewControllerAnimated:)];
    UINavigationController *c = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentModalViewController:c animated:YES];
}

- (void)addDefaultFilters
{
    [self addDefaultFiltersForLib:NULL];
}

- (void)addDefaultFiltersForLib:(const char *)lib
{
    [self addFilterWithTag:NULL lib:lib file:NULL function:NULL];
    [self addFilterWithTag:"warn" lib:lib file:NULL function:NULL];
    [self addFilterWithTag:"info" lib:lib file:NULL function:NULL];
    [self addFilterWithTag:"dbug" lib:lib file:NULL function:NULL];
}


@end


@implementation NWLFilter

@synthesize tag, lib, file, function;

- (NSString *)text
{
    NSMutableString *result = [[NSMutableString alloc] init];
    if (tag) {
        [result appendFormat:@"tag:%s ", tag];
    }
    if (lib) {
        [result appendFormat:@"lib:%s ", lib];
    }
    if (file) {
        [result appendFormat:@"file:%s ", file];
    }
    if (function) {
        [result appendFormat:@"function:%s ", function];
    }
    if (!result.length) {
        [result appendString:@"ALL"];
    }
   return result;
}

- (BOOL)active
{
    NWLAction action = NWLHasFilter(tag, lib, file, function);
    BOOL result = (action != kNWLAction_none);
    return result;
}

- (void)setActive:(BOOL)active
{
    NWLAction action = active ? kNWLAction_print : kNWLAction_none;
    NWLAddFilter(tag, lib, file, function, action);
}

@end


@implementation NWLFilterViewController {
    NSArray *filters;
}

- (void)loadFilters:(NSArray *)_filters
{
    filters = _filters;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return filters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    NWLFilter *filter = [filters objectAtIndex:indexPath.row];
    cell.textLabel.text = filter.text;
    cell.accessoryType = filter.active ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    BOOL checked = cell.accessoryType == UITableViewCellAccessoryCheckmark;
    cell.accessoryType = checked ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    NWLFilter *filter = [filters objectAtIndex:indexPath.row];
    filter.active = !checked;
    NWLDump();
}

@end

