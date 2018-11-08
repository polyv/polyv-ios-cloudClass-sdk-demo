//
//  PLVMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVPlayerSkinView.h"

@protocol PLVMediaViewControllerDelegate;

@interface PLVMediaViewController : UIViewController

@property (nonatomic, weak) id<PLVMediaViewControllerDelegate> delegate;

//准备退出时，必须清空播放器资源
- (void)clearResource;

//加载副屏
- (void)loadSecondaryView:(CGRect)rect;

//是否全屏
- (BOOL)fullscreen;

//切换主副屏的操作，直播子类有连麦时要重写实现
- (void)switchAction:(BOOL)manualControl;

@end

@protocol PLVMediaViewControllerDelegate <NSObject>

//退出，实现上退出前要手动调用clearResource，释放相关资源
- (void)quit:(PLVMediaViewController *)mediaVC;

//横竖屏切换前，更新Status Bar的状态
- (void)statusBarAppearanceNeedsUpdate:(PLVMediaViewController *)mediaVC;

@end
