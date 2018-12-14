//
//  ZNavigationController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/12/5.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "ZNavigationController.h"
#import "ZPicDefine.h"
#import "MyTool.h"

BOOL isPhone = YES;
CGFloat ToolbarHeight = 50.0;
NSInteger PickerNumberOfItemsInSection = 4;
CGFloat LimitMemeory = 1024 * 1024 * 75;
CGFloat MemeoryLarge = 1024 * 1024 * 50;

UIColor *NavBackgroupColor;
UIColor *ViewBackgroupColor;

@implementation ZNavigationController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UIScreen mainScreen].bounds.size.height == 812) {
        ToolbarHeight = 84.0;
        LimitMemeory = 1024 * 1024 * 120;
        MemeoryLarge = 1024 * 1024 * 80;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        isPhone = NO;
        PickerNumberOfItemsInSection = 6;
        LimitMemeory = 1024 * 1024 * 120;
        MemeoryLarge = 1024 * 1024 * 80;
    }
    
    NavBackgroupColor = [UIColor blackColor];
    ViewBackgroupColor = [UIColor whiteColor];
    
    self.navigationBar.barTintColor = NavBackgroupColor;
    self.navigationBar.titleTextAttributes = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:17.0], NSForegroundColorAttributeName : NormalColor};
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end
