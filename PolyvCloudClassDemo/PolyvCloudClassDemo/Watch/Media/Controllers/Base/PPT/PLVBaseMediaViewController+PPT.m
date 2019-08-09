//
//  PLVBaseMediaViewController+PPT.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController+PPT.h"
#import "PLVPPTMediaProtocol.h"

@interface PLVBaseMediaViewController () <PLVPPTMediaProtocol, PLVPlayerSkinViewDelegate, PLVPlayerControllerDelegate, PLVPPTViewControllerDelegate>

@end

@implementation PLVBaseMediaViewController (PPT)

#pragma mark - public
- (void)dealDeviceOrientationDidChangeSubAnimation {
    UIView *displayView = self.pptOnSecondaryView ? self.mainView : self.secondaryView;
    [self.player setFrame:displayView.bounds];
    
    CGRect secondaryRect = self.originSecondaryFrame;
    self.secondaryView.fullscreen = self.skinView.fullscreen;
    if (self.secondaryView.fullscreen) {
        if (@available(iOS 11.0, *)) {
            CGRect safeFrame = self.view.superview.safeAreaLayoutGuide.layoutFrame;
            // 快速旋转时，safeAreaLayoutGuide 如果出现横竖屏错乱的情况，手动调整
            if (safeFrame.origin.y > 0.0) {
                safeFrame.origin = CGPointMake(safeFrame.origin.y, safeFrame.origin.x);
            }
            if (safeFrame.size.width < safeFrame.size.height) {
                safeFrame.size = CGSizeMake(safeFrame.size.height, safeFrame.size.width);
            }
            secondaryRect.origin = CGPointMake(safeFrame.origin.x + safeFrame.size.width - secondaryRect.size.width, 0.0);
        } else {
            secondaryRect.origin = CGPointMake(self.view.bounds.size.width - secondaryRect.size.width, 0.0);
        }
    }
    self.secondaryView.frame = secondaryRect;
}

- (void)dealSwitchAction:(BOOL)manualControl {
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

- (void)openSecondaryView {
    [self hiddenSecondaryView:NO];
    [self.secondaryView showCloseBtn];
}

#pragma mark - PLVPPTMediaProtocol
- (void)loadSecondaryView:(CGRect)rect {
    self.originSecondaryFrame = rect;
    self.secondaryView = [[PLVMediaSecondaryView alloc] initWithFrame:self.originSecondaryFrame];
    self.secondaryView.delegate = self;
    self.secondaryView.backgroundColor = [UIColor whiteColor];
    [self.secondaryView loadSubviews];
    [self.view.superview addSubview:self.secondaryView];
    [self loadPPT];
    [self loadPlayer];
}

#pragma mark - private
- (void)loadPPT {
    self.pptVC = [[PLVPPTViewController alloc] init];
    self.pptVC.delegate = self;
    self.pptVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.pptVC.backgroundImgView setContentMode:UIViewContentModeScaleAspectFit];
    UIView *displayView = self.pptOnSecondaryView ? self.secondaryView : self.mainView;
    self.pptVC.view.frame = displayView.bounds;
    [displayView insertSubview:self.pptVC.view atIndex:0];
}

- (void)hiddenSecondaryView:(BOOL)hidden {
    self.secondaryView.hidden = hidden;
    [self.skinView modifySwitchScreenBtnState:self.secondaryView.hidden pptOnSecondaryView:self.pptOnSecondaryView];
}

#pragma mark - PLVMediaSecondaryViewDelegate
- (void)closeSecondaryView:(PLVMediaSecondaryView *)secondaryView {
    [self hiddenSecondaryView:YES];
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)switchScreenOnManualControl:(PLVPlayerSkinView *)skinView {
    if (self.secondaryView.hidden) {
        [self openSecondaryView];
    } else {
        [self switchAction:YES];
    }
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController subPlaybackIsPreparedToPlay:(NSNotification *)notification {
    self.skinView.controllView.hidden = YES;
    if (!self.pptOnSecondaryView) {//主屏切换为暖场，副屏为PPT
        [self switchAction:NO];
    }
    if (self.pptOnSecondaryView) {//关闭副屏的PPT
        [self closeSecondaryView:self.secondaryView];
    }
}

- (void)mainPlaybackIsPreparedToPlay:(NSNotification *)notification {
    self.skinView.controllView.hidden = NO;
    [self skinShowAnimaion];

    if ([self.player isKindOfClass:PLVLivePlayerController.class]) {
        [self.moreView modifyModeBtnSelected:((PLVLivePlayerController*)self.player).audioMode];
    }
    
    self.pptVC.pptPlayable = YES;
    if (self.pptOnSecondaryView && !self.player.playingAD && !self.pptFlag) {//自动切换主屏为PPT，副屏为视频
        self.pptFlag = YES;
        [self switchAction:NO];
    }

    if (![self cameraClosed] && !self.player.playingAD && !self.pptOnSecondaryView && self.secondaryView.hidden) {
        [self openSecondaryView];//推流端打开了摄像头，而iOS端，正在播放直播（非广告），副屏为视频且已经关闭，则自动打开副屏
    }
    [self.skinView modifySwitchScreenBtnState:self.secondaryView.hidden pptOnSecondaryView:self.pptOnSecondaryView];
}

- (void)changePlayerScreenBackgroundColor:(PLVPlayerController *)playerController {
    if ([playerController isKindOfClass:PLVLivePlayerController.class] && ((PLVLivePlayerController *)playerController).linkMic) {
        return;
    }
    if (self.pptOnSecondaryView) {
        self.mainView.backgroundColor = playerController.backgroundImgView.hidden ? [UIColor blackColor] : GrayBackgroundColor;
    } else {
        self.secondaryView.backgroundColor = playerController.backgroundImgView.hidden ? [UIColor blackColor] : [UIColor whiteColor];
    }
    
    if ([playerController isKindOfClass:PLVLivePlayerController.class]) {
        BOOL showAudioModeBtn = ((PLVLivePlayerController*)self.player).supportAudioMode && self.player.playable;
        [self.moreView showAudioModeBtn:showAudioModeBtn];
        [self.moreView modifyModeBtnSelected:((PLVLivePlayerController*)self.player).audioMode];
    }
}

- (BOOL)cameraClosed {
    BOOL cameraClosed = NO;
    if ([self.player isKindOfClass:[PLVLivePlayerController class]]) {
        cameraClosed = ((PLVLivePlayerController *)self.player).cameraClosed;
    }
    return cameraClosed;
}

#pragma mark - PLVPPTViewControllerDelegate
- (void)changePPTScreenBackgroundColor:(PLVPPTViewController *)pptVC {
    if (self.pptOnSecondaryView) {
        self.secondaryView.backgroundColor = self.pptVC.pptPlayable ? [UIColor blackColor] : [UIColor whiteColor];
    } else {
        self.mainView.backgroundColor = self.pptVC.pptPlayable ? [UIColor blackColor] : BlueBackgroundColor;
    }
}

@end
