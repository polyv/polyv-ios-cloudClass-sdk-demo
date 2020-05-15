//
//  PLVUtils.m
//  PolyvCloudClassSDKDemo
//
//  Created by ftao on 01/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PCCUtils.h"
#import <PolyvFoundationSDK/PLVProgressHUD.h>
#import <Masonry/Masonry.h>

static PCCUtils *chatroomHud = nil;

@interface PCCUtils ()

@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation PCCUtils

#pragma mark - UIColor
+ (UIColor *)colorFromHexString:(NSString *)hexString {
    if (!hexString || hexString.length < 6) {
        return [UIColor whiteColor];
    }
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString rangeOfString:@"#"].location == 0) {
        [scanner setScanLocation:1]; // bypass '#' character
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (UIColor *)colorWithHex:(u_int32_t)hex {
    // >> 右移运算; & 与运算, 相同为1 不同为0, FF: 1111 1111
    // 如:0xAABBCC:AA为red的值,BB为green的值,CC为blue的值
    // 通过&运算和>>运算, 分别计算出 red,green,blue的值
    int red = (hex & 0xFF0000) >> 16;
    int green = (hex & 0x00FF00) >> 8;
    int blue = hex & 0x0000FF;
    
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

#pragma mark - HUD

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view {
    NSLog(@"HUD info title:%@,detail:%@",title,detail);
    if (view == nil) {
        return;
    }
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = title;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:2.0];
}

+ (void)showChatroomMessage:(NSString *)message addedToView:(UIView *)view {
    if (!view) return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        chatroomHud = [[PCCUtils alloc] init];
    });
    if (chatroomHud.messageLabel) {
        [chatroomHud.messageLabel removeFromSuperview];
    }
    if (@available(iOS 8.2, *)) {
        chatroomHud.messageLabel = [self addLabel:message font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium] textAlignment:NSTextAlignmentCenter inView:view];
    } else {
        chatroomHud.messageLabel = [self addLabel:message font:[UIFont systemFontOfSize:12.0] textAlignment:NSTextAlignmentCenter inView:view];
    }
    chatroomHud.messageLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    chatroomHud.messageLabel.clipsToBounds = YES;
    chatroomHud.messageLabel.layer.cornerRadius = 16.0;
    CGSize size = [chatroomHud.messageLabel sizeThatFits:CGSizeMake(MAXFLOAT, 32.0)];
    [chatroomHud.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(view);
        make.size.mas_equalTo(CGSizeMake(size.width+32, 32));
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [chatroomHud.messageLabel removeFromSuperview];
    });
}

- (void)showMessage:(NSString *)message addedToView:(UIView *)view {
    UILabel *messageLabel = [PCCUtils addLabel:message font:[UIFont systemFontOfSize:15.0] textAlignment:NSTextAlignmentCenter inView:view];
    messageLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    messageLabel.clipsToBounds = YES;
    messageLabel.layer.cornerRadius = 16.0;
    //UIEdgeInsets messageMargin = UIEdgeInsetsMake(-1.0, 10.0, 44.0, -1.0);
    //CGSize size = [messageLabel sizeThatFits:CGSizeMake(1000.0, 32.0)];
    //[self remakeConstraints:messageLabel margin:messageMargin size:CGSizeMake(size.width + 32.0, 32.0) baseView:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [messageLabel removeFromSuperview];
    });
}

+ (UILabel *)addLabel:(NSString *)text font:(UIFont *)font textAlignment:(NSTextAlignment)textAlignment inView:(UIView *)view {
    UILabel *label = [[UILabel alloc] init];
    //label.backgroundColor = [UIColor clearColor];
    label.font = font;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = textAlignment;
    label.text = text;
    [view addSubview:label];
    return label;
}

#pragma mark - Alert
+ (void)presentAlertViewController:(NSString *)title message:(NSString *)message inViewController:(UIViewController *)vc {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [vc presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UIDevice changeDeviceOrientation
+ (void)changeDeviceOrientation:(UIDeviceOrientation)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];//从2开始，因为0 1 两个参数已经被selector和target占用
        [invocation invoke];
    }
}

#pragma mark - UIDevice UIInterfaceOrientationMaskPortrait
+ (void)deviceOnInterfaceOrientationMaskPortrait {
    [self changeDeviceOrientation:UIDeviceOrientationPortrait];
}

#pragma mark - Layout
+ (CGFloat)getStatusBarHeight{
    CGFloat statusBarHeight;
    if (@available(iOS 11.0, *)) {
        CGFloat topY = (([[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0) ? [[UIApplication sharedApplication] delegate].window.safeAreaInsets.top : 20);
        statusBarHeight = topY;
    } else {
        statusBarHeight = 20;
    }
    return statusBarHeight;
}


@end
