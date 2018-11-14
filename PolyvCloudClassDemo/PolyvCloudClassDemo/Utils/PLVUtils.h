//
//  PLVUtils.h
//  PolyvCloudClassSDKDemo
//
//  Created by ftao on 01/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 使用示例 UIColorFromRGB(0x0e0e10)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface PLVUtils : NSObject

#pragma mark - UIColor

// Assumes input like "#00FF00" (#RRGGBB).
+ (nullable UIColor *)colorFromHexString:(nullable NSString *)hexString;

#pragma mark - HUD

/**
 show hud view

 @param title can't be nil.
 @param detail detail message.
 @param view super view.
 */
+ (void)showHUDWithTitle:(nullable NSString * )title detail:(nullable NSString *)detail view:(nonnull UIView *)view;


+ (void)showChatroomMessage:(nullable NSString *)message addedToView:(nullable UIView *)view;

#pragma mark - UIImage

+ (nullable UIImage *)imageRotatedByDegrees:(nullable UIImage *)oldImage deg:(CGFloat)degrees;

+ (void)presentAlertViewController:(NSString *)title message:(NSString *)message inViewController:(UIViewController *)vc;

@end
