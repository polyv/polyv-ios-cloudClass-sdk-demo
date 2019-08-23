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
/// 竖屏时是否可以移动（直播不可以，回放可以）
@property (nonatomic, assign) BOOL canMove;

/// 加在子View
- (void)loadSubviews;

@end

@protocol PLVMediaSecondaryViewDelegate <NSObject>

/// 云课堂直播时，单击讲师的连麦窗口切换视频和PPT窗口，普通直播不做处理
- (void)switchScreenOnManualControl:(PLVMediaSecondaryView *)secondaryView;

@end
