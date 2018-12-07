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

//直播播放器基类协议（功能：1.弹幕；2.连麦窗口的交互）
@protocol PLVLiveMediaProtocol <NSObject>

@property (nonatomic, assign) BOOL playAD;//在登录时，根据网络请求返回当前频道是否正在直播（直播中：云课堂主屏为PPT，副屏为视频流；未直播，主屏优先播放暖场广告）
@property (nonatomic, strong) NSString *channelId;//必须，不能为空
@property (nonatomic, strong) NSString *userId;//必须，不能为空
@property (nonatomic, strong) PLVLinkMicController *linkMicVC;//连麦的控件，由外层传递进来，和皮肤层做一些连麦相关联的操作
@property (nonatomic, strong) ZJZDanMu *danmuLayer;//弹幕控件
@property (nonatomic, assign) BOOL reOpening;//正在加载channelJSON

@optional
//显示一条弹幕，该 message 由外层的键盘输入回调 或 Sockect IM 传递进来
- (void)danmu:(NSMutableAttributedString *)message;

//连麦成功，由外层连麦控件调用
- (void)linkMicSuccess;

//取消连麦，由外层连麦控件调用
- (void)cancelLinkMic;

//当前LiveVideoChannel对象
- (PLVLiveVideoChannel *)currentChannel;

@end
