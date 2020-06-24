//
//  PLVKeyboardTool.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2020/5/19.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVKeyboardTool.h"

@implementation PLVKeyboardTool

+ (UIImage *)getImageWithImageName:(NSString *)imageName{
    UIImage * img;
    if (imageName && [imageName isKindOfClass:NSString.class] && imageName.length > 0) {
        NSString * bundlePath = [[NSBundle bundleForClass:[self class]].resourcePath stringByAppendingPathComponent:@"/PLVKeyboardSkin.bundle"];
        NSBundle * bundle = [NSBundle bundleWithPath:bundlePath];
        img = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return img;
}

@end
