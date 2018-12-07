//
//  PLVBaseMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PolyvCloudClassSDK/PLVLivePlayerController.h>
#import "PLVPlayerSkinView.h"

#define BlueBackgroundColor [UIColor colorWithRed:215.0 / 255.0 green:242.0 / 255.0 blue:254.0 / 255.0 alpha:1.0]

@protocol PLVBaseMediaViewControllerDelegate;

//播放器基类 - 继承于 UIViewController（功能：1.清空播放器资源；2.加载皮肤；3.显示或隐藏皮肤；4.退出；5.横竖屏切换）
@interface PLVBaseMediaViewController : UIViewController

@property (nonatomic, weak) id<PLVBaseMediaViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) PLVPlayerSkinView *skinView;//播放器的皮肤

@property (nonatomic, strong, readonly) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器
@property (nonatomic, strong, readonly) UIView *mainView;//主屏
@property (nonatomic, assign, readonly) CGRect originFrame;//页面初始化，记住竖屏时view的Frame，横竖屏切换的动画需要使用
@property (nonatomic, assign, readonly) UIDeviceOrientation curOrientation;//设备的当前方向，横竖屏切换动画需要使用

#pragma mark - public
//准备退出时，必须清空播放器资源
- (void)clearResource;

#pragma mark - protected
//加载皮肤
- (void)loadSkinView:(PLVPlayerSkinViewType)skinType;

//显示皮肤
- (void)skinShowAnimaion;

#pragma mark - protected - abstract
//横竖屏旋转动画时，云课堂相关的副窗口需要做动画的逻辑在这里实现（普通直播不需要）
- (void)deviceOrientationDidChangeSubAnimation:(CGAffineTransform)rotationTransform;

//加载视频播放器
- (void)loadPlayer;

//切换主副屏的操作，直播子类 PLVPPTLiveMediaViewController 需要要重写实现，兼容连麦的窗口切换
- (void)switchAction:(BOOL)manualControl;

@end

@protocol PLVBaseMediaViewControllerDelegate <NSObject>

//退出，退出前要手动调用clearResource，释放相关资源
- (void)quit:(PLVBaseMediaViewController *)mediaVC;

//横竖屏切换前，更新Status Bar的状态
- (void)statusBarAppearanceNeedsUpdate:(PLVBaseMediaViewController *)mediaVC;

@end
