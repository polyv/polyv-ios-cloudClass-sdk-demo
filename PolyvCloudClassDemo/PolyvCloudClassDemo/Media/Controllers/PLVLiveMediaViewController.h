//
//  PLVLiveMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVMediaViewController.h"
#import <PolyvCloudClassSDK/PLVLinkMicController.h>

@protocol PLVLiveMediaViewControllerDelegate;

@interface PLVLiveMediaViewController : PLVMediaViewController

@property (nonatomic, strong) NSString *channelId;//必须，不能为空
@property (nonatomic, strong) NSString *userId;//必须，不能为空
@property (nonatomic, weak) id<PLVLiveMediaViewControllerDelegate> liveDelegate;
@property (nonatomic, strong, readonly) PLVLinkMicController *linkMicVC;//连麦的控件

//显示一条弹幕，该message由外层的键盘输入回调传递进来
- (void)danmu:(NSMutableAttributedString *)message;

//加载答题卡题目信息，该json由外层的Socket接收传递进来
- (void)openQuestionContent:(NSString *)json;

//公布答题卡答案和作答信息，该json由外层的Socket接收传递进来
- (void)openQuestionResult:(NSString *)json;

//测试答题卡，该json由外层的Socket接收传递进来
- (void)testQuestion:(NSString *)json;

//刷新PPT内容，该json由外层的Socket接收传递进来
- (void)refreshPPT:(NSString *)json;

//副窗口和连麦窗口跟随聊天室的键盘移动，防止挡住聊天室内容
- (void)followKeyboardAnimation:(BOOL)flag;

@end

@protocol PLVLiveMediaViewControllerDelegate <NSObject>

//答题卡答案选择时回调
- (void)liveMediaViewController:(PLVLiveMediaViewController *)liveVC chooseAnswer:(NSDictionary *)dict;

//发送连麦的相关请求的回调
- (void)liveMediaViewController:(PLVLiveMediaViewController *)liveVC emitLinkMicObject:(PLVSocketLinkMicEventType)eventType;

//发送连麦的相关请求，并处理ACK回调
- (void)liveMediaViewController:(PLVLiveMediaViewController *)liveVC emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback;

@end
