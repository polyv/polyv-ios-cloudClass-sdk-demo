//
//  PLVBaseNavigationController.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2020/5/6.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVBaseNavigationController.h"

@interface PLVBaseNavigationController ()

@end

@implementation PLVBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotate{
    return [self.visibleViewController shouldAutorotate];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return [self.visibleViewController preferredInterfaceOrientationForPresentation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (![self.visibleViewController isKindOfClass:[UIAlertController class]]) {
        return [self.visibleViewController supportedInterfaceOrientations];
    }else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
