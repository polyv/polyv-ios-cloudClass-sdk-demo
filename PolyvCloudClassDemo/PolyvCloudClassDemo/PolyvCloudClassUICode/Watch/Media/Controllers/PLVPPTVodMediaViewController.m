//
//  PLVPPTVodMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVPPTVodMediaViewController.h"
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>
#import "PLVBaseMediaViewController+Vod.h"
#import "PLVBaseMediaViewController+PPT.h"

@interface PLVPPTVodMediaViewController () <PLVPlayerControllerDelegate, PLVPlayerSkinViewDelegate, PLVPPTViewControllerDelegate, PLVPlayerSkinMoreViewDelegate>

@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器

@end

@implementation PLVPPTVodMediaViewController

@synthesize player;
@synthesize vodId;
@synthesize channelId;
@synthesize userId;
@synthesize pptVC;
@synthesize secondaryView;
@synthesize originSecondaryFrame;
@synthesize pptOnSecondaryView;
@synthesize vodList;

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadSkinView:PLVPlayerSkinViewTypeCloudClassVod];
    self.skinView.controllView.hidden = YES;
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    if (liveConfig.channelId && liveConfig.userId) {
        __weak typeof(self)weakSelf = self;
        [PLVLivePlayerController loadLiveVideoChannelWithUserId:liveConfig.userId channelId:liveConfig.channelId.integerValue completion:^(PLVLiveVideoChannel *channel) {
            [weakSelf setupMarquee:channel customNick:self.nickName];
            [weakSelf setupPlayerLogoImage:channel];
        } failure:^(NSError *error) {
            NSLog(@"直播频道信息加载失败：%@",error);
        }];
    }
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
}

- (void)loadPlayer {
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    self.player = [[PLVVodPlayerController alloc] initWithChannelId:liveConfig.channelId vodId:self.vodId vodList:NO displayView:self.secondaryView delegate:self];
    [self.pptVC videoStart:self.vodId];
    self.pptVC.pptPlayable = YES;
}

- (void)switchAction:(BOOL)manualControl {
    [self dealSwitchAction:manualControl];
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController subPlaybackIsPreparedToPlay:(NSNotification *)notification {
    [self subPlaybackIsPreparedToPlay:notification];
}

- (void)playerController:(PLVPlayerController *)playerController mainPlaybackIsPreparedToPlay:(NSNotification *)notification {
    [self mainPlaybackIsPreparedToPlay:notification];
    if (self.networkErrorStatus) {
        [(PLVVodPlayerController *)self.player seek:self.timeOfInterruption];
    }
    self.networkErrorStatus = NO;
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)play:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player play];
    [self.pptVC pptPlay:[self.skinView getCurrentTime] * 1000.0];
}

- (void)pause:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player pause];
    [self.pptVC pptPause:[self.skinView getCurrentTime] * 1000.0];
}

#pragma mark - PLVPlayerSkinMoreViewDelegate
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView codeRate:(NSString *)codeRate{
    [(PLVVodPlayerController *)self.player switchCodeRate:codeRate];
}

#pragma mark - PLVPPTViewControllerDelegate
- (void)pptPrepare:(PLVPPTViewController *)pptVC {
    
}

- (NSTimeInterval)getCurrentTime:(PLVPPTViewController *)pptVC {
    return [self.skinView getCurrentTime] * 1000.0;
}

- (void)changeVideoAndPPTPosition:(BOOL)status {
    if (status != self.pptOnSecondaryView) {
        [super dealSwitchAction:NO];
    }
}

@end
