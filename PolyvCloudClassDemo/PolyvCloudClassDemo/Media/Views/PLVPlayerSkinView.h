//
//  PLVPlayerSkinView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PLVPlayerSkinViewType) {
    PLVPlayerSkinViewTypeLive   = 1,//直播
    PLVPlayerSkinViewTypeVod    = 2 //点播
};

@protocol PLVPlayerSkinViewDelegate;

@interface PLVPlayerSkinView : UIView

@property (nonatomic, weak) id<PLVPlayerSkinViewDelegate> delegate;
@property (nonatomic, assign) PLVPlayerSkinViewType type;
@property (nonatomic, strong) NSMutableArray<NSString *> *codeRateItems;
@property (nonatomic, assign) BOOL fullscreen;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong, readonly) UIView *controllView;
@property (nonatomic, strong, readonly) UIButton *linkMicBtn;

- (void)loadSubviews;
- (void)layout;
- (void)modifySwitchScreenBtnState:(BOOL)secondaryViewClosed pptOnSecondaryView:(BOOL)pptOnSecondaryView;
- (void)switchCodeRate:(NSString *)codeRate;
- (void)showMessage:(NSString *)message;

//点播特有
- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration;
- (void)modifyMainBtnState:(BOOL)playing;
- (NSTimeInterval)getCurrentTime;
- (void)linkMicStatus:(BOOL)select;

@end

@protocol PLVPlayerSkinViewDelegate <NSObject>

@optional
- (void)quit:(PLVPlayerSkinView *)skinView;
- (void)refreshLive:(PLVPlayerSkinView *)skinView;
- (void)linkMic:(PLVPlayerSkinView *)skinView;
- (void)play:(PLVPlayerSkinView *)skinView;
- (void)pause:(PLVPlayerSkinView *)skinView;
- (void)switchScreenOnManualControl:(PLVPlayerSkinView *)skinView;
- (void)playerSkinView:(PLVPlayerSkinView *)skinView switchDanmu:(BOOL)switchDanmu;
- (void)playerSkinView:(PLVPlayerSkinView *)skinView speed:(CGFloat)speed;
- (void)seek:(PLVPlayerSkinView *)skinView;
- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate;

@end
