//
//  ZJZDanMu.h
//  DanMu
//
//  Created by 郑家柱 on 16/6/17.
//  Copyright © 2016年 Jiangsu Houxue Network Information Technology Limited By Share Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZJZDanMu : UIView

/* 插入弹幕 （随机样式）*/
- (void)insertDML:(NSMutableAttributedString *)content;

/* 插入弹幕 （滚动样式）*/
- (void)insertScrollDML:(NSMutableAttributedString *)content;

/* 重置Frame */
- (void)resetFrame:(CGRect)frame;

@end
