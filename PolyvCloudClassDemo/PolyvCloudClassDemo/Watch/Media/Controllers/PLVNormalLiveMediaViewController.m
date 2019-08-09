//
//  PLVNormalLiveMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVNormalLiveMediaViewController.h"
#import "PLVBaseMediaViewController+Live.h"

@interface PLVNormalLiveMediaViewController () <PLVLivePlayerControllerDelegate, PLVPlayerControllerDelegate>

@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器

@end

@implementation PLVNormalLiveMediaViewController

@synthesize playAD;
@synthesize channelId;
@synthesize userId;
@synthesize linkMicVC;
@synthesize danmuLayer;
@synthesize danmuInputView;
@synthesize reOpening;
@synthesize player;
@synthesize countdownTimeView;
@synthesize countdownTimeLabel;
@synthesize countdownTimer;
@synthesize startTime;
@synthesize curStreamState;

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadSkinView:PLVPlayerSkinViewTypeNormalLive];
    
    self.player = [[PLVLivePlayerController alloc] initWithChannelId:self.channelId userId:self.userId playAD:self.playAD displayView:self.mainView delegate:self];
    ((PLVLivePlayerController *)self.player).cameraClosed = NO;
}

#pragma mark - PLVBaseMediaViewController
- (void)deviceOrientationDidChangeSubAnimation {
    UIView *displayView = self.mainView;
    [self.player setFrame:displayView.bounds];

    if (self.skinView.fullscreen) {
        self.danmuInputView.frame = self.view.bounds;
    }
    if (self.linkMicVC.linkMicType == PLVLinkMicTypeLive) {
        self.linkMicVC.view.alpha = self.skinView.fullscreen ? 0 : 1;
    }
    self.countdownTimeView.hidden = self.skinView.fullscreen;
}

- (CGFloat)getLinkMicHeight {
    if (self.linkMicVC.linkMicType != PLVLinkMicTypeLive && self.linkMicVC.linkMicViewArray.count > 0) {
        return self.linkMicVC.originSize.height;
    }
    return 0.0;
}

#pragma mark - PLVLiveMediaProtocol
- (void)linkMicSuccess {
    if (self.linkMicVC.linkMicType == PLVLinkMicTypeLive) {
        [((PLVLivePlayerController*)self.player) mute];
        
        [self.moreView showAudioModeBtn:NO];
        [self.skinView linkMicStart:YES];
    } else {
        PLVLinkMicView *linkMicView = [self.linkMicVC.linkMicViewArray objectAtIndex:0];
        if (linkMicView.switchCameraBtn) {
            self.skinView.switchCameraBtn.hidden = NO;
        }
        linkMicView.onBigView = YES;
        self.mainView.backgroundColor = linkMicView.videoView.hidden ? BlueBackgroundColor : [UIColor blackColor];
        [self.mainView addSubview:linkMicView.mainView];
        CGRect linkMicRect = self.mainView.bounds;
        linkMicRect.size.height += 5.0;
        linkMicView.mainView.frame = linkMicRect;
        
        ((PLVLivePlayerController*)self.player).linkMic = YES;
        [self.player clearAllPlayer];
        
        [self.moreView showAudioModeBtn:NO];
        [self.skinView linkMicStart:YES];
    }
}

- (void)cancelLinkMic {
    if (self.linkMicVC.linkMicType == PLVLinkMicTypeLive) {
        self.skinView.switchCameraBtn.hidden = YES;
        [((PLVLivePlayerController*)self.player) cancelMute];
        [self reOpenPlayerWithLineIndex:-1 codeRate:nil showHud:NO];
        
        BOOL showAudioModeSwitch = ((PLVLivePlayerController*)self.player).supportAudioMode && self.player.playable;
        [self.moreView showAudioModeBtn:showAudioModeSwitch];
        [self.skinView linkMicStart:NO];
    } else {
        if (self.mainView.subviews.count > 1) {
            UIView *videoView = self.mainView.subviews[self.mainView.subviews.count - 1];
            [videoView removeFromSuperview];
        }
        self.skinView.switchCameraBtn.hidden = YES;

        ((PLVLivePlayerController*)self.player).linkMic = NO;
        [self reOpenPlayerWithLineIndex:-1 codeRate:nil showHud:NO];
        
        BOOL showAudioModeSwitch = ((PLVLivePlayerController*)self.player).supportAudioMode && self.player.playable;
        [self.moreView showAudioModeBtn:showAudioModeSwitch];
        [self.skinView linkMicStart:NO];
    }
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController subPlaybackIsPreparedToPlay:(NSNotification *)notification {
    self.skinView.controllView.hidden = YES;
}

- (void)playerController:(PLVPlayerController *)playerController mainPlaybackIsPreparedToPlay:(NSNotification *)notification {
    [self clearCountdownTimer];
    self.skinView.controllView.hidden = NO;
    [self skinShowAnimaion];
    [self.moreView modifyModeBtnSelected:((PLVLivePlayerController*)self.player).audioMode];
}

- (void)changePlayerScreenBackgroundColor:(PLVPlayerController *)playerController {
    self.mainView.backgroundColor = playerController.backgroundImgView.hidden ? [UIColor blackColor] : GrayBackgroundColor;
    
    BOOL showAudioModeSwitch = ((PLVLivePlayerController*)self.player).supportAudioMode && self.player.playable;
    [self.moreView showAudioModeBtn:showAudioModeSwitch];
    [self.moreView modifyModeBtnSelected:((PLVLivePlayerController*)self.player).audioMode];
}

#pragma mark - PLVLivePlayerControllerDelegate
- (void)livePlayerController:(PLVLivePlayerController *)livePlayer streamState:(PLVLiveStreamState)streamState {
    if (streamState == PLVLiveStreamStateNoStream) {//没直播流
        self.skinView.controllView.hidden = YES;
    }
    
    if (self.curStreamState != streamState) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(streamStateDidChange:streamState:)]) {
            [self.delegate streamStateDidChange:self streamState:streamState];
        }
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
