//
//  PLVBaseMediaViewController+PPT.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController+PPT.h"
#import "PLVPPTMediaProtocol.h"
#import "PCCUtils.h"

@interface PLVBaseMediaViewController () <PLVPPTMediaProtocol, PLVPlayerSkinViewDelegate, PLVPlayerControllerDelegate, PLVPPTViewControllerDelegate>

@end

@implementation PLVBaseMediaViewController (PPT)

#pragma mark - public
- (void)dealDeviceOrientationBeignAnimation {
    if (self.skinView.fullscreen) {
        if ([self.player isKindOfClass:[PLVLivePlayerController class]]) {
            [self.view.superview insertSubview:self.secondaryView atIndex:0];
        } else {
            [self.view.superview addSubview:self.secondaryView];
        }
    } else {
        [self.view insertSubview:self.secondaryView belowSubview:self.skinView];
        [self.view insertSubview:self.secondaryView belowSubview:self.marqueeView];
    }
}

- (void)dealDeviceOrientationEndAnimation {
    if (self.skinView.fullscreen) {
        [self.view insertSubview:self.secondaryView belowSubview:self.skinView];
        [self.view insertSubview:self.secondaryView belowSubview:self.marqueeView];
    } else {
        if ([self.player isKindOfClass:[PLVLivePlayerController class]]) {
            [self.view.superview insertSubview:self.secondaryView atIndex:1];
        } else {
            [self.view.superview addSubview:self.secondaryView];
        }
    }
}

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
            secondaryRect.origin = CGPointMake(safeFrame.origin.x, 0.0);
        } else {
            secondaryRect.origin = CGPointMake(0.0, 0.0);
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
}

#pragma mark - PLVPPTMediaProtocol
- (void)loadSecondaryView:(CGRect)rect {
    self.originSecondaryFrame = rect;
    self.secondaryView = [[PLVMediaSecondaryView alloc] initWithFrame:self.originSecondaryFrame];
    self.secondaryView.delegate = self;
    self.secondaryView.backgroundColor = [UIColor whiteColor];
    [self.secondaryView loadSubviews];

    [self loadPPT];
    [self loadPlayer];
    if ([self.player isKindOfClass:[PLVLivePlayerController class]]) {
        self.secondaryView.canMove = NO;
        [self.view.superview insertSubview:self.secondaryView belowSubview:self.view];
    } else {
        self.secondaryView.canMove = YES;
        [self.view.superview addSubview:self.secondaryView];
    }
}

#pragma mark - private
- (void)loadPPT {
    self.pptVC = [[PLVPPTViewController alloc] init];
    // 此处定义需要设置的PPT占位图、宽度和背景色
//    self.pptVC.pptBackgroundImgUrl = @"";
//    self.pptVC.pptBackgroundImgWidth = @"100px";
//    self.pptVC.pptBackgroundColor = @"rgba(0,0,0,0)";
    self.pptVC.delegate = self;
    self.pptVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIView *displayView = self.pptOnSecondaryView ? self.secondaryView : self.mainView;
    self.pptVC.view.frame = displayView.bounds;
    [displayView insertSubview:self.pptVC.view atIndex:0];
    [self loadPPTEnd];
    self.pptVC.backgroundImgView.image = [PCCUtils getBaseMediaImage:@"plv_skin_ppt_background"]; // 可在此处自定义PPT背景图（本地图片或网络图片）
}

- (void)hiddenSecondaryView:(BOOL)hidden {
    self.secondaryView.hidden = hidden;
    [self.skinView modifySwitchScreenBtnState:self.secondaryView.hidden pptOnSecondaryView:self.pptOnSecondaryView];
    [self resetLinkMicTopControlFrame:hidden];
}

- (void)resetLinkMicTopControlFrame:(BOOL)close {
    
}

#pragma mark - PLVMediaSecondaryViewDelegate
- (void)switchScreenOnManualControl:(PLVMediaSecondaryView *)secondaryView {
    [self switchAction:YES];
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)closeSecondaryView:(PLVPlayerSkinView *)skinView {
    if (self.secondaryView.hidden) {
        [self openSecondaryView];
    } else {
        [self hiddenSecondaryView:YES];
    }
}

#pragma mark - PLVPlayerControllerDelegate
- (void)subPlaybackIsPreparedToPlay:(NSNotification *)notification {
    self.skinView.controllView.hidden = YES;
    if (!self.pptOnSecondaryView) {//主屏切换为暖场，副屏为PPT
        [self switchAction:NO];
    }
    if (self.pptOnSecondaryView && !self.secondaryView.hidden) {//关闭副屏的PPT
        [self closeSecondaryView:self.skinView];
    }
}

- (void)mainPlaybackIsPreparedToPlay:(NSNotification *)notification {
    self.skinView.controllView.hidden = NO;
    [self skinShowAnimaion];

    if ([self.player isKindOfClass:PLVLivePlayerController.class]) {
        [self.moreView modifyModeBtnSelected:((PLVLivePlayerController*)self.player).audioMode];
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
        self.mainView.backgroundColor = playerController.showVideoView ? [UIColor blackColor] : GrayBackgroundColor;
    } else {
        self.secondaryView.backgroundColor = playerController.showVideoView ? [UIColor blackColor] : [UIColor whiteColor];
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

- (void)sendPaintInfo:(PLVPPTViewController *)pptVC jsonData:(NSString *)jsonData {
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendPaintInfo:jsonData:)]) {
        [self.delegate sendPaintInfo:self jsonData:jsonData];
    }
}

@end
