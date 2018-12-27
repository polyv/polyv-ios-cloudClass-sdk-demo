//
//  UIAlertController+UnRotate.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/12/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "UIAlertController+UnRotate.h"

@implementation UIAlertController (UnRotate)

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
