//
//  PLVVodViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVVodViewController.h"
#import <PolyvBusinessSDK/PLVVodConfig.h>
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import "PLVNormalVodMediaViewController.h"
#import "PLVPPTVodMediaViewController.h"

#define PPTPlayerViewScale (3.0 / 4.0)
#define NormalPlayerViewScale (9.0 / 16.0)

@interface PLVVodViewController () <PLVBaseMediaViewControllerDelegate>

@property (nonatomic, strong) PLVBaseMediaViewController<PLVVodMediaProtocol> *mediaVC;

@end

@implementation PLVVodViewController

#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    PLVVodConfig *vodConfig = [PLVVodConfig sharedInstance];
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    
    if (self.vodType == PLVVodViewControllerTypeCloudClass) {
        self.mediaVC = [[PLVPPTVodMediaViewController alloc] init];
    } else {
        self.mediaVC = [[PLVNormalVodMediaViewController alloc] init];
    }
    
    self.mediaVC.delegate = self;
    self.mediaVC.vodId = vodConfig.vodId; //必须，不能为空
    self.mediaVC.channelId = liveConfig.channelId;
    self.mediaVC.userId = liveConfig.userId;
    
    CGFloat h = self.view.bounds.size.width * (self.vodType == PLVVodViewControllerTypeCloudClass ? PPTPlayerViewScale : NormalPlayerViewScale) + [UIApplication sharedApplication].statusBarFrame.size.height;
    self.mediaVC.view.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, h);
    [self.view addSubview:self.mediaVC.view];
    if (self.vodType == PLVVodViewControllerTypeCloudClass) {
        CGFloat w = (int)([UIScreen mainScreen].bounds.size.width / 3.0);
        [(PLVPPTVodMediaViewController *)self.mediaVC loadSecondaryView:CGRectMake(self.view.frame.size.width - w, h, w, (int)(w * PPTPlayerViewScale))];
    }
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {//设备方向旋转，横竖屏切换，但UIViewController不需要旋转，在播放器的父类里自己实现旋转的动画效果
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    if (self.mediaVC.skinView.fullscreen) {//横屏时，隐藏Status Bar
        return YES;
    } else {
        return NO;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {//Status Bar颜色随底色高亮变化
    return UIStatusBarStyleLightContent;
}

#pragma mark - PLVBaseMediaViewControllerDelegate
- (void)quit:(PLVBaseMediaViewController *)mediaVC error:(NSError *)error {
    [self.mediaVC clearResource];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)statusBarAppearanceNeedsUpdate:(PLVBaseMediaViewController *)mediaVC {
    [self setNeedsStatusBarAppearanceUpdate];//横竖屏切换前，更新Status Bar的状态
}

@end
