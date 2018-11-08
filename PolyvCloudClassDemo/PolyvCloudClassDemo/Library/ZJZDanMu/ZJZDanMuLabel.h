//
//  ZJZDanMuLabel.h
//  DanMu
//
//  Created by 郑家柱 on 16/6/17.
//  Copyright © 2016年 Jiangsu Houxue Network Information Technology Limited By Share Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZJZDMLState) {
    ZJZDMLStateRunning,
    ZJZDMLStateStop,
    ZJZDMLStateFinish
};

typedef NS_ENUM(NSUInteger, ZJZDMLStyle) {
    ZJZDMLRoll,
    ZJZDMLFade
};

@interface ZJZDanMuLabel : UILabel

@property (nonatomic, assign) ZJZDMLState                   zjzDMLState;
@property (nonatomic, assign) ZJZDMLStyle                   zjzDMLStyle;

/* 当前弹幕开始动画时间 */
@property (nonatomic, strong) NSDate                        *startTime;

/* 弹幕滚动速度 */
@property (nonatomic, assign, readonly) CGFloat             dmlSpeed;

/* 弹幕浮动时间 */
@property (nonatomic, assign, readonly) CGFloat             dmlFadeTime;

/* 创建 */
+ (instancetype)dmInitDML:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY superFrame:(CGRect)superFrame style:(ZJZDMLStyle)style;

/* 开始弹幕动画 */
- (void)dmBeginAnimation;

@end
