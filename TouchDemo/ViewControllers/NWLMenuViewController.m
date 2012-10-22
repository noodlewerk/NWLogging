//
//  NWLMenuViewController.m
//  NWLoggingTouchDemo
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLMenuViewController.h"
#import "NWLIntroViewController.h"
#import "NWLPerformanceViewController.h"
#import "NWLPersistentViewController.h"
#import "NWLLogViewController.h"


@implementation NWLMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NWAssertMainThread();
    self.title = @"NWLogging Demo";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    switch (indexPath.row) {
        case 0: cell.textLabel.text = @"Introduction"; break;
        case 1: cell.textLabel.text = @"Performance"; break;
        case 2: cell.textLabel.text = @"File Printer"; break;
        case 3: cell.textLabel.text = @"Log View"; break;
    }

    return cell;
}

- (void)selectController:(NSInteger)index animated:(BOOL)animated
{
    UIViewController* controller = nil;
    switch (index) {
        case 0: controller = [[NWLIntroViewController alloc] init]; break;
        case 1: controller = [[NWLPerformanceViewController alloc] init]; break;
        case 2: controller = [[NWLPersistentViewController alloc] init]; break;
        case 3: {
            NWLLogViewController *c = [[NWLLogViewController alloc] init];
            if (NWLPersistentViewController.printer) {
                [c configureWithFilePrinter:NWLPersistentViewController.printer];
            } else {
                [c appendText:@"To view previous logs, turn on file logging.\n"];
            }
            [c configureWithMultiLogger:NWLMultiLogger.shared];
            [c addEmailButton:@"leonard@noodlewerk.com" compressAttachment:YES];
            [c addDefaultFilters];
            [c addAboutButton];
            controller = c;
        } break;
    }

    [self.navigationController pushViewController:controller animated:animated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectController:indexPath.row animated:YES];
}

@end
