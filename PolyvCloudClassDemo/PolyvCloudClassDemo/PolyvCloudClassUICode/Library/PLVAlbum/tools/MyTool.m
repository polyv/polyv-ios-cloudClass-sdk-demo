//
//  MyTool.h
//  zFM
//
//  Created by zykhbl on 15-9-25.
//  Copyright (c) 2015年 zykhbl. All rights reserved.
//

#import "MyTool.h"
#import "SDWebImageDecoder.h"
#import "ZPicDefine.h"

@implementation MyTool

+ (int)floatToInt:(CGFloat)v {
    int v_int = (int)v;
    if (v - v_int >= 0.99) {
        v_int += 1;
    }
    return v_int;
}

+ (NSString*)makeUserFilePath:(NSString*)filename {
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return filePath;
}

+ (NSString*)makeTmpFilePath:(NSString*)filename {
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return filePath;
}

+ (NSString*)makeAppFilePath:(NSString*)filename {
    NSString *appDirectory = [[NSBundle mainBundle] resourcePath];
    NSString *filePath = [appDirectory stringByAppendingPathComponent:filename];
    return filePath;
}

+ (void)makeDir:(NSString*)dir {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dir]) {
        return ;
    } else {
        NSError* error;
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
    }
}

+ (void)makeDirWithFilePath:(NSString*)filepath {
    if (!filepath) {
        return ;
    }
    NSString *filename = [filepath lastPathComponent];
    NSString *dirpath = [filepath substringToIndex:([filepath length]-[filename length])];
    return [[self class] makeDir:dirpath];
}

+ (BOOL)checkFilepathExists:(NSString*)filepath {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:filepath];
}

+ (void)makeFile:(NSString*)filepath {
    if (![self checkFilepathExists:filepath]) {
        [self makeDirWithFilePath:filepath];
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createFileAtPath:filepath contents:nil attributes:nil];
    }
}

+ (void)removeFile:(NSString*)filepath {
    if ([self checkFilepathExists:filepath]) {
        NSFileManager *fm = [NSFileManager defaultManager];        
        NSError* error;
        [fm removeItemAtPath:filepath error:&error];
    }
}

+ (UIView*)createLineView:(UIView*)view rect:(CGRect)lineRect {
    UIView *lineView = [[UIView alloc] initWithFrame:lineRect];
    lineView.backgroundColor = [LightGrayColor colorWithAlphaComponent:0.2];
    [view addSubview:lineView];
    return lineView;
}

+ (UIView*)createToolBarInView:(UIView*)view {
    CGRect toolBarRect = CGRectMake(0.0, view.bounds.size.height - ToolbarHeight, view.bounds.size.width, ToolbarHeight);
    UIView *toolBar = [[UIView alloc] initWithFrame:toolBarRect];
    toolBar.backgroundColor = NavBackgroupColor;
    [view addSubview:toolBar];
    return toolBar;
}

+ (UIButton*)createBtn:(NSString*)normalImgStr selectedImgStr:(NSString*)selectedImgStr disabledImgStr:(NSString*)disabledImgStr action:(SEL)action frame:(CGRect)rect target:(id)target inView:(UIView*)view {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = rect;
    [btn setImage:[self getImageWithImageName:normalImgStr] forState:UIControlStateNormal];
    if (selectedImgStr != nil) {
        [btn setImage:[self getImageWithImageName:selectedImgStr] forState:UIControlStateSelected];
    }
    if (disabledImgStr != nil) {
        [btn setImage:[self getImageWithImageName:disabledImgStr] forState:UIControlStateDisabled];
    }
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
    
    return btn;
}

+ (UIButton*)createToolBarBtn:(NSString*)title titleFontSize:(CGFloat)fontSize normalColor:(UIColor*)normalColor selectedColor:(UIColor*)selectedColor action:(SEL)action frame:(CGRect)rect target:(id)target inView:(UIView*)view {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = rect;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    [btn setTitleColor:normalColor forState:UIControlStateNormal];
    [btn setTitleColor:selectedColor forState:UIControlStateSelected];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
    
    return btn;
}

+ (CABasicAnimation*)moveAnimationFrom:(NSValue*)fromValue to:(NSValue*)toValue {
    CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    moveAnimation.fromValue = fromValue;
    moveAnimation.toValue = toValue;
    moveAnimation.duration = 0.4;
    moveAnimation.repeatCount = MAXFLOAT;
    moveAnimation.autoreverses = YES;
    moveAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    return moveAnimation;
}

+ (NSString*)currentTimeToString:(CGFloat)currentTime {
    int m = currentTime / 60.0;
    double ds = currentTime - m * 60.0;
    int s = (int)ds;
    if (ds - s > 0.3) {
        s += 1;
    }
    NSString *mStr = m < 10 ? [NSString stringWithFormat:@"0%d", m] : [NSString stringWithFormat:@"%d", m];
    NSString *sStr = s < 10 ? [NSString stringWithFormat:@"0%d", s] : [NSString stringWithFormat:@"%d", s];
    return [NSString stringWithFormat:@"%@:%@", mStr, sStr];
}

+ (UIImageOrientation)imageOrientation:(AVAsset*)avasset {
    NSArray *videoTracks = [avasset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count == 0) {
        return UIImageOrientationRight;
    } else {
        AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {//PortraitUP
            return UIImageOrientationUp;
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {//PortraitDown
            return UIImageOrientationDown;
        } else if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {//LandscapeLeft
            return UIImageOrientationLeft;
        } else {//LandscapeRight (t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
            return UIImageOrientationRight;
        }
    }
}

+ (CGFloat)spacePreFrameTimeStamp:(CGFloat)baseDuration {
    if (baseDuration < 10.0) {
        return 1.0;
    } else if (baseDuration < 30.0) {
        return 2.0;
    } else if (baseDuration < 60.0) {
        return 3.0;
    } else if (baseDuration < 600.0) {
        return 5.0;
    } else if (baseDuration < 1800.0) {
        return 10.0;
    } else {
        return 30.0;
    }
}

+ (CGFloat)spaceDetailFrameTimeStamp:(CGFloat)baseDuration {    
    if (baseDuration < 10.0) {
        return 0.4;
    } else if (baseDuration < 30.0) {
        return 0.8;
    } else if (baseDuration < 60.0) {
        return 1.0;
    } else if (baseDuration < 600.0) {
        return 1.5;
    } else if (baseDuration < 1800.0) {
        return 2.0;
    } else {
        return 2.5;
    }
}

+ (void)leftBarButtonItemAction:(SEL)action target:(UIViewController*)vc {
    vc.navigationItem.leftItemsSupplementBackButton = YES;
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:[self getImageWithImageName:@"back.png"] style:UIBarButtonItemStylePlain target:vc action:action];
    leftItem.tintColor = NormalColor;
    vc.navigationItem.leftBarButtonItem = leftItem;
}

+ (void)rightBarButtonItem:(NSString*)imgStr action:(SEL)action target:(UIViewController*)vc {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:[self getImageWithImageName:imgStr] style:UIBarButtonItemStylePlain target:vc action:action];
    rightItem.tintColor = SelectedColor;
    vc.navigationItem.rightBarButtonItem = rightItem;
    [vc.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:17.0]} forState:UIControlStateNormal];
}

+ (UIView*)createTitleView:(NSArray*)items action:(SEL)action otherAction:(SEL)otherAction target:(UIViewController*)vc {
    UIFont *font = [UIFont boldSystemFontOfSize:17.0];
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectZero];
    NSString *leftStr = [items objectAtIndex:0];
    CGSize leftSize = [leftStr sizeWithAttributes:@{NSFontAttributeName : font}];
    CGRect leftRect = CGRectMake(0.0, 0.0, (int)leftSize.width + 1.0, vc.navigationController.navigationBar.frame.size.height);
    [MyTool createToolBarBtn:leftStr titleFontSize:17.0 normalColor:NormalColor selectedColor:SelectedColor action:action frame:leftRect target:vc inView:titleView];
    
    NSString *rightStr = [items objectAtIndex:1];
    CGSize rightSize = [rightStr sizeWithAttributes:@{NSFontAttributeName : font}];
    CGRect rightRect = leftRect;
    rightRect.origin.x += rightRect.size.width + 20.0;
    rightRect.size.width = rightSize.width + 1.0;
    [MyTool createToolBarBtn:rightStr titleFontSize:17.0 normalColor:NormalColor selectedColor:SelectedColor action:otherAction frame:rightRect target:vc inView:titleView];
    
    CGRect titleRect = CGRectMake(0.0, 0.0, rightRect.origin.x + rightRect.size.width, rightRect.size.height);
    titleRect.origin.x = (vc.navigationController.navigationBar.frame.size.width - titleRect.size.width) * 0.5;
    titleView.frame = titleRect;
    vc.navigationItem.titleView = titleView;
    return titleView;
}

+ (void)presentAlertController:(NSString*)message inViewController:(UIViewController*)vc {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil]];
    [vc presentViewController:alertVC animated:YES completion:nil];
}

+ (UILabel*)createUILabel:(CGRect)rect fontOfSize:(CGFloat)fontOfSize textColor:(UIColor*)textColor backgroundColor:(UIColor*)backgroundColor textAlignment:(NSTextAlignment)textAlignment inView:(UIView*)view {
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    label.backgroundColor = backgroundColor;
    label.font = [UIFont boldSystemFontOfSize:fontOfSize];
    label.textColor = textColor;
    label.textAlignment = textAlignment;
    if (view != nil) {
        [view addSubview:label];
    }    
    return label;
}

+ (void)tip:(UIViewController*)vc text:(NSString*)text originY:(CGFloat)originY backgroundColor:(UIColor*)backgroundColor {
    CGRect tipRect = CGRectMake(0.0, originY - 40.0, vc.view.bounds.size.width, 40.0);
    UILabel *tipLabel = [MyTool createUILabel:tipRect fontOfSize:15.0 textColor:NormalColor backgroundColor:backgroundColor textAlignment:NSTextAlignmentCenter inView:vc.view];
    tipLabel.text = text;
    
    [UIView animateWithDuration:0.5 animations:^ {
        CGRect rect = tipLabel.frame;
        rect.origin.y = originY;
        tipLabel.frame = rect;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:2.5 options:UIViewAnimationOptionCurveEaseInOut animations:^ {
            tipLabel.frame = tipRect;
        } completion:nil];
    }];
}

+ (UILabel*)createUILabel:(CGRect)rect fontOfSize:(CGFloat)fontOfSize textColor:(UIColor*)textColor inView:(UIView*)view {
    UILabel *label = [MyTool createUILabel:rect fontOfSize:fontOfSize textColor:textColor backgroundColor:BgClearColor textAlignment:NSTextAlignmentCenter inView:view];
    label.clipsToBounds = YES;
    label.layer.borderWidth = 1.5;
    label.layer.borderColor = textColor.CGColor;
    label.layer.cornerRadius = rect.size.width * 0.5;
    
    return label;
}

+ (UISlider*)createUISlider:(CGRect)rect minimumValue:(double)minimumValue maximumValue:(double)maximumValue value:(double)value action:(SEL)action target:(NSObject*)obj inView:(UIView*)view {
    UISlider *slider = [[UISlider alloc] initWithFrame:rect];
    slider.tintColor = SelectedColor;
    slider.minimumValue = minimumValue;
    slider.maximumValue = maximumValue;
    slider.value = value;
    if (obj != nil) {
        [slider addTarget:obj action:action forControlEvents:UIControlEventValueChanged];
    }    
    [view addSubview:slider];
    return slider;
}

+ (UISwitch*)createUISwitch:(CGRect)rect on:(BOOL)on action:(SEL)action target:(UIViewController*)vc inView:(UIView*)view {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:rect];
    sw.onTintColor = SelectedColor;
    sw.tintColor = NormalColor;
    sw.on = on;
    if (vc != nil) {
        [sw addTarget:vc action:action forControlEvents:UIControlEventValueChanged];
    }
    [view addSubview:sw];
    return sw;
}

+ (UIImage *)getImageWithImageName:(NSString *)imageName{
    UIImage * img;
    if (imageName && [imageName isKindOfClass:NSString.class] && imageName.length > 0) {
        NSString * bundlePath = [[NSBundle bundleForClass:[self class]].resourcePath stringByAppendingPathComponent:@"/PLVAlbum.bundle"];
        NSBundle * bundle = [NSBundle bundleWithPath:bundlePath];
        img = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return img;
}

@end
