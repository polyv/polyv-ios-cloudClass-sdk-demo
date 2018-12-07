//
//  MyTool.h
//  zFM
//
//  Created by zykhbl on 15-9-25.
//  Copyright (c) 2015年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface MyTool : NSObject

+ (int)floatToInt:(CGFloat)v;
+ (NSString*)makeUserFilePath:(NSString*)filename;
+ (NSString*)makeTmpFilePath:(NSString*)filename;
+ (NSString*)makeAppFilePath:(NSString*)filename;

+ (void)makeDir:(NSString*)dir;
+ (void)makeDirWithFilePath:(NSString*)filepath;
+ (BOOL)checkFilepathExists:(NSString*)filepath;
+ (void)makeFile:(NSString*)filepath;
+ (void)removeFile:(NSString*)filepath;

+ (UIView*)createLineView:(UIView*)view rect:(CGRect)lineRect;
+ (UIView*)createToolBarInView:(UIView*)view;
+ (UIButton*)createBtn:(NSString*)normalImgStr selectedImgStr:(NSString*)selectedImgStr disabledImgStr:(NSString*)disabledImgStr action:(SEL)action frame:(CGRect)rect target:(id)target inView:(UIView*)view;
+ (UIButton*)createToolBarBtn:(NSString*)title titleFontSize:(CGFloat)fontSize normalColor:(UIColor*)normalColor selectedColor:(UIColor*)selectedColor action:(SEL)action frame:(CGRect)rect target:(id)target inView:(UIView*)view;
+ (CABasicAnimation*)moveAnimationFrom:(NSValue*)fromValue to:(NSValue*)toValue;

+ (NSString*)currentTimeToString:(CGFloat)currentTime;
+ (UIImageOrientation)imageOrientation:(AVAsset*)avasset;
+ (CGFloat)spacePreFrameTimeStamp:(CGFloat)baseDuration;
+ (CGFloat)spaceDetailFrameTimeStamp:(CGFloat)baseDuration;

+ (void)leftBarButtonItemAction:(SEL)action target:(UIViewController*)vc;
+ (void)rightBarButtonItem:(NSString*)imgStr action:(SEL)action target:(UIViewController*)vc;

+ (UIView*)createTitleView:(NSArray*)items action:(SEL)action otherAction:(SEL)otherAction target:(UIViewController*)vc;
+ (void)presentAlertController:(NSString*)message inViewController:(UIViewController*)vc;

+ (UILabel*)createUILabel:(CGRect)rect fontOfSize:(CGFloat)fontOfSize textColor:(UIColor*)textColor backgroundColor:(UIColor*)backgroundColor textAlignment:(NSTextAlignment)textAlignment inView:(UIView*)view;
+ (void)tip:(UIViewController*)vc text:(NSString*)text originY:(CGFloat)originY backgroundColor:(UIColor*)backgroundColor;
+ (UILabel*)createUILabel:(CGRect)rect fontOfSize:(CGFloat)fontOfSize textColor:(UIColor*)textColor inView:(UIView*)view;
+ (UISlider*)createUISlider:(CGRect)rect minimumValue:(double)minimumValue maximumValue:(double)maximumValue value:(double)value action:(SEL)action target:(NSObject*)obj inView:(UIView*)view;
+ (UISwitch*)createUISwitch:(CGRect)rect on:(BOOL)on action:(SEL)action target:(UIViewController*)vc inView:(UIView*)view;

@end
