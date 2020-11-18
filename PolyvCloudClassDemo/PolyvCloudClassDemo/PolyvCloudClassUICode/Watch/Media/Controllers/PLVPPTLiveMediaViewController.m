//
//  PLVPPTLiveMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVPPTLiveMediaViewController.h"
#import "PLVBaseMediaViewController+PPT.h"
#import "PLVBaseMediaViewController+Live.h"

@interface PLVPPTLiveMediaViewController () <PLVLivePlayerControllerDelegate, PLVPlayerControllerDelegate>

@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器

@end

@implementation PLVPPTLiveMediaViewController

@synthesize playAD;
@synthesize channelId;
@synthesize userId;
@synthesize linkMicVC;
@synthesize danmuLayer;
@synthesize danmuInputView;
@synthesize reOpening;
@synthesize player;
@synthesize pptVC;
@synthesize secondaryView;
@synthesize originSecondaryFrame;
@synthesize pptOnSecondaryView;
@synthesize pptFlag;
@synthesize countdownTimeView;
@synthesize countdownTimeLabel;
@synthesize countdownTimer;
@synthesize startTime;
@synthesize curStreamState;
@synthesize chaseFrame;

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadSkinView:PLVPlayerSkinViewTypeCloudClassLive];
}

#pragma mark - public
- (void)refreshPPT:(NSString *)json {
    if ([json containsString:@"\"isCamClosed\":1"]) {//推流端关闭了摄像头
        if (self.pptOnSecondaryView && !self.player.playingAD && !((PLVLivePlayerController *)self.player).linkMic) {//自动切换主屏为PPT，副屏为视频
            self.pptFlag = YES;
            [self switchAction:NO];
        }
        
        if (((PLVLivePlayerController *)self.player).playing) {
            //若正在直播中，收到则关闭；若不在直播中，则等待上课时的最新摄像头字段
            ((PLVLivePlayerController *)self.player).cameraClosed = YES;
        }
        if (!self.pptOnSecondaryView && !self.secondaryView.hidden) {//而iOS端，副屏为视频且已经打开，则自动关闭副屏
            [self closeSecondaryView:self.skinView];
        }
    } else if ([json containsString:@"\"isCamClosed\":0"]) {//推流端打开了摄像头
        ((PLVLivePlayerController *)self.player).cameraClosed = NO;
        if (!self.player.playingAD && ((PLVLivePlayerController *)self.player).playing && !self.pptOnSecondaryView && self.secondaryView.hidden) {//而iOS端，正在播放直播（非广告），副屏为视频且已经关闭，则自动打开副屏
            [self openSecondaryView];
        }
    }
    
    if (((PLVLivePlayerController *)self.player).linkMic) {
        [self.pptVC refreshPPT:json];
    } else {
        [self.pptVC refreshPPT:json delay:5000];
    }
}

- (void)loadPPTEnd {
    self.linkMicVC.PPTVC = self.pptVC;
}

- (void)linkMicSwitchViewAction:(BOOL)manualControl {
    [self switchAction:manualControl];
}

- (void)resetLinkMicTopControlFrame:(BOOL)close {
    [self.linkMicVC resetLinkMicTopControlFrame:close];
}

#pragma mark - PLVBaseMediaViewController
- (void)deviceOrientationBeignAnimation {
    [self dealDeviceOrientationBeignAnimation];
}

- (void)deviceOrientationEndAnimation {
     [self dealDeviceOrientationEndAnimation];
}

- (void)deviceOrientationDidChangeSubAnimation {
    [self dealDeviceOrientationDidChangeSubAnimation];
    
    if (self.skinView.fullscreen) {
        self.danmuInputView.frame = self.view.bounds;
    }
    self.linkMicVC.view.hidden = self.skinView.fullscreen && self.linkMicVC.linkMicViewArray.count == 0;
    self.countdownTimeView.hidden = self.skinView.fullscreen;
}

- (CGRect)getMainRect {
    CGRect mainRect = [super getMainRect];
    if (self.skinView.fullscreen && self.linkMicVC.linkMicViewArray.count > 0) {
        mainRect.origin.x = self.linkMicVC.view.frame.origin.x + self.linkMicVC.view.frame.size.width;
        mainRect.size.width = self.linkMicVC.controlView.frame.origin.x - mainRect.origin.x;
    }
    return mainRect;
}

- (void)loadPlayer {
    if (self.playAD) {
        [self closeSecondaryView:self.skinView];
    }
    self.player = [[PLVLivePlayerController alloc] initWithChannelId:self.channelId userId:self.userId playAD:self.playAD displayView:self.secondaryView delegate:self];
    [(PLVLivePlayerController *)self.player setChaseFrame:self.chaseFrame];
}

- (void)switchAction:(BOOL)manualControl {
    if (self.linkMicVC.linkMicViewArray.count > 0) {
        PLVLinkMicView *linkMicView = [self.linkMicVC.linkMicViewArray objectAtIndex:0];
        self.pptOnSecondaryView = !self.pptOnSecondaryView;
        if (!self.pptOnSecondaryView) {
            UIView *videoView = self.mainView.subviews[0];
            linkMicView.onBigView = NO;
            linkMicView.backgroundColor = linkMicView.videoView.hidden ? LinkMicViewBackgroundColor : [UIColor whiteColor];
            [linkMicView insertSubview:videoView belowSubview:linkMicView.permissionImgView];
            [videoView setFrame:linkMicView.bounds];
            self.mainView.backgroundColor = [UIColor blackColor];
            [self.mainView insertSubview:self.pptVC.view atIndex:0];
            self.pptVC.view.frame = self.mainView.bounds;
        } else {
            if (manualControl) {
                self.pptFlag = manualControl;
            }
            linkMicView.onBigView = YES;
            UIView *videoView = linkMicView.mainView;
            self.mainView.backgroundColor = linkMicView.videoView.hidden ? LinkMicViewBackgroundColor : [UIColor blackColor];
            [self.mainView insertSubview:videoView atIndex:0];
            [videoView setFrame:self.mainView.bounds];
            linkMicView.backgroundColor = [UIColor whiteColor];
            [linkMicView insertSubview:self.pptVC.view belowSubview:linkMicView.permissionImgView];
            self.pptVC.view.frame = linkMicView.bounds;
        }
    } else {
        [super dealSwitchAction:manualControl];
    }
}

- (void)clearResource {
    [super clearResource];
}

- (void)changeVideoAndPPTPosition:(BOOL)status {
    if (status != self.pptOnSecondaryView) {
        [super dealSwitchAction:NO];
    }
}

#pragma mark - PLVLiveMediaProtocol
- (void)linkMicSuccess {
    self.secondaryView.alpha = 0.0;
    if (self.secondaryView.hidden) {
        [self openSecondaryView];
    }
    if (self.pptOnSecondaryView) {
        [super dealSwitchAction:NO];
    }
    ((PLVLivePlayerController*)self.player).linkMic = YES;
    [self.player clearAllPlayer];
    
    [self.moreView showAudioModeBtn:NO];
    [self.skinView linkMicStart:YES];
    
    [self resetMarquee];
}

- (void)cancelLinkMic {
    if (self.pptOnSecondaryView) {
        UIView *videoView = self.mainView.subviews[0];
        [videoView removeFromSuperview];
        [super dealSwitchAction:NO];
    }
    self.secondaryView.alpha = 1.0;
    
    if (!self.viewer) { ((PLVLivePlayerController*)self.player).linkMic = NO; }
    [self reOpenPlayerWithLineIndex:-1 codeRate:nil showHud:NO];
    
    BOOL showAudioModeSwitch = ((PLVLivePlayerController*)self.player).supportAudioMode && self.player.playable;
    [self.moreView showAudioModeBtn:showAudioModeSwitch];
    [self.skinView linkMicStart:NO];
}

- (void)hiddenLinkMic {
    if (self.linkMicVC.linkMicViewArray.count == 0 || self.linkMicVC.viewer) {
        [self.linkMicVC hiddenLinkMic:YES];
    }
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController subPlaybackIsPreparedToPlay:(NSNotification *)notification {
    [self hiddenLinkMic];
    [self subPlaybackIsPreparedToPlay:notification];
}

- (void)playerController:(PLVPlayerController *)playerController mainPlaybackIsPreparedToPlay:(NSNotification *)notification {
    [self.linkMicVC hiddenLinkMic:NO];
    [self clearCountdownTimer];
    [self mainPlaybackIsPreparedToPlay:notification];
}

- (void)playerController:(PLVPlayerController *)playerController mainPlayerSeiDidChange:(long)timeStamp {
    long newTimeStamp = timeStamp - playerController.videoCacheDuration;
    if (newTimeStamp > 0) {
        NSString *json = [NSString stringWithFormat:@"{\"time\":\"%ld\"}",newTimeStamp];
        [self.pptVC setSeiData:json];
    }
}

#pragma mark - PLVLivePlayerControllerDelegate
- (void)livePlayerController:(PLVLivePlayerController *)livePlayer streamState:(PLVLiveStreamState)streamState {
    self.pptVC.pptPlayable = streamState > PLVLiveStreamStateNoStream;
    if (streamState == PLVLiveStreamStateNoStream) {//没直播流
        [self hiddenLinkMic];
        self.skinView.controllView.hidden = YES;
        self.pptFlag = NO;
        if (!self.secondaryView.hidden) {//副屏已经打开，则自动关闭副屏
            [self closeSecondaryView:self.skinView];
        }
        self.linkMicVC.sessionId = @"";
    } else if (self.linkMicVC.sessionId.length == 0) {
        self.linkMicVC.sessionId = [self currentChannelSessionId];
    }
    
    if (self.curStreamState != streamState) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(streamStateDidChange:streamState:)]) {
            [self.delegate streamStateDidChange:self streamState:streamState];
        }
        if (streamState == PLVLiveStreamStateLive && self.viewer) { [self.linkMicVC hiddenLinkMic:NO]; }
    }

    self.curStreamState = streamState;
}

- (void)reconnectPlayer:(PLVLivePlayerController *)livePlayer {
    [self reOpenPlayerWithLineIndex:-1 codeRate:nil showHud:NO];
}

- (void)liveVideoChannelDidUpdate:(PLVLiveVideoChannel *)channel {
    self.enableDanmuModule = !channel.closeDanmuEnable;
    [self setupMarquee:channel customNick:self.nickName];
}

@end
