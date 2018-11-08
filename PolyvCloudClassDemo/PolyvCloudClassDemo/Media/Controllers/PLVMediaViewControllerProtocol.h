//
//  PLVMediaViewControllerProtocol.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/9/18.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <PolyvCloudClassSDK/PLVLivePlayerController.h>
#import <PolyvCloudClassSDK/PLVPPTViewController.h>
#import "PLVMediaSecondaryView.h"

@protocol PLVMediaViewControllerProtocol <NSObject>

@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;
@property (nonatomic, strong) PLVPPTViewController *pptVC;
@property (nonatomic, strong) PLVPlayerSkinView *skinView;//播放器的皮肤
@property (nonatomic, strong) UIView *mainView;//主屏
@property (nonatomic, strong) PLVMediaSecondaryView *secondaryView;//副屏
@property (nonatomic, assign) CGRect originSecondaryFrame;//页面初始化，记住竖屏时副屏的Frame，横竖屏切换的动画需要使用
@property (nonatomic, assign) BOOL pptOnSecondaryView;//PPT是否在副屏
@property (nonatomic, assign) BOOL pptFlag;//PPT主副屏自动切换标志位

@optional
//以下方法，由子类PLVLiveMediaViewController或PLVVodMediaViewController实现，在父类PLVMediaViewController的viewDidLoad中调用

//加载播放器
- (void)loadPlayer;

@end
