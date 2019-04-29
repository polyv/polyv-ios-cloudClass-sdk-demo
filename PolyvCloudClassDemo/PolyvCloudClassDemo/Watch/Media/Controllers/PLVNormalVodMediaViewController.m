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

@interface PLVNormalVodMediaViewController () <PLVPlayerSkinViewDelegate, PLVPlayerControllerDelegate>

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
    
    self.player = [[PLVVodPlayerController alloc] initWithVodId:self.vodId displayView:self.mainView delegate:self];
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    if (liveConfig.channelId && liveConfig.userId) {
        __weak typeof(self)weakSelf = self;
        [PLVLivePlayerController loadLiveVideoChannelWithUserId:liveConfig.userId channelId:liveConfig.channelId.integerValue completion:^(PLVLiveVideoChannel *channel) {
            [weakSelf setupMarquee:channel customNick:self.nickName];
        } failure:^(NSError *error) {
            NSLog(@"直播频道信息加载失败：%@",error);
        }];
    }
}

#pragma mark - PLVBaseMediaViewController
- (void)deviceOrientationDidChangeSubAnimation:(CGAffineTransform)rotationTransform {
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

- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate {
    [(PLVVodPlayerController *)self.player switchCodeRate:codeRate];
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

@end
