//
//  PLVMediaSecondaryView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/9.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVMediaSecondaryViewDelegate;

/// 浮屏窗口
@interface PLVMediaSecondaryView : UIView

/// delegate
@property (nonatomic, weak) id<PLVMediaSecondaryViewDelegate> delegate;
/// 是否全屏
@property (nonatomic, assign) BOOL fullscreen;

/// 加在子View
- (void)loadSubviews;

/// 显示关闭按钮
- (void)showCloseBtn;

@end

@protocol PLVMediaSecondaryViewDelegate <NSObject>

/// 点击关闭按钮时回调，有外层处理
- (void)closeSecondaryView:(PLVMediaSecondaryView *)secondaryView;

@end
