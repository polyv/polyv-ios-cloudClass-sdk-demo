//
//  MBProgressHUD+Rotate.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/12/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "MBProgressHUD+Rotate.h"

@implementation MBProgressHUD (Rotate)

#pragma mark - life cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public
- (void)addDeviceOrientationDidChangeNotification {
    [self rotateAnimation:0.0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - orientation
- (void)deviceOrientationDidChange {
    [self rotateAnimation:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration]];
}

- (void)rotateAnimation:(CGFloat)duration {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    CGFloat angle = 0.0;
    if (UIDeviceOrientationIsLandscape(orientation)) {
        angle = (orientation == UIDeviceOrientationLandscapeRight ? -M_PI_2 : M_PI_2);
    }
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.transform = CGAffineTransformMakeRotation(angle);
    } completion:nil];
}

@end
