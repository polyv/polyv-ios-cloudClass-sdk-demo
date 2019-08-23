//
//  PLVLiveMediaProtocol.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <PolyvCloudClassSDK/PLVLiveVideoChannel.h>
#import <PolyvCloudClassSDK/PLVLinkMicController.h>
#import "ZJZDanMu.h"
#import "PLVPlayerInputView.h"

/// 直播播放器基类协议（功能：1.弹幕；2.连麦窗口的交互）
@protocol PLVLiveMediaProtocol <NSObject>

/// 在登录时，根据网络请求返回当前频道是否正在直播（直播中：云课堂主屏为PPT，副屏为视频流；未直播，主屏优先播放暖场广告）
@property (nonatomic, assign) BOOL playAD;
/// 必须，不能为空
@property (nonatomic, strong) NSString *channelId;
/// 必须，不能为空
@property (nonatomic, strong) NSString *userId;
/// 连麦的控件，由外层传递进来，和皮肤层做一些连麦相关联的操作
@property (nonatomic, strong) PLVLinkMicController *linkMicVC;
/// 弹幕控件
@property (nonatomic, strong) ZJZDanMu *danmuLayer;
/// 发送弹幕弹窗
@property (nonatomic, strong) PLVPlayerInputView *danmuInputView;
/// 正在加载channelJSON
@property (nonatomic, assign) BOOL reOpening;
/// 倒计时器的父View
@property (nonatomic, strong) UIView *countdownTimeView;
/// 倒计时器
@property (nonatomic, strong) UILabel *countdownTimeLabel;
/// 倒计时相关定时器
@property (nonatomic, strong) NSTimer *countdownTimer;
/// 倒计时间
@property (nonatomic, strong) NSDate *startTime;
/// 当前流状态
@property (nonatomic, assign) PLVLiveStreamState curStreamState;

@optional
/// 显示一条弹幕，该 message 由外层的键盘输入回调 或 Sockect IM 传递进来
- (void)danmu:(NSMutableAttributedString *)message;

/// 连麦成功，由外层连麦控件调用
- (void)linkMicSuccess;

/// 取消连麦，由外层连麦控件调用
- (void)cancelLinkMic;

/// 切换连麦人的位置，manualControl为YES时，是自己主动切换主副屏窗口，为NO时是推流端的讲师切换主副屏窗口
- (void)linkMicSwitchViewAction:(BOOL)manualControl;

/// 登录成功后，返回登录消息里的user信息，调用PLVPPTViewController里的setUser
- (void)setUserInfo:(NSDictionary *)userInfo;

/**
 获取当前直播的seesionId
 
 @return 返回值有可能为 nil，调用层需要做判断
 */
- (NSString *)currentChannelSessionId;

/// 有外层返回的startTime时间决定是否需要加载倒计时器，显示在播放器顶部
- (void)loadCountdownTimeLabel:(NSDate *)startTime;

/// 清空倒计时的定时器
- (void)clearCountdownTimer;

@end
