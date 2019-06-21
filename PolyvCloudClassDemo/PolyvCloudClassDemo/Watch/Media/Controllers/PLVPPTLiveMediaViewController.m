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

@interface PLVPPTLiveMediaViewController () <PLVLivePlayerControllerDelegate>

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
        
        ((PLVLivePlayerController *)self.player).cameraClosed = YES;
        if (!self.pptOnSecondaryView && !self.secondaryView.hidden) {//而iOS端，副屏为视频且已经打开，则自动关闭副屏
            [self closeSecondaryView:self.secondaryView];
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
        NSTimeInterval delay = 5000.0;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [weakSelf.pptVC refreshPPT:json];
        });
    }
}

- (void)secondaryViewFollowKeyboardAnimation:(BOOL)flag {
    if (flag) {
        CGFloat safeAreaY = 20.0;
        if (@available(iOS 11.0, *)) {
            safeAreaY = self.view.superview.safeAreaLayoutGuide.layoutFrame.origin.y;
        }
        CGRect secondaryRect = self.secondaryView.frame;
        secondaryRect = CGRectMake(self.view.frame.size.width - secondaryRect.size.width, safeAreaY, secondaryRect.size.width, secondaryRect.size.height);
        self.secondaryView.frame = secondaryRect;
    } else {
        self.secondaryView.frame = self.originSecondaryFrame;
    }
}

- (void)linkMicSwitchViewAction {
    [self switchAction:NO];
}

#pragma mark - PLVBaseMediaViewController
- (void)deviceOrientationDidChangeSubAnimation {
    [self dealDeviceOrientationDidChangeSubAnimation];
    
    if (self.skinView.fullscreen) {
        [self.view insertSubview:self.linkMicVC.view belowSubview:self.skinView];
        CGRect rect = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, self.linkMicVC.view.frame.size.height);
        if (@available(iOS 11.0, *)) {
            CGRect safeFrame = [UIApplication sharedApplication].delegate.window.safeAreaLayoutGuide.layoutFrame;
            rect.origin.x = safeFrame.origin.x;
            rect.size.width -= rect.origin.x * 2.0;
        }
        self.linkMicVC.view.frame = rect;
        self.danmuInputView.frame = self.view.bounds;
    } else {
        self.linkMicVC.view.frame = CGRectMake(0.0, self.linkMicVC.originSecondaryFrame.origin.y, self.view.bounds.size.width, self.linkMicVC.originSecondaryFrame.size.height);
        [self.view.superview insertSubview:self.linkMicVC.view aboveSubview:self.view];
    }
}

- (void)loadPlayer {
    if (self.playAD) {
        [self closeSecondaryView:self.secondaryView];
    }
    self.player = [[PLVLivePlayerController alloc] initWithChannelId:self.channelId userId:self.userId playAD:self.playAD displayView:self.secondaryView delegate:self];
}

- (void)switchAction:(BOOL)manualControl {
    if (self.linkMicVC.linkMicViewArray.count > 0) {
        PLVLinkMicView *linkMicView = [self.linkMicVC.linkMicViewArray objectAtIndex:0];
        self.pptOnSecondaryView = !self.pptOnSecondaryView;
        if (!self.pptOnSecondaryView) {
            self.skinView.switchCameraBtn.hidden = YES;
            UIView *videoView = self.mainView.subviews[0];
            linkMicView.onBigView = NO;
            linkMicView.backgroundColor = [UIColor whiteColor];
            [linkMicView insertSubview:videoView belowSubview:linkMicView.nickNameLabel];
            [videoView setFrame:linkMicView.bounds];
            self.mainView.backgroundColor = [UIColor blackColor];
            [self.mainView addSubview:self.pptVC.view];
            self.pptVC.view.frame = self.mainView.bounds;
        } else {
            if (manualControl) {
                self.pptFlag = manualControl;
            }
            if (linkMicView.switchCameraBtn) {
                self.skinView.switchCameraBtn.hidden = NO;
            }
            linkMicView.onBigView = YES;
            UIView *videoView = linkMicView.mainView;
            self.mainView.backgroundColor = linkMicView.videoView.hidden ? BlueBackgroundColor : [UIColor blackColor];
            [self.mainView addSubview:videoView];
            [videoView setFrame:self.mainView.bounds];
            linkMicView.backgroundColor = [UIColor whiteColor];
            [linkMicView insertSubview:self.pptVC.view belowSubview:linkMicView.nickNameLabel];
            self.pptVC.view.frame = linkMicView.bounds;
        }
    } else {
        [super dealSwitchAction:manualControl];
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
}

- (void)cancelLinkMic {
    if (self.pptOnSecondaryView) {
        UIView *videoView = self.mainView.subviews[0];
        [videoView removeFromSuperview];
        [super dealSwitchAction:NO];
    }
    self.skinView.switchCameraBtn.hidden = YES;
    self.secondaryView.alpha = 1.0;
    ((PLVLivePlayerController*)self.player).linkMic = NO;
    [self reOpenPlayer:nil showHud:NO];
    
    BOOL showAudioModeSwitch = ((PLVLivePlayerController*)self.player).supportAudioMode && self.player.playable;
    [self.moreView showAudioModeBtn:showAudioModeSwitch];
    [self.skinView linkMicStart:NO];
}

#pragma mark - PLVLivePlayerControllerDelegate
- (void)livePlayerController:(PLVLivePlayerController *)livePlayer streamState:(PLVLiveStreamState)streamState {
    if (streamState == PLVLiveStreamStateNoStream) {//没直播流
        self.skinView.controllView.hidden = YES;
        self.pptFlag = NO;
        self.pptVC.pptPlayable = NO;
        if (!self.secondaryView.hidden) {//副屏已经打开，则自动关闭副屏
            [self closeSecondaryView:self.secondaryView];
        }
    }
}

- (void)reconnectPlayer:(PLVLivePlayerController *)livePlayer {
    [self reOpenPlayer:nil showHud:NO];
}

- (void)liveVideoChannelDidUpdate:(PLVLiveVideoChannel *)channel {
    self.enableDanmuModule = !channel.closeDanmuEnable;
    [self setupMarquee:channel customNick:self.nickName];
}

@end
