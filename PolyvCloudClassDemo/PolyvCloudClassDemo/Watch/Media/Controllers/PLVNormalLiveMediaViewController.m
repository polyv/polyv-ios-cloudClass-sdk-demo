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
@synthesize reOpening;
@synthesize player;

#pragma mark - life cycle

- (void)dealloc {
    NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadSkinView:PLVPlayerSkinViewTypeNormalLive];
    
    self.player = [[PLVLivePlayerController alloc] initWithChannelId:self.channelId userId:self.userId playAD:self.playAD displayView:self.mainView delegate:self];
    ((PLVLivePlayerController *)self.player).cameraClosed = NO;
}

#pragma mark - PLVBaseMediaViewController
- (void)deviceOrientationDidChangeSubAnimation:(CGAffineTransform)rotationTransform {
    UIView *displayView = self.mainView;
    [self.player setFrame:displayView.bounds];
}

#pragma mark - PLVLiveMediaProtocol
- (void)linkMicSuccess {
    [((PLVLivePlayerController*)self.player) mute];
}

- (void)cancelLinkMic {
    self.skinView.switchCameraBtn.hidden = YES;
    [((PLVLivePlayerController*)self.player) cancelMute];
    [self reOpenPlayer:nil showHud:NO];
}

#pragma mark - PLVPlayerControllerDelegate
- (void)adPreparedToPlay:(PLVPlayerController *)playerController {
    self.skinView.controllView.hidden = YES;
}

- (void)playerController:(PLVPlayerController *)playerController showMessage:(NSString *)message {
    [self.skinView showMessage:message];
}

- (void)mainPreparedToPlay:(PLVPlayerController *)playerController {
    self.skinView.controllView.hidden = NO;
    [self skinShowAnimaion];
}

- (void)changePlayerScreenBackgroundColor:(PLVPlayerController *)playerController {
    self.mainView.backgroundColor = playerController.playable ? [UIColor blackColor] : BlueBackgroundColor;
}

- (BOOL)onSafeArea:(PLVPlayerController *)playerController {
    return !self.skinView.fullscreen;
}

#pragma mark - PLVLivePlayerControllerDelegate
- (void)livePlayerController:(PLVLivePlayerController *)livePlayer streamState:(PLVLiveStreamState)streamState {
    if (streamState == PLVLiveStreamStateNoStream) {//没直播流
        self.skinView.controllView.hidden = YES;
    }
}

- (void)reconnectPlayer:(PLVLivePlayerController *)livePlayer {
    [self reOpenPlayer:nil showHud:NO];
}

@end
