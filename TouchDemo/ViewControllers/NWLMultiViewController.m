//
//  NWLMultiViewController.m
//  NWLogging
//
//  Created by leonard on 4/25/12.
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLMultiViewController.h"
#import "NWLMultiLogger.h"
#import "NWLTools.h"


@implementation NWLMultiViewController {
    NWLLogView *logView;
    UILabel *countLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Multi Logger";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(10, 10, self.view.bounds.size.width - 200, 40);
    [button setTitle:@"Run" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(run) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    countLabel = [[UILabel alloc] init];
    countLabel.frame = CGRectMake(self.view.bounds.size.width - 170, 10, 160, 40);
    [self.view addSubview:countLabel];

    logView = [[NWLLogView alloc] init];
    logView.frame = CGRectMake(10, 60, self.view.bounds.size.width - 20, self.view.bounds.size.height - 70 - 40);
    [self.view addSubview:logView];
    
    [self updateUI];
}

- (void)run
{
    NWLog(@"This line should *not* be visible in the view");
    [NWLMultiLogger.shared addPrinter:logView];
    NWLog(@"This line should be visible in the view ...");
    [self performSelector:@selector(run2) withObject:nil afterDelay:1];
    [self updateUI];
}

- (void)run2
{
    NWLog(@".. an this one too.");
    [NWLMultiLogger.shared removePrinter:logView];
    NWLog(@"And this line should *not* be visible in the view");
    [self updateUI];
}

- (void)updateUI
{
    countLabel.text = [NSString stringWithFormat:@"#printers: %u", NWLMultiLogger.shared.count];
}

@end
