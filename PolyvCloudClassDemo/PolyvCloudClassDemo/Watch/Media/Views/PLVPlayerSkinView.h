//
//  PLVPlayerSkinView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PLVPlayerSkinViewType) {
    PLVPlayerSkinViewTypeNormalLive       = 1,//普通直播
    PLVPlayerSkinViewTypeCloudClassLive   = 2,//云课堂直播
    PLVPlayerSkinViewTypeNormalVod        = 3,//普通直播回放
    PLVPlayerSkinViewTypeCloudClassVod    = 4 //云课堂直播回放
};

@protocol PLVPlayerSkinViewDelegate;

//播放器皮肤
@interface PLVPlayerSkinView : UIView

@property (nonatomic, weak) id<PLVPlayerSkinViewDelegate> delegate;
@property (nonatomic, assign) PLVPlayerSkinViewType type;
@property (nonatomic, strong) NSMutableArray<NSString *> *codeRateItems;
@property (nonatomic, assign) BOOL fullscreen;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong, readonly) UIView *controllView;
@property (nonatomic, strong, readonly) UIButton *linkMicBtn;
@property (nonatomic, strong) UIButton *switchCameraBtn;//只有自己的连麦窗口切换到主屏, 才显示切换前后置摄像头的按钮

#pragma mark - 共有方法
- (void)loadSubviews;
- (void)layout;
- (void)modifySwitchScreenBtnState:(BOOL)secondaryViewClosed pptOnSecondaryView:(BOOL)pptOnSecondaryView;
- (void)switchCodeRate:(NSString *)codeRate;
- (void)showMessage:(NSString *)message;

#pragma mark - 点播独有方法
- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration;
- (void)modifyMainBtnState:(BOOL)playing;
- (NSTimeInterval)getCurrentTime;
- (void)linkMicStatus:(BOOL)select;

@end

@protocol PLVPlayerSkinViewDelegate <NSObject>

@optional

#pragma mark -  播放控制
- (void)play:(PLVPlayerSkinView *)skinView;
- (void)pause:(PLVPlayerSkinView *)skinView;
- (void)seek:(PLVPlayerSkinView *)skinView;
- (void)refresh:(PLVPlayerSkinView *)skinView;
- (void)quit:(PLVPlayerSkinView *)skinView;

#pragma mark -  速率
- (void)playerSkinView:(PLVPlayerSkinView *)skinView speed:(CGFloat)speed;

#pragma mark -  码率
- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate;

#pragma mark -  连麦
- (void)linkMic:(PLVPlayerSkinView *)skinView;
- (void)switchCamera:(PLVPlayerSkinView *)skinView;

#pragma mark -  弹幕
- (void)playerSkinView:(PLVPlayerSkinView *)skinView switchDanmu:(BOOL)switchDanmu;

#pragma mark -  主副屏幕切换
- (void)switchScreenOnManualControl:(PLVPlayerSkinView *)skinView;

@end
