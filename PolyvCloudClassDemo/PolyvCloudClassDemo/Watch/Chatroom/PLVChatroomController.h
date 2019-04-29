//
//  PLVChatroomController.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 23/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>
#import <PolyvBusinessSDK/PLVSocketObject.h>
#import "PLVTextInputView.h"

/// 聊天室错误码
typedef NS_ENUM(NSInteger, PLVChatroomErrorCode) {
    /// 无访问权限
    PLVChatroomErrorCodeBeKicked    = -100,
    /// 房间关闭
    PLVChatroomErrorCodeRoomClose   = -111,
    /// 被禁言
    PLVChatroomErrorCodeBanned      = -122,
};

@class PLVChatroomController;

@protocol PLVChatroomDelegate <NSObject>
@required
/// 授权失败的回调
- (void)chatroom:(PLVChatroomController *)chatroom didOpenError:(PLVChatroomErrorCode)code;

/// 聊天室消息回调
- (void)chatroom:(PLVChatroomController *)chatroom emitSocketObject:(PLVSocketChatRoomObject *)object;

/// 输入键盘弹出弹入回调，由外层实现相关逻辑
- (void)chatroom:(PLVChatroomController *)chatroom followKeyboardAnimation:(BOOL)flag;

/// 从外层获取当前频道的SessionId
- (NSString *)currentChannelSessionId:(PLVChatroomController *)chatroom;

@optional
/// 发言回调，可用于弹幕显示
- (void)chatroom:(PLVChatroomController *)chatroom didSendSpeakContent:(NSString *)content;

/// 自定义消息回调
- (void)chatroom:(PLVChatroomController *)chatroom emitCustomEvent:(NSString *)event emitMode:(int)emitMode data:(NSDictionary *)data tip:(NSString *)tip;

/// 回调HUD消息
- (void)chatroom:(PLVChatroomController *)chatroom showMessage:(NSString *)message;

@end

@interface PLVChatroomController : UIViewController

/// 当前频道号
@property (nonatomic, readonly) NSUInteger roomId;

/// 输入键盘的类型
@property (nonatomic, readonly) PLVTextInputViewType type;

/// 聊天室在线人数（实时）
@property (nonatomic, readonly) NSUInteger onlineCount;

/// 是否关闭
@property (nonatomic, getter=isClosed, readonly) BOOL closed;

/// delegate
@property (nonatomic, weak) id<PLVChatroomDelegate> delegate;

/// 各类开关信息
@property (nonatomic, strong) NSDictionary *switchInfo;

/// 只看讲师模式下是否允许发言、点赞、送花等操作，默认 YES（公聊模式属性）
@property (nonatomic, assign) BOOL allowToSpeakInTeacherMode;

/**
 是否有观看直播权限

 @param roomId 房间号
 @return YES/NO
 */
+ (BOOL)havePermissionToWatchLive:(NSUInteger)roomId;

/**
 聊天室初始化方法
 
 @param type 聊天室类型
 @param roomId 房间号
 @param frame frame
 @return PLVChatroomController
 */
- (instancetype)initChatroomWithType:(PLVTextInputViewType)type roomId:(NSUInteger)roomId frame:(CGRect)frame;

/**
 聊天室便利初始化方法

 @param type 聊天室类型
 @param roomId 房间号
 @param frame frame
 @return PLVChatroomController
 */
+ (instancetype)chatroomWithType:(PLVTextInputViewType)type roomId:(NSUInteger)roomId frame:(CGRect)frame;

/**
 加载子视图
 */
- (void)loadSubViews;

/**
 准备退出时，必须清空定时器资源
 */
- (void)clearResource;

/**
 还原聊天室状态
 */
- (void)recoverChatroomStatus;

/**
 添加新事件

 @param object PLVSocketChatRoomObject
 */
- (void)addNewChatroomObject:(PLVSocketChatRoomObject *)object;

/**
 添加自定义事件

 @param customeMessage 自定义消息内容
 @param mine 自己消息类型
 */
- (void)addCustomMessage:(NSDictionary *)customeMessage mine:(BOOL)mine;

#pragma mark - chatInputView

- (void)tapChatInputView;

@end
