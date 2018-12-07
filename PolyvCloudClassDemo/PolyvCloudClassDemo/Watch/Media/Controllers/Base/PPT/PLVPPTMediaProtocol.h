//
//  PLVPPTMediaProtocol.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <PolyvCloudClassSDK/PLVPPTViewController.h>
#import "PLVMediaSecondaryView.h"

//云课堂播放器基类协议（PPT相关功能：1.加载副屏窗口）
@protocol PLVPPTMediaProtocol <NSObject>

@property (nonatomic, strong) PLVPPTViewController *pptVC;//PPT
@property (nonatomic, strong) PLVMediaSecondaryView *secondaryView;//副屏
@property (nonatomic, assign) CGRect originSecondaryFrame;//页面初始化，记住竖屏时副屏的Frame，横竖屏切换的动画需要使用
@property (nonatomic, assign) BOOL pptOnSecondaryView;//PPT是否在副屏
@property (nonatomic, assign) BOOL pptFlag;//PPT主副屏自动切换标志位

@optional
//加载副屏
- (void)loadSecondaryView:(CGRect)rect;

@end
