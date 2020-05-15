//
//  PLVUtils.h
//  PolyvCloudClassSDKDemo
//
//  Created by ftao on 01/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 使用示例 UIColorFromRGB(0x0e0e10)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface PCCUtils : NSObject

#pragma mark - UIColor
/// Assumes input like "#00FF00" (#RRGGBB).
+ (nullable UIColor *)colorFromHexString:(nullable NSString *)hexString;

#pragma mark - HUD
/**
 show hud view

 @param title can't be nil.
 @param detail detail message.
 @param view super view.
 */
+ (void)showHUDWithTitle:(nullable NSString * )title detail:(nullable NSString *)detail view:(nonnull UIView *)view;

/**
 show hud view
 
 @param message message.
 @param view super view.
 */
+ (void)showChatroomMessage:(nullable NSString *)message addedToView:(nullable UIView *)view;

#pragma mark - Alert
/// UIAlertViewController弹窗
+ (void)presentAlertViewController:(NSString *)title message:(NSString *)message inViewController:(UIViewController *)vc;

/// 改变设备的方向，用于横竖屏切换
+ (void)changeDeviceOrientation:(UIDeviceOrientation)orientation;

/// 强制把设备UIDevice的方向设置为竖屏（在弹出，弹入相册，照相机，或退出直播时需要手动调用）
+ (void)deviceOnInterfaceOrientationMaskPortrait;

#pragma mark - Layout
/// 获取当前设备的状态栏高度
+ (CGFloat)getStatusBarHeight;

@end

NS_ASSUME_NONNULL_END
