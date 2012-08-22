//
//  NWLMenuViewController.m
//  NWLogging
//
//  Created by leonard on 4/25/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLMenuViewController.h"
#import "NWLIntroViewController.h"
#import "NWLPerformanceViewController.h"
#import "NWLMultiViewController.h"
#import "NWLPersistentViewController.h"
#import "NWLLogViewController.h"


@implementation NWLMenuViewController


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
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
        case 0: cell.textLabel.text = @"Introduction to NWLogging"; break;
        case 1: cell.textLabel.text = @"Performance test"; break;
        case 2: cell.textLabel.text = @"About the Multi Logger"; break;
        case 3: cell.textLabel.text = @"File Printer"; break;
        case 4: cell.textLabel.text = @"Log view"; break;
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)selectController:(NSInteger)index animated:(BOOL)animated
{
    UIViewController* controller = nil;
    switch (index) {
        case 0: controller = [[NWLIntroViewController alloc] init]; break;
        case 1: controller = [[NWLPerformanceViewController alloc] init]; break;
        case 2: controller = [[NWLMultiViewController alloc] init]; break;
        case 3: controller = [[NWLPersistentViewController alloc] init]; break;
        case 4: {
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
