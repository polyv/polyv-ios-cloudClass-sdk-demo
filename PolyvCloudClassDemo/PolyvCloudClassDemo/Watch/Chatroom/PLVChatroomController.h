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

/// 发送Socket信息，传递PLVSocketChatRoomObject对象，由外层发送
- (void)chatroom:(PLVChatroomController *)chatroom emitSocketObject:(PLVSocketChatRoomObject *)object;

/// 用户昵称设置回调
- (void)chatroom:(PLVChatroomController *)chatroom nickNameRenamed:(NSString *)newName success:(BOOL)success message:(NSString *)message;

/// 输入键盘弹出弹入回调，由外层实现相关逻辑
- (void)chatroom:(PLVChatroomController *)chatroom followKeyboardAnimation:(BOOL)flag;

/// 从外层获取当前频道的SessionId
- (NSString *)currentChannelSessionId:(PLVChatroomController *)chatroom;

@optional
/// 发言，传递content，由外层发送
- (void)chatroom:(PLVChatroomController *)chatroom didSendSpeakContent:(NSString *)content;

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

/// 键盘控件
@property (nonatomic, strong, readonly) PLVTextInputView *inputView;

/// delegate
@property (nonatomic, weak) id<PLVChatroomDelegate> delegate;

/// 登录 socket 的用户对象（必传，否则无法提交聊天室相关消息）
/// 该属性逐渐废弃，使用 PLVChatroomManager 中的 socketUser 值
@property (nonatomic, strong) PLVSocketObject *socketUser;

/// 各类开关信息
@property (nonatomic, strong) NSDictionary *switchInfo;

/// 只看讲师模式下是否允许发言、点赞、送花等操作，默认 YES（公聊模式属性）
@property (nonatomic, assign) BOOL allowToSpeakInTeacherMode;

/// 是否有观看直播权限
+ (BOOL)havePermissionToWatchLive:(NSUInteger)roomId;

/// 便利初始化
+ (instancetype)chatroomWithType:(PLVTextInputViewType)type roomId:(NSUInteger)roomId frame:(CGRect)frame;

/// 初始化
- (instancetype)initChatroomWithType:(PLVTextInputViewType)type roomId:(NSUInteger)roomId frame:(CGRect)frame;

/// 准备退出时，必须清空定时器资源
- (void)clearResource;

/// 加载子视图
- (void)loadSubViews;

/// 添加新事件
- (void)addNewChatroomObject:(PLVSocketChatRoomObject *)object;

@end
