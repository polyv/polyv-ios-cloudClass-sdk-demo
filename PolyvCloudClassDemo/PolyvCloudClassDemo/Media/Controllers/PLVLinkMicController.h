//
//  PLVLinkMicController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/10/17.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PolyvBusinessSDK/PLVSocketObject.h>
#import "PLVPlayerSkinView.h"
#import "PLVLinkMicView.h"

@protocol PLVLinkMicControllerDelegate;

@interface PLVLinkMicController : UIViewController

@property (nonatomic, weak) id<PLVLinkMicControllerDelegate> delegate;
@property (nonatomic, strong) PLVSocketObject *login;//登录对象，连麦时需要使用
@property (nonatomic, strong) NSDictionary *linkMicParams;//连麦token信息，连麦时需要使用
@property (nonatomic, strong) PLVPlayerSkinView *skinView;//播放器的皮肤
@property (nonatomic, assign) CGRect originSecondaryFrame;//页面初始化，记住竖屏时副屏的Frame，连麦窗口大小需要使用
@property (nonatomic, assign, readonly) BOOL linkMicOnAudio;//记住当前频道讲师开启的连麦类型（YES：声音；NO：视频）
@property (nonatomic, strong, readonly) NSMutableArray *linkMicViewArray;//连麦人的关联窗口集合(避免 linkMicViewDic 导致的先后顺序问题，方便顺序查找连麦人的窗口)

//准备退出时，必须清空连麦资源
- (void)clearResource;

//处理连麦的Socket消息对象，该对象由外层的Socket接收传递进来
- (void)handleLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject;

//点击播放器控制栏的连麦按钮时调用
- (void)linkMic;

@end


@protocol PLVLinkMicControllerDelegate <NSObject>

//发送连麦的相关请求的回调
- (void)linkMicController:(PLVLinkMicController *)lickMic emitLinkMicObject:(PLVSocketLinkMicEventType)eventType;

//发送连麦的相关请求，并处理ACK回调
- (void)linkMicController:(PLVLinkMicController *)lickMic emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback;

//连麦成功
- (void)linkMicSuccess:(PLVLinkMicController *)lickMic;

//退出连麦
- (void)cancelLinkMic:(PLVLinkMicController *)lickMic;

@end
