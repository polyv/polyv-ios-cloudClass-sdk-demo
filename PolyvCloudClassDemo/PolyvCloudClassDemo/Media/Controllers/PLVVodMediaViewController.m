//
//  PLVVodMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVVodMediaViewController.h"
#import <PolyvCloudClassSDK/PLVVodPlayerController.h>
#import "PLVMediaViewControllerPrivateProtocol.h"
#import "PLVMediaViewControllerProtocol.h"

@interface PLVVodMediaViewController () <PLVMediaViewControllerPrivateProtocol, PLVMediaViewControllerProtocol, PLVVodPlayerControllerDelegate, PLVPlayerSkinViewDelegate, PLVPPTViewControllerDelegate>

@end

@implementation PLVVodMediaViewController

@synthesize player;
@synthesize pptVC;
@synthesize skinView;
@synthesize mainView;
@synthesize secondaryView;
@synthesize originSecondaryFrame;
@synthesize pptOnSecondaryView;
@synthesize pptFlag;

- (void)loadPlayer {
    [self openSecondaryView];
    self.player = [[PLVVodPlayerController alloc] initWithVodId:self.vodId displayView:self.secondaryView delegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.pptVC videoStart:self.vodId];
    
    [self loadSkinView:PLVPlayerSkinViewTypeVod];
    self.skinView.controllView.hidden = YES;
}

//======PLVPlayerSkinViewDelegate======
- (void)play:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player play];
    [self.pptVC pptPlay:[self.skinView getCurrentTime] * 1000.0];
}

- (void)pause:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player pause];
    [self.pptVC pptPause:[self.skinView getCurrentTime] * 1000.0];
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView speed:(CGFloat)speed {
    [(PLVVodPlayerController *)self.player speedRate:speed];
}

- (void)seek:(PLVPlayerSkinView *)skinView {
    NSTimeInterval curTime = [self.skinView getCurrentTime];
    [(PLVVodPlayerController *)self.player seek:curTime];
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate {
    [(PLVVodPlayerController *)self.player switchCodeRate:codeRate];
}

//============PLVVodPlayerControllerDelegate============
- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer duration:(NSTimeInterval)duration playing:(BOOL)playing {
    self.skinView.duration = duration;
    [self.skinView modifyMainBtnState:playing];
}

- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer dowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration {
    [self.skinView updateDowloadProgress:dowloadProgress playedProgress:playedProgress currentPlaybackTime:currentPlaybackTime duration:duration];
}

//============PLVPPTViewControllerDelegate============
- (void)pptPrepare:(PLVPPTViewController *)pptVC {
    
}

- (NSTimeInterval)getCurrentTime:(PLVPPTViewController *)pptVC {
    return [self.skinView getCurrentTime] * 1000.0;
}

@end
