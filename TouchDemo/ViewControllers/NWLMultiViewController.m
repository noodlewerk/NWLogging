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
    UITextView *logView;
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

    logView = [[UITextView alloc] init];
    logView.frame = CGRectMake(10, 60, self.view.bounds.size.width - 20, self.view.bounds.size.height - 70 - 40);
    logView.backgroundColor = UIColor.blackColor;
    logView.textColor = UIColor.whiteColor;
    logView.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10]; // Courier-Bold or CourierNewPS-BoldMT
    logView.editable = NO;
    [self.view addSubview:logView];
    
    [self updateUI];
}

- (void)run
{
    NWLog(@"This line should *not* be visible in the view");
    [NWLMultiLogger.shared addPrinter:self];
    NWLog(@"This line should be visible in the view ...");
    [self performSelector:@selector(run2) withObject:nil afterDelay:1];
    [self updateUI];
}

- (void)run2
{
    NWLog(@".. an this one too.");
    [NWLMultiLogger.shared removePrinter:self];
    NWLog(@"And this line should *not* be visible in the view");
    [self updateUI];
}

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function message:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *s = [NWLTools formatTag:tag lib:lib file:file line:line function:function message:message];
        logView.text = [logView.text stringByAppendingString:s];
    });
}

- (void)updateUI
{
    countLabel.text = [NSString stringWithFormat:@"#printers: %u", NWLMultiLogger.shared.count];
}

@end
