//
//  PLVMediaSecondaryView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/9.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVMediaSecondaryViewDelegate;

//浮屏窗口
@interface PLVMediaSecondaryView : UIView

@property (nonatomic, weak) id<PLVMediaSecondaryViewDelegate> delegate;
@property (nonatomic, assign) BOOL fullscreen;

- (void)loadSubviews;
- (void)showCloseBtn;

@end

@protocol PLVMediaSecondaryViewDelegate <NSObject>

- (void)closeSecondaryView:(PLVMediaSecondaryView *)secondaryView;

@end
