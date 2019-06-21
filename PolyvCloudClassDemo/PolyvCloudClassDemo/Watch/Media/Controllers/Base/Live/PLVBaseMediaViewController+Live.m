//
//  PLVBaseMediaViewController+Live.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/22.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController+Live.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "PLVLiveMediaProtocol.h"

@interface PLVBaseMediaViewController () <PLVLiveMediaProtocol, PLVPlayerSkinViewDelegate, PLVPlayerSkinMoreViewDelegate, PLVPlayerInputViewDelegate, PLVPlayerSkinAudioModeViewDelegate>

@end

@implementation PLVBaseMediaViewController (Live)

#pragma mark - protected
- (void)reOpenPlayer:(NSString *)codeRate showHud:(BOOL)showHud {
    if (!self.reOpening && !((PLVLivePlayerController *)self.player).linkMic) {
        self.reOpening = YES;
        MBProgressHUD *hud = nil;
        if (showHud) {
            hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
            [hud.label setText:@"加载JSON..."];
        }
        
        __weak typeof(self) weakSelf = self;
        [(PLVLivePlayerController *)self.player loadChannel:codeRate completion:^{
            weakSelf.reOpening = NO;
            if (hud != nil) {
                hud.label.text = @"JSON加载成功";
                [hud hideAnimated:YES];
            }
        } failure:^(NSString *message) {
            weakSelf.reOpening = NO;
            if (hud != nil) {
                hud.label.text = [NSString stringWithFormat:@"JSON加载失败:%@", message];
                [hud hideAnimated:YES];
            }
        }];
    }
}

#pragma mark - PLVLiveMediaProtocol
- (void)danmu:(NSMutableAttributedString *)message {
    [self addDanmuLayer];
    [self.danmuLayer insertScrollDML:message];
    [self addDanmuInputView];
}

- (void)addDanmuLayer {
    if (self.danmuLayer == nil) {
        CGRect danmuRect = self.mainView.bounds;
        if (@available(iOS 11.0, *)) {
            danmuRect = self.mainView.safeAreaLayoutGuide.layoutFrame;
        }
        if (CGRectEqualToRect(danmuRect, CGRectZero)) { return; }
        self.danmuLayer = [[ZJZDanMu alloc] initWithFrame:danmuRect];
        self.danmuLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.danmuLayer.hidden = YES;
        self.danmuLayer.userInteractionEnabled = NO;
        [self.view insertSubview:self.danmuLayer belowSubview:self.skinView];
    }
}

- (void)addDanmuInputView {
    if (self.danmuInputView == nil) {
        if (self.view.superview == nil) { return; }
        self.danmuInputView = [[PLVPlayerInputView alloc]initWithFrame:self.view.superview.bounds];
        self.danmuInputView.delegate = self;
        [self.view.superview addSubview:self.danmuInputView];
    }
}

- (NSString *)currentChannelSessionId; {
    return [((PLVLivePlayerController *)self.player) currentChannelSessionId];
}

- (void)addAudioModeView {
    if ([self.player isKindOfClass:PLVLivePlayerController.class] && ((PLVLivePlayerController *)self.player).audioModeDisplayView == nil) {
        PLVPlayerSkinAudioModeView * audioModeV = [[PLVPlayerSkinAudioModeView alloc]init];
        audioModeV.delegate = self;
        ((PLVLivePlayerController *)self.player).audioModeDisplayView = audioModeV;
    }
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)play:(PLVPlayerSkinView *)skinView {
    [self reOpenPlayer:nil showHud:NO];
}

- (void)pause:(PLVPlayerSkinView *)skinView {
    [(PLVLivePlayerController *)self.player pause];
}

- (void)refresh:(PLVPlayerSkinView *)skinView {
    [self reOpenPlayer:nil showHud:NO];
}

- (void)linkMic:(PLVPlayerSkinView *)skinView {
    [self.linkMicVC linkMic];
}

- (void)switchCamera:(PLVPlayerSkinView *)skinView {
    PLVLinkMicView *linkMicView = [self.linkMicVC.linkMicViewArray objectAtIndex:0];
    if (linkMicView.switchCameraBtn) {
        [self.linkMicVC switchCamera:nil];
    }
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView switchDanmu:(BOOL)switchDanmu {
    [self addDanmuLayer];
    self.danmuLayer.hidden = !switchDanmu;
    [self addDanmuInputView];
}

- (void)showInput:(PLVPlayerSkinView *)skinView{
    [self skinHiddenAnimaion];
    [self.danmuInputView show];
    [self.view.superview bringSubviewToFront:self.danmuInputView];
}

#pragma mark - PLVPlayerSkinMoreViewDelegate
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView codeRate:(NSString *)codeRate{
    [self reOpenPlayer:codeRate showHud:YES];
}

- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView switchAudioMode:(BOOL)switchAudioMode{
    if (switchAudioMode) {
        [self addAudioModeView];
        [(PLVLivePlayerController *)self.player switchAudioMode:YES];
    }else{
        [(PLVLivePlayerController *)self.player switchAudioMode:NO];
    }
}

#pragma mark - PLVPlayerInputViewDelegate
- (void)playerInputView:(PLVPlayerInputView *)inputView didSendText:(NSString *)text{
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendText:text:)]) {
        [self.delegate sendText:self text:text];
    }
}

#pragma mark - PLVLivePlayerControllerDelegate
- (void)livePlayerController:(PLVLivePlayerController *)livePlayer playing:(BOOL)playing{
    [self.skinView modifyMainBtnState:playing];
}

#pragma mark - PLVPlayerSkinAudioModeViewDelegate
- (void)playVideoAudioModeView:(PLVPlayerSkinAudioModeView *)audioModeView{
    [(PLVLivePlayerController *)self.player switchAudioMode:NO];
}

@end
