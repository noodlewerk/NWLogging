//
//  NWLAppDelegate.m
//  NWLoggingTouchDemo
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLAppDelegate.h"
#import "NWLMenuViewController.h"


@implementation NWLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NWParameterAssert(application);
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    NWLMenuViewController *controller = [[NWLMenuViewController alloc] init];
    UINavigationController * navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    self.window.rootViewController = navigation;
    self.window.backgroundColor = UIColor.whiteColor;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
