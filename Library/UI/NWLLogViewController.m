//
//  NWLLogViewController.m
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLLogViewController.h"
#import "NWLCore.h"
#import "NWLTools.h"
#import "NWLFilePrinter.h"
#import "NWLMultiLogger.h"
#import "NWLLogView.h"
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
    NWLLogView *_textView;
    NSMutableArray *_emailAddresses;
    BOOL _compressAttachment;
    NSDictionary *_additionalAttachments;
    void(^_clearBlock)(void);
    NWLMultiLogger *_logger;
    NSMutableArray *_filters;
}


#pragma mark - View life cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _textView = [[NWLLogView alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _textView.frame = self.view.bounds;
    _textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_textView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _textView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_logger addPrinter:_textView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_logger removePrinter:_textView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)appendText:(NSString *)text
{
    [_textView appendAndScrollText:text];
}


#pragma mark - Clear button

- (void)addClearButton:(void (^)(void))block
{
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearLogs)];
    [buttons addObject:item];
    self.navigationItem.rightBarButtonItems = buttons;
    _clearBlock = [block copy];
}

- (void)clearLogs
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NWLoggingClear_Title", @"") message:NSLocalizedString(@"NWLoggingClear_Text", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"NWLoggingClear_No", @"") otherButtonTitles:NSLocalizedString(@"NWLoggingClear_Yes", @""), nil];
    alert.tag = 1237;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != alertView.cancelButtonIndex && alertView.tag == 1237){
        _textView.text = @"";
        if (_clearBlock) _clearBlock();
    }
}


#pragma mark - Email button

- (void)addEmailButton:(NSString *)address compressAttachment:(BOOL)compressAttachment;
{
    [self addEmailButton:address additionalAttachments:nil compress:compressAttachment];
}

- (void)addEmailButton:(NSString *)address additionalAttachments:(NSDictionary *)additional compress:(BOOL)compress
{
    if (!_emailAddresses.count) {
        NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(emailLogs)];
        [buttons addObject:item];
        self.navigationItem.rightBarButtonItems = buttons;
        _emailAddresses = [NSMutableArray array];
        _compressAttachment = compress;
        _additionalAttachments = additional;
    }
    [_emailAddresses addObject:[address copy]];
}

- (void)emailLogs
{
    MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
    [mailController setMailComposeDelegate:(id<MFMailComposeViewControllerDelegate>)self];
    [mailController setSubject:NSLocalizedString(@"NWLoggingEmail_Subject", @"")];
    if (_emailAddresses.count) {
        [mailController setToRecipients:_emailAddresses];
    }
    [mailController setMessageBody:NSLocalizedString(@"NWLoggingEmail_Text", @"") isHTML:NO];

    // attach files
    NSMutableDictionary *files = [[NSMutableDictionary alloc] initWithCapacity:_additionalAttachments.count + 1];
    NSData *logData = [_textView.text dataUsingEncoding:NSUTF8StringEncoding];
    NSString *logName = NSLocalizedString(@"NWLoggingEmail_File", @"");
    if (logData.length && logName.length) {
        files[logName] = logData;
    }
    for (NSString *key in _additionalAttachments) {
        id value = _additionalAttachments[key];
        if ([value isKindOfClass:NSData.class]) {
            files[key] = value;
        } else if ([value isKindOfClass:NSURL.class]) {
            NSData *data = [NSData dataWithContentsOfURL:value];
            if (data) files[key] = data;
        } else {
            NSData *data = [[value description] dataUsingEncoding:NSUTF8StringEncoding];
            if (data) files[key] = data;
        }
    }
    for (NSString *key in files) {
        NSData *data = files[key];
        NSString *filename = key;
        NSString *mime = @"text/plain";
        if (_compressAttachment) {
            NSData *compressed = [self.class compress:data];
            if (compressed.length) {
                data = compressed;
                filename = [filename stringByAppendingString:@".gzip"];
                mime = @"application/gzip";
            }
        }
        [mailController addAttachmentData:data mimeType:mime fileName:filename];
    }

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
        stream.avail_in = (uInt)data.length;
        int status = deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY);
        if (status == Z_OK) {
            NSMutableData *result = [[NSMutableData alloc] initWithLength:data.length * 1.1 + 32];
            while (status == Z_OK) {
                stream.next_out = result.mutableBytes + stream.total_out;
                stream.avail_out = (uInt)(result.length - stream.total_out);
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
    char buffer[1024];
    NWLAboutString(buffer, sizeof(buffer));
    NSString *about = [NSString stringWithFormat:@"%s", buffer];
    [_textView appendAndScrollText:about];
}

#pragma mark - Convenient configuration

- (void)configureWithFilePrinter:(NWLFilePrinter *)printer
{
    if (printer) {
        [self addClearButton:^{
            [printer clear];
        }];
        NSString *text = [NSString stringWithContentsOfFile:printer.path encoding:NSUTF8StringEncoding error:nil];
        [_textView appendAndScrollText:text];
    }
}

- (void)configureWithMultiLogger:(NWLMultiLogger *)logger
{
    _logger = logger;
}


#pragma mark - Filtering

- (void)addFilterWithTag:(const char *)tag lib:(const char *)lib file:(const char *)file function:(const char *)function
{
    NWLFilter *filter = [[NWLFilter alloc] init];
    filter.tag = tag;
    filter.lib = lib;
    filter.file = file;
    filter.function = function;
    if (!_filters) {
        _filters = [[NSMutableArray alloc] init];
        [self addFilterButton];
    }
    [_filters addObject:filter];
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
    [controller loadFilters:_filters];
    controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:controller action:@selector(dismissModalViewControllerAnimated:)];
    UINavigationController *c = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:c animated:YES completion:nil];
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

- (NSString *)text
{
    NSMutableString *result = [[NSMutableString alloc] init];
    if (_tag) {
        [result appendFormat:@"tag:%s ", _tag];
    }
    if (_lib) {
        [result appendFormat:@"lib:%s ", _lib];
    }
    if (_file) {
        [result appendFormat:@"file:%s ", _file];
    }
    if (_function) {
        [result appendFormat:@"function:%s ", _function];
    }
    if (!result.length) {
        [result appendString:@"ALL"];
    }
   return result;
}

- (BOOL)active
{
    NWLAction action = NWLHasFilter(_tag, _lib, _file, _function);
    BOOL result = (action != kNWLAction_none);
    return result;
}

- (void)setActive:(BOOL)active
{
    if (self.active ^ active) {
        NWLAction action = active ? kNWLAction_print : kNWLAction_none;
        NWLAddFilter(_tag, _lib, _file, _function, action);
    }
}

@end


@implementation NWLFilterViewController {
    NSArray *_filters;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(uncheckAll)];
    [buttons addObject:item];
    self.navigationItem.rightBarButtonItems = buttons;
}

- (void)uncheckAll
{
    for (NWLFilter *filter in _filters) {
        filter.active = NO;
    }
    [self.tableView reloadData];
}

- (void)loadFilters:(NSArray *)filters
{
    _filters = filters;
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
    return _filters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    NWLFilter *filter = [_filters objectAtIndex:indexPath.row];
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
    NWLFilter *filter = [_filters objectAtIndex:indexPath.row];
    filter.active = !checked;
}

@end

