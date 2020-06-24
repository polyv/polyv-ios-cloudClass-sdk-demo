//
//  PLVPlayerSkinAudioModeView.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/6/11.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PolyvCloudClassSDK/PLVLivePlayerController.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVPlayerSkinAudioModeViewDelegate;

/// 音频模式示意视图
@interface PLVPlayerSkinAudioModeView : UIView <PLVPlayerAudioModeViewProtocol>

/// delegate
@property (nonatomic, weak) id<PLVPlayerSkinAudioModeViewDelegate> delegate;

@end

@protocol PLVPlayerSkinAudioModeViewDelegate <NSObject>

@optional

/// 点击播放画面
- (void)playVideoAudioModeView:(PLVPlayerSkinAudioModeView *)audioModeView;

@end

NS_ASSUME_NONNULL_END
