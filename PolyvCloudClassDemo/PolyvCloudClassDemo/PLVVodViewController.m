//
//  PLVVodViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVVodViewController.h"
#import "PLVVodMediaViewController.h"

#define PlayerViewScale (3.0 / 4.0)

@interface PLVVodViewController () <PLVMediaViewControllerDelegate>

@property (nonatomic, strong) PLVVodMediaViewController *mediaVC;

@end

@implementation PLVVodViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.mediaVC = [[PLVVodMediaViewController alloc] init];
    self.mediaVC.delegate = self;
    self.mediaVC.vodVideo = self.vodVideo;
    CGFloat h = self.view.bounds.size.width * PlayerViewScale + 44.0;
    self.mediaVC.view.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, h);
    [self.view addSubview:self.mediaVC.view];
    CGFloat w = (int)([UIScreen mainScreen].bounds.size.width / 3.0);
    [self.mediaVC loadSecondaryView:CGRectMake(self.mediaVC.view.frame.size.width - w, self.mediaVC.view.frame.origin.y + self.mediaVC.view.frame.size.height, w, (int)(w * PlayerViewScale))];
}

#pragma mark <PLVMediaViewControllerDelegate>
- (void)quit:(PLVMediaViewController *)mediaVC {
    [self.mediaVC clearResource];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)statusBarAppearanceNeedsUpdate:(PLVMediaViewController *)mediaVC {
    [self setNeedsStatusBarAppearanceUpdate];//横竖屏切换前，更新Status Bar的状态
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {//设备方向旋转，横竖屏切换，但UIViewController不需要旋转，在播放器的父类里自己实现旋转的动画效果
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    if ([self.mediaVC fullscreen]) {//横屏时，隐藏Status Bar
        return YES;
    } else {
        return NO;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {//Status Bar颜色随底色高亮变化
    return UIStatusBarStyleLightContent;
}

@end
