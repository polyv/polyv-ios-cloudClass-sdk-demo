//
//  PLVNormalVodMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/12/5.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVNormalVodMediaViewController.h"
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>
#import "PLVBaseMediaViewController+Vod.h"

@interface PLVNormalVodMediaViewController () <PLVPlayerSkinViewDelegate, PLVPlayerControllerDelegate, PLVPlayerSkinMoreViewDelegate>

@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器

@end

@implementation PLVNormalVodMediaViewController

@synthesize player;
@synthesize vodId;
@synthesize channelId;
@synthesize userId;

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadSkinView:PLVPlayerSkinViewTypeNormalVod];
    self.skinView.controllView.hidden = YES;
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    if (liveConfig.channelId && liveConfig.userId) {
        __weak typeof(self)weakSelf = self;
        [PLVLivePlayerController loadLiveVideoChannelWithUserId:liveConfig.userId channelId:liveConfig.channelId.integerValue completion:^(PLVLiveVideoChannel *channel) {
            [weakSelf setupMarquee:channel customNick:self.nickName];
        } failure:^(NSError *error) {
            NSLog(@"直播频道信息加载失败：%@",error);
        }];
    }
    
    self.player = [[PLVVodPlayerController alloc] initWithVodId:self.vodId displayView:self.mainView delegate:self];
}

#pragma mark - PLVBaseMediaViewController
- (void)deviceOrientationDidChangeSubAnimation {
    UIView *displayView = self.mainView;
    [self.player setFrame:displayView.bounds];
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)play:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player play];
}

- (void)pause:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player pause];
}

#pragma mark - PLVPlayerSkinMoreViewDelegate
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView codeRate:(NSString *)codeRate{
    [(PLVVodPlayerController *)self.player switchCodeRate:codeRate];
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController subPlaybackIsPreparedToPlay:(NSNotification *)notification {
    self.skinView.controllView.hidden = YES;
}

- (void)playerController:(PLVPlayerController *)playerController mainPlaybackIsPreparedToPlay:(NSNotification *)notification {
    self.skinView.controllView.hidden = NO;
    [self skinShowAnimaion];
}

- (void)changePlayerScreenBackgroundColor:(PLVPlayerController *)playerController {
    self.mainView.backgroundColor = playerController.backgroundImgView.hidden ? [UIColor blackColor] : BlueBackgroundColor;
}

@end
