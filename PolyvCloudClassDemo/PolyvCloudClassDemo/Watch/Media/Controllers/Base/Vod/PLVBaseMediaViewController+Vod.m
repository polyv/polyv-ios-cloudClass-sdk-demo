//
//  PLVBaseMediaViewController+Vod.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/22.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController+Vod.h"

@interface PLVBaseMediaViewController () <PLVPlayerSkinViewDelegate>

@end

@implementation PLVBaseMediaViewController (Vod)

#pragma mark - PLVPlayerSkinViewDelegate
- (void)playerSkinView:(PLVPlayerSkinView *)skinView speed:(CGFloat)speed {
    [(PLVVodPlayerController *)self.player speedRate:speed];
}

- (void)seek:(PLVPlayerSkinView *)skinView {
    NSTimeInterval curTime = [self.skinView getCurrentTime];
    [(PLVVodPlayerController *)self.player seek:curTime];
}

#pragma mark - PLVVodPlayerControllerDelegate
- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer duration:(NSTimeInterval)duration playing:(BOOL)playing {
    self.skinView.duration = duration;
    [self.skinView modifyMainBtnState:playing];
}

- (void)vodPlayerController:(PLVVodPlayerController *)vodPlayer dowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration {
    [self.skinView updateDowloadProgress:dowloadProgress playedProgress:playedProgress currentPlaybackTime:currentPlaybackTime duration:duration];
}

@end
