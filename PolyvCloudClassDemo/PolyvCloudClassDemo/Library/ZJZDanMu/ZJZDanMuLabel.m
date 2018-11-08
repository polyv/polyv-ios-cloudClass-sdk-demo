//
//  ZJZDanMuLabel.m
//  DanMu
//
//  Created by 郑家柱 on 16/6/17.
//  Copyright © 2016年 Jiangsu Houxue Network Information Technology Limited By Share Ltd. All rights reserved.
//

#import "ZJZDanMuLabel.h"
#import "ZJZDanMuDefine.h"

@interface ZJZDanMuLabel ()

@property (nonatomic, assign) CGRect superFrame;
@property (nonatomic, assign) CGFloat animateDuration;

@end

@implementation ZJZDanMuLabel

/* 创建 */
+ (instancetype)dmInitDML:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY superFrame:(CGRect)superFrame style:(ZJZDMLStyle)style
{
    ZJZDanMuLabel *dmLabel = [[ZJZDanMuLabel alloc] init];
    dmLabel.superFrame = superFrame;
    dmLabel.zjzDMLStyle = style;
    
    [dmLabel dmInitWithContent:content dmlOriginY:dmlOriginY];
    
    return dmLabel;
}

/* 初始化 */
- (void)dmInitWithContent:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY
{
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont systemFontOfSize:14];
    self.attributedText = content;
    
    CGSize size = [self countString:content size:CGSizeMake(MAXFLOAT, KZJZDMHEIGHT) font:self.font];
    
    // 当文字显示大于一屏时，自动调整为滚动显示
    if (size.width > self.superFrame.size.width - 90) {
        self.zjzDMLStyle = ZJZDMLRoll;
    }
    
    if (self.zjzDMLStyle == ZJZDMLRoll) {
        self.frame = CGRectMake(self.superFrame.size.width, dmlOriginY, size.width, size.height);
    } else {
        self.frame = CGRectMake(0, 0, size.width, size.height);
        self.center = CGPointMake(self.superFrame.size.width/2 - 30 + arc4random_uniform(60), dmlOriginY + size.height/2);
        self.alpha = 0.0f;
    }
}

/* 开始弹幕动画 */
- (void)dmBeginAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.zjzDMLState = ZJZDMLStateRunning;
        self.startTime = [NSDate date];
        
        if (self.zjzDMLStyle == ZJZDMLRoll) {
            int scale = self.frame.size.width / [UIScreen mainScreen].bounds.size.width;
            scale = sqrt(scale) * 2.0;
            if (scale == 0) {
                scale = 1;
            }
            self.animateDuration = KZJZDMLROLLANIMATION * scale;
            [UIView animateWithDuration:self.animateDuration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
                
                CGRect frame = self.frame;
                frame.origin.x = - self.frame.size.width;
                self.frame = frame;
                
            } completion:^(BOOL finished) {
                
                if (finished) {
                    [self removeDanmu];
                }
                
            }];
            
        } else {
            
            [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
                
                self.alpha = 1.0f;
                
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:1.0f delay:KZJZDMLFADEANIMATION options:UIViewAnimationOptionCurveLinear animations:^{
                    
                    self.alpha = 0.2f;
                    
                } completion:^(BOOL finished) {
                    
                    if (finished) {
                        [self removeDanmu];
                    }
                    
                }];
                
            }];
        }
        
    });
}

/* 移除弹幕 */
- (void)removeDanmu {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.zjzDMLState = ZJZDMLStateFinish;
        [self.layer removeAllAnimations];
        [self removeFromSuperview];
    });
}

/** 动态计算文本高度 **/
- (CGSize)countString:(NSMutableAttributedString *)content size:(CGSize)size font:(UIFont *)font
{
    CGSize expectedLabelSize = [self sizeThatFits:size];
    
    return CGSizeMake(ceil(expectedLabelSize.width), ceil(expectedLabelSize.height));
}

#pragma mark - GET
- (CGFloat)dmlSpeed
{
    return (self.frame.size.width + self.superFrame.size.width) / self.animateDuration;
}

- (CGFloat)dmlFadeTime
{
    return 1.0f + 1.0f + KZJZDMLFADEANIMATION;
}

@end
