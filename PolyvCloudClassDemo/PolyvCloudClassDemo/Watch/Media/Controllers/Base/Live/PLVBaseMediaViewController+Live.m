//
//  PLVBaseMediaViewController+Live.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/22.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController+Live.h"
#import <AVFoundation/AVFoundation.h>
#import <PolyvFoundationSDK/PLVProgressHUD.h>
#import "PLVLiveMediaProtocol.h"

@interface PLVBaseMediaViewController () <PLVLiveMediaProtocol, PLVPlayerSkinViewDelegate, PLVPlayerSkinMoreViewDelegate, PLVPlayerInputViewDelegate, PLVPlayerSkinAudioModeViewDelegate>

@end

@implementation PLVBaseMediaViewController (Live)

#pragma mark - protected
- (void)reOpenPlayerWithLineIndex:(NSInteger)lineIndex codeRate:(NSString *)codeRate showHud:(BOOL)showHud {
    if (!self.reOpening && !((PLVLivePlayerController *)self.player).linkMic) {
        self.reOpening = YES;
        PLVProgressHUD *hud = nil;
        if (showHud) {
            hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
            [hud.label setText:@"加载JSON..."];
        }
        
        __weak typeof(self) weakSelf = self;
        [(PLVLivePlayerController *)self.player loadChannelWithLineIndex:lineIndex codeRate:codeRate completion:^{
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

- (void)loadCountdownTimeLabel:(NSDate *)startTime {
    self.startTime = startTime;
    if (!self.countdownTimeView) {
        self.skinView.topBgImgV.hidden = YES;
        self.countdownTimeView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.mainView.frame.origin.y + 44.0)];
        self.countdownTimeView.backgroundColor = [UIColor colorWithRed:33.0 / 255.0 green:170.0 / 255.0 blue:242.0 / 255.0 alpha:1.0];
        [self.view insertSubview:self.countdownTimeView belowSubview:self.skinView];
        
        self.countdownTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, self.mainView.frame.origin.y, self.view.bounds.size.width, 44.0)];
        self.countdownTimeLabel.backgroundColor = [UIColor clearColor];
        self.countdownTimeLabel.textAlignment = NSTextAlignmentCenter;
        self.countdownTimeLabel.textColor = [UIColor whiteColor];
        self.countdownTimeLabel.font = [UIFont systemFontOfSize:15.0];
        self.countdownTimeLabel.hidden = self.skinView.fullscreen;
        [self.countdownTimeView addSubview:self.countdownTimeLabel];
        
        self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdown) userInfo:nil repeats:YES];
        [self.countdownTimer fire];
    }
}

- (NSString *)countdownText:(NSTimeInterval)timeInterval {
    int daySeconds = 3600 * 24;
    int day = timeInterval / daySeconds;
    int hour = (timeInterval - day * daySeconds) / 3600;
    int min = (timeInterval - day * daySeconds - hour * 3600) / 60;
    int sec = timeInterval - day * daySeconds - hour * 3600 - min * 60;
    return [NSString stringWithFormat:@"倒计时：%@ 天 %@ 小时 %@ 分 %@ 秒", [NSString stringWithFormat:day < 10 ? @"0%d" : @"%d", day], [NSString stringWithFormat:hour < 10 ? @"0%d" : @"%d", hour], [NSString stringWithFormat:min < 10 ? @"0%d" : @"%d", min], [NSString stringWithFormat:sec < 10 ? @"0%d" : @"%d", sec]];
}

- (void)countdown {
    if (self.countdownTimeView != nil && !self.countdownTimeView.hidden) {
        NSTimeInterval timeInterval = [self.startTime timeIntervalSinceNow];
        if (timeInterval > 0.0) {
            self.countdownTimeLabel.text = [self countdownText:timeInterval];
        } else {
            [self clearCountdownTimer];
        }
    }
}

- (void)clearCountdownTimer {
    self.skinView.topBgImgV.hidden = NO;
    if (self.countdownTimeView) {
        [self.countdownTimeView removeFromSuperview];
        self.countdownTimeView = nil;
    }
    if (self.countdownTimer) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
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
    [self reOpenPlayerWithLineIndex:-1 codeRate:nil showHud:NO];
}

- (void)pause:(PLVPlayerSkinView *)skinView {
    [(PLVLivePlayerController *)self.player pause];
}

- (void)refresh:(PLVPlayerSkinView *)skinView {
    [self reOpenPlayerWithLineIndex:-1 codeRate:nil showHud:NO];
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
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView line:(NSUInteger)line {
    [self reOpenPlayerWithLineIndex:line codeRate:self.moreView.curCodeRate showHud:YES];
}

- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView codeRate:(NSString *)codeRate{
    [self reOpenPlayerWithLineIndex:-1 codeRate:codeRate showHud:YES];
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
