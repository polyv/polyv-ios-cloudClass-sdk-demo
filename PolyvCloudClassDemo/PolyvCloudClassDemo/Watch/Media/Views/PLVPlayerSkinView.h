//
//  PLVPlayerSkinView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 皮肤类型
typedef NS_ENUM(NSInteger, PLVPlayerSkinViewType) {
    /// 普通直播
    PLVPlayerSkinViewTypeNormalLive       = 1,
    /// 云课堂直播
    PLVPlayerSkinViewTypeCloudClassLive   = 2,
    /// 普通直播回放
    PLVPlayerSkinViewTypeNormalVod        = 3,
    /// 云课堂直播回放
    PLVPlayerSkinViewTypeCloudClassVod    = 4
};

@protocol PLVPlayerSkinViewDelegate;

/// 播放器皮肤
@interface PLVPlayerSkinView : UIView

/// delegate
@property (nonatomic, weak) id<PLVPlayerSkinViewDelegate> delegate;
/// 皮肤类型
@property (nonatomic, assign) PLVPlayerSkinViewType type;
/// 码率列表
@property (nonatomic, strong) NSMutableArray<NSString *> *codeRateItems;
/// 是否全屏
@property (nonatomic, assign) BOOL fullscreen;
/// 回放视频时长
@property (nonatomic, assign) NSTimeInterval duration;
/// 控制控件的父View
@property (nonatomic, strong, readonly) UIView *controllView;
/// 连麦按钮
@property (nonatomic, strong, readonly) UIButton *linkMicBtn;
/// 只有自己的连麦窗口切换到主屏, 才显示切换前后置摄像头的按钮
@property (nonatomic, strong) UIButton *switchCameraBtn;

#pragma mark - 共有方法
/// 加在子View
- (void)loadSubviews;

/// 布局（横竖屏切换动画中调用）
- (void)layout;

/// 更新切换主副窗口的按钮状态
- (void)modifySwitchScreenBtnState:(BOOL)secondaryViewClosed pptOnSecondaryView:(BOOL)pptOnSecondaryView;

/// 切换码率
- (void)switchCodeRate:(NSString *)codeRate;

/// 更新连麦按钮状态
- (void)linkMicStatus:(BOOL)select;

/// 显示播放器的回调信息
- (void)showMessage:(NSString *)message;

#pragma mark - 点播独有方法
/// 更新点播的进度条
- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration;

/// 更新播放暂停按钮的状态
- (void)modifyMainBtnState:(BOOL)playing;

/// 获取当前播放进度
- (NSTimeInterval)getCurrentTime;

@end

@protocol PLVPlayerSkinViewDelegate <NSObject>

@optional

#pragma mark -  播放控制
/// 播放
- (void)play:(PLVPlayerSkinView *)skinView;

/// 暂停
- (void)pause:(PLVPlayerSkinView *)skinView;

/// seek
- (void)seek:(PLVPlayerSkinView *)skinView;

/// 刷新
- (void)refresh:(PLVPlayerSkinView *)skinView;

///退出
- (void)quit:(PLVPlayerSkinView *)skinView;

/// 速率
- (void)playerSkinView:(PLVPlayerSkinView *)skinView speed:(CGFloat)speed;

/// 码率
- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate;

/// 连麦
- (void)linkMic:(PLVPlayerSkinView *)skinView;

/// 切换前后置摄像头
- (void)switchCamera:(PLVPlayerSkinView *)skinView;

/// 弹幕
- (void)playerSkinView:(PLVPlayerSkinView *)skinView switchDanmu:(BOOL)switchDanmu;

/// 主副屏幕切换
- (void)switchScreenOnManualControl:(PLVPlayerSkinView *)skinView;

@end
