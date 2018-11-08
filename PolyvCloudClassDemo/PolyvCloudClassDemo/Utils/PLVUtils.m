//
//  PLVUtils.m
//  PolyvCloudClassSDKDemo
//
//  Created by ftao on 01/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVUtils.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <Masonry/Masonry.h>

static PLVUtils *chatroomHud = nil;

@interface PLVUtils ()

@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation PLVUtils

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
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = title;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:3.0];
}

+ (void)showChatroomMessage:(NSString *)message addedToView:(UIView *)view {
    if (!view) return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        chatroomHud = [[PLVUtils alloc] init];
    });
    if (chatroomHud.messageLabel) {
        [chatroomHud.messageLabel removeFromSuperview];
    }
    chatroomHud.messageLabel = [self addLabel:message font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium] textAlignment:NSTextAlignmentCenter inView:view];
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
    UILabel *messageLabel = [PLVUtils addLabel:message font:[UIFont systemFontOfSize:15.0] textAlignment:NSTextAlignmentCenter inView:view];
    messageLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    messageLabel.clipsToBounds = YES;
    messageLabel.layer.cornerRadius = 16.0;
    //UIEdgeInsets messageMargin = UIEdgeInsetsMake(-1.0, 10.0, 44.0, -1.0);
    //CGSize size = [messageLabel sizeThatFits:CGSizeMake(1000.0, 32.0)];
    //[self remakeConstraints:messageLabel margin:messageMargin size:CGSizeMake(size.width + 32.0, 32.0) baseView:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

#pragma mark - UIImage

+ (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees {
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,oldImage.size.width, oldImage.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, (degrees * M_PI / 180));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSString *)secondsToString:(NSTimeInterval)seconds {
    NSInteger time = seconds;
    NSInteger hour = time / 3600;
    NSInteger min = (time / 60) % 60;
    NSInteger sec = time % 60;
    NSString *str = hour > 0 ? [NSString stringWithFormat:@"%02zd:", hour] : @"";
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%02zd:%02zd", min, sec]];
    return str;
}

#pragma mark - Privates


@end
