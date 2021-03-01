//
//  PLVBaseMediaViewController+Vod.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/22.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController+Vod.h"
#import <Masonry/Masonry.h>
#import "PLVReachabilityManager.h"

@interface PLVBaseMediaViewController () <PLVPlayerSkinViewDelegate, PLVPlayerSkinMoreViewDelegate>

@end

@implementation PLVBaseMediaViewController (Vod)

#pragma mark - PLVPlayerSkinViewDelegate
- (void)seek:(PLVPlayerSkinView *)skinView {
    NSTimeInterval curTime = [self.skinView getCurrentTime];
    [(PLVVodPlayerController *)self.player seek:curTime];
}

#pragma mark - PLVPlayerSkinMoreViewDelegate
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView speed:(CGFloat)speed{
    [(PLVVodPlayerController *)self.player speedRate:speed];
}

#pragma mark - PLVVodPlayerControllerDelegate
- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer duration:(NSTimeInterval)duration playing:(BOOL)playing {
    self.skinView.duration = duration;
    [self.skinView modifyMainBtnState:playing];
}

- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer dowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration {
    [self.skinView updateDowloadProgress:dowloadProgress playedProgress:playedProgress currentPlaybackTime:currentPlaybackTime duration:duration];
}

- (void)mainPlayerPlaybackErrorWithTimeOfInterruption:(NSTimeInterval)timeOfInterruption {
    if (!self.networkErrorView) {
        self.networkErrorView = [[UIView alloc]init];
        self.networkErrorView.backgroundColor = [UIColor blackColor];
        self.networkErrorView.alpha = 0.5;
        [self.view insertSubview:self.networkErrorView belowSubview:self.skinView.backBtn];
        [self.networkErrorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(0);
        }];
    
        [self.networkErrorView addSubview:self.replayButton];
        [self.replayButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_offset(0);
            make.size.mas_equalTo(CGSizeMake(80, 30));
        }];
        [self.replayButton addTarget:self action:@selector(replayButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.networkErrorView.hidden = NO;
    }
    
    [self removeTapGestureRecognizer];
    [self backBtnShowNow];
    self.networkErrorStatus = YES;
    self.timeOfInterruption = timeOfInterruption;
}



#pragma mark - Action
- (void)replayButtonAction:(UIButton *)button {
    if ([PLVReachabilityManager currentReachabilityStatus] != PLVNotReachable) {
        self.networkErrorView.hidden = YES;
        [self addTapGestureRecognizer];
        [(PLVVodPlayerController *)self.player switchCodeRate:nil];
    }
}

@end
