//
//  PLVMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVMediaViewController.h"
#import <PolyvCloudClassSDK/PLVLivePlayerController.h>
#import "PLVMediaViewControllerPrivateProtocol.h"
#import "PLVMediaViewControllerProtocol.h"

#define BlueBackgroundColor [UIColor colorWithRed:215.0 / 255.0 green:242.0 / 255.0 blue:254.0 / 255.0 alpha:1.0]

@interface PLVMediaViewController () <PLVMediaViewControllerPrivateProtocol, PLVMediaViewControllerProtocol, PLVPlayerControllerDelegate, PLVPlayerSkinViewDelegate, PLVMediaSecondaryViewDelegate, PLVPPTViewControllerDelegate>

@property (nonatomic, assign) CGRect originFrame;//页面初始化，记住竖屏时view的Frame，横竖屏切换的动画需要使用
@property (nonatomic, assign) BOOL skinShowed;//播放器皮肤是否已显示
@property (nonatomic, assign) BOOL skinAnimationing;//播放器皮肤显示隐藏动画的开关
@property (nonatomic, assign) BOOL zoomAnimationing;//横竖屏切换动画的开关
@property (nonatomic, assign) UIDeviceOrientation curOrientation;//设备的当前方向，横竖屏切换动画需要使用

@end

@implementation PLVMediaViewController

@synthesize player;
@synthesize pptVC;
@synthesize skinView;
@synthesize mainView;
@synthesize secondaryView;
@synthesize originSecondaryFrame;
@synthesize pptOnSecondaryView;
@synthesize pptFlag;

- (void)clearResource {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [self.player clearPlayersAndTimers];
}

- (void)loadPPT {
    self.pptVC = [[PLVPPTViewController alloc] init];
    self.pptVC.delegate = self;
    self.pptVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIView *displayView = self.pptOnSecondaryView ? self.secondaryView : self.mainView;
    self.pptVC.view.frame = displayView.bounds;
    [displayView insertSubview:self.pptVC.view atIndex:0];
}

- (void)loadSecondaryView:(CGRect)rect {
    self.originFrame = self.view.frame;
    self.originSecondaryFrame = rect;
    self.secondaryView = [[PLVMediaSecondaryView alloc] initWithFrame:rect];
    self.secondaryView.delegate = self;
    self.secondaryView.backgroundColor = [UIColor whiteColor];
    [self.secondaryView loadSubviews];
    [self.view.superview addSubview:self.secondaryView];
    [self loadPlayer];
}

- (BOOL)fullscreen {
    return self.skinView.fullscreen;
}

- (void)skinAlphaAnimaion:(CGFloat)alpha {
    self.skinAnimationing = YES;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.skinView.alpha = alpha;
    } completion:^(BOOL finished) {
        weakSelf.skinAnimationing = NO;
        weakSelf.skinShowed = (alpha == 1.0 ? YES : NO);
    }];
}

- (void)skinHiddenAnimaion {
    [self skinAlphaAnimaion:0.0];
}

- (void)skinShowAnimaion {
    [self skinAlphaAnimaion:1.0];
    [self performSelector:@selector(skinHiddenAnimaion) withObject:nil afterDelay:3.0];
}

- (void)tapAction {
    if (!self.skinAnimationing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(skinHiddenAnimaion) object:nil];
        if (self.skinShowed) {
            [self skinHiddenAnimaion];
        } else {
            [self skinShowAnimaion];
        }
    }
}

- (void)loadSkinView:(PLVPlayerSkinViewType)skinType {
    self.skinView = [[PLVPlayerSkinView alloc]  initWithFrame:self.view.bounds];
    self.skinView.delegate = self;
    self.skinView.type = skinType;
    self.skinView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.skinView];
    [self.skinView loadSubviews];
    self.skinView.controllView.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.skinShowed = YES;
    self.curOrientation = UIDeviceOrientationPortrait;
    
    self.mainView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.mainView.backgroundColor = BlueBackgroundColor;
    self.mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mainView];
    
    [self loadPPT];
    
    //单击显示或隐藏皮肤
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

//======PLVMediaSecondaryViewDelegate======
- (void)closeSecondaryView:(PLVMediaSecondaryView *)secondaryView {
    [self hiddenSecondaryView:YES];
}

- (void)hiddenSecondaryView:(BOOL)hidden {
    self.secondaryView.hidden = hidden;
    [self.skinView modifySwitchScreenBtnState:self.secondaryView.hidden pptOnSecondaryView:self.pptOnSecondaryView];
}

- (void)openSecondaryView {
    [self hiddenSecondaryView:NO];
    self.secondaryView.backgroundColor = [UIColor whiteColor];
    [self.secondaryView showCloseBtn];
}

//======PLVPlayerSkinViewDelegate======
- (void)quit:(PLVPlayerSkinView *)skinView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(quit:)]) {
        [self.delegate quit:self];
    }
}

- (void)switchAction:(BOOL)manualControl {
    self.pptOnSecondaryView = !self.pptOnSecondaryView;
    if (!self.pptOnSecondaryView) {
        [self.secondaryView insertSubview:self.player.playerView atIndex:0];
        [self.player setFrame:self.secondaryView.bounds];
        [self.mainView insertSubview:self.pptVC.view atIndex:0];
        self.pptVC.view.frame = self.mainView.bounds;
    } else {
        if (manualControl) {
            self.pptFlag = manualControl;
        }
        [self.mainView insertSubview:self.player.playerView atIndex:0];
        [self.player setFrame:self.mainView.bounds];
        [self.secondaryView insertSubview:self.pptVC.view atIndex:0];
        self.pptVC.view.frame = self.secondaryView.bounds;
    }
    [self changePPTScreenBackgroundColor:self.pptVC];
    [self changePlayerScreenBackgroundColor:self.player];
}

- (void)switchScreenOnManualControl:(PLVPlayerSkinView *)skinView {
    if (self.secondaryView.hidden) {
        [self openSecondaryView];
    } else {
        [self switchAction:YES];
    }
}

//横竖屏选装动画
- (void)deviceOrientationDidChange {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (!self.zoomAnimationing && self.curOrientation != orientation) {
        CGRect rect = self.originFrame;
        CGFloat angle = 0.0;
        BOOL fullscreen = NO;
        BOOL flip = NO;
        if (UIDeviceOrientationIsLandscape(orientation)) {
            rect = [UIScreen mainScreen].bounds;
            angle = (orientation == UIDeviceOrientationLandscapeRight ? -M_PI_2 : M_PI_2);
            fullscreen = YES;
            if (UIDeviceOrientationIsLandscape(self.curOrientation)) {//水平翻转时，只改变view.transform，不改变view.frame
                flip = YES;
            }
        }
        self.curOrientation = orientation;
        self.zoomAnimationing = YES;
        
        __weak typeof(self) weakSelf = self;
        [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation)orientation animated:YES];
        [UIView animateWithDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration] delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.skinView.fullscreen = fullscreen;
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(statusBarAppearanceNeedsUpdate:)]) {
                //delegate回调隐藏或显示statusBar，一定要放在最前前执行，因为layout时需要用到安全区域，而statusBar的隐藏或显示会影响安全区域的y坐标
                [weakSelf.delegate statusBarAppearanceNeedsUpdate:weakSelf];
            }
            CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(angle);
            weakSelf.view.transform = rotationTransform;
            if (!flip) {
                weakSelf.view.frame = rect;
            }
            CGRect mainRect = weakSelf.view.bounds;
            if (fullscreen) {
                if (@available(iOS 11.0, *)) {
                    CGRect safeFrame = weakSelf.view.safeAreaLayoutGuide.layoutFrame;
                    mainRect.origin.x = safeFrame.origin.x;
                    mainRect.size.width = safeFrame.size.width;
                }
            }
            weakSelf.mainView.frame = mainRect;
            UIView *displayView = weakSelf.pptOnSecondaryView ? weakSelf.mainView : weakSelf.secondaryView;
            [weakSelf.player setFrame:displayView.bounds];
            if ([weakSelf.player isKindOfClass:[PLVLivePlayerController class]]) {
                [(PLVLivePlayerController *)weakSelf.player hiddenTriviaCard:fullscreen];
            }
            [weakSelf.skinView layout];
            weakSelf.secondaryView.fullscreen = fullscreen;
            weakSelf.secondaryView.transform = rotationTransform;
            CGRect secondaryRect = weakSelf.originSecondaryFrame;
            if (weakSelf.secondaryView.fullscreen) {
                if (orientation == UIDeviceOrientationLandscapeRight) {
                    secondaryRect = CGRectMake(0.0, mainRect.origin.x, self.originSecondaryFrame.size.height, self.originSecondaryFrame.size.width);
                } else {
                    secondaryRect = CGRectMake(mainRect.origin.y + mainRect.size.height - self.originSecondaryFrame.size.height, mainRect.origin.x + mainRect.size.width - self.originSecondaryFrame.size.width, self.originSecondaryFrame.size.height, self.originSecondaryFrame.size.width);
                }
            }
            weakSelf.secondaryView.frame = secondaryRect;
            if ([weakSelf respondsToSelector:@selector(deviceOrientationDidChangeSubAnimation:)]) {
                [weakSelf deviceOrientationDidChangeSubAnimation:rotationTransform];
            }
            [weakSelf.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            weakSelf.zoomAnimationing = NO;
        }];
    }
}

//============PLVPlayerControllerDelegate============
- (void)playerController:(PLVPlayerController *)playerController codeRateItems:(NSMutableArray *)codeRateItems codeRate:(NSString *)codeRate {
    self.skinView.codeRateItems = codeRateItems;
    [self.skinView layout];
    [self.skinView switchCodeRate:codeRate];
}

- (void)playerController:(PLVPlayerController *)playerController loadMainPlayerFailure:(NSString *)message {
    [self openSecondaryView];
}

- (void)adPreparedToPlay:(PLVPlayerController *)playerController {
    self.skinView.controllView.hidden = YES;
    if (!self.pptOnSecondaryView) {//主屏切换为暖场，副屏为PPT
        [self switchAction:NO];
    }
    if (self.pptOnSecondaryView) {//关闭副屏的PPT
        [self closeSecondaryView:self.secondaryView];
    }
}

- (BOOL)cameraClosed {
    BOOL cameraClosed = NO;
    if ([self.player isKindOfClass:[PLVLivePlayerController class]]) {
        cameraClosed = ((PLVLivePlayerController *)self.player).cameraClosed;
    }
    return cameraClosed;
}

- (void)mainPreparedToPlay:(PLVPlayerController *)playerController {
    self.pptVC.pptPlayable = YES;
    
    self.skinView.controllView.hidden = NO;
    [self skinShowAnimaion];
    
    if (self.pptOnSecondaryView && !self.player.playingAD && !self.pptFlag) {//自动切换主屏为PPT，副屏为视频
        self.pptFlag = YES;
        [self switchAction:NO];
    }

    if (![self cameraClosed] && !self.player.playingAD && !self.pptOnSecondaryView && self.secondaryView.hidden) {
        [self openSecondaryView];//推流端打开了摄像头，而iOS端，正在播放直播（非广告），副屏为视频且已经关闭，则自动打开副屏
    }
    [self.skinView modifySwitchScreenBtnState:self.secondaryView.hidden pptOnSecondaryView:self.pptOnSecondaryView];
}

- (void)playerController:(PLVPlayerController *)playerController showMessage:(NSString *)message {
    [self.skinView showMessage:message];
}

- (void)changePlayerScreenBackgroundColor:(PLVPlayerController *)playerController {
    if (self.pptOnSecondaryView) {
        self.mainView.backgroundColor = (self.player.playable && (![self cameraClosed] || self.player.playingAD)) ? [UIColor blackColor] : BlueBackgroundColor;
    } else {
        self.secondaryView.backgroundColor = (self.player.playable && (![self cameraClosed] || self.player.playingAD)) ? [UIColor blackColor] : [UIColor whiteColor];
    }
}

- (BOOL)onSafeArea:(PLVPlayerController *)playerController {
    return self.pptOnSecondaryView && !self.skinView.fullscreen;
}

//============PLVPPTViewControllerDelegate============
- (void)changePPTScreenBackgroundColor:(PLVPPTViewController *)pptVC {
    if (self.pptOnSecondaryView) {
        self.secondaryView.backgroundColor = self.pptVC.pptPlayable ? [UIColor blackColor] : [UIColor whiteColor];
    } else {
        self.mainView.backgroundColor = self.pptVC.pptPlayable ? [UIColor blackColor] : BlueBackgroundColor;
    }
}

@end
