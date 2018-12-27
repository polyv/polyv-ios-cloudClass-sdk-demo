//
//  PLVPPTMediaProtocol.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <PolyvCloudClassSDK/PLVPPTViewController.h>
#import "PLVMediaSecondaryView.h"

/// 云课堂播放器基类协议（PPT相关功能：1.加载副屏窗口）
@protocol PLVPPTMediaProtocol <NSObject>

/// PPT
@property (nonatomic, strong) PLVPPTViewController *pptVC;
/// 副屏
@property (nonatomic, strong) PLVMediaSecondaryView *secondaryView;
/// 页面初始化，记住竖屏时副屏的Frame，横竖屏切换的动画需要使用
@property (nonatomic, assign) CGRect originSecondaryFrame;
/// PPT是否在副屏
@property (nonatomic, assign) BOOL pptOnSecondaryView;
/// PPT主副屏自动切换标志位
@property (nonatomic, assign) BOOL pptFlag;

@optional
/// 加载副屏
- (void)loadSecondaryView:(CGRect)rect;

@end
