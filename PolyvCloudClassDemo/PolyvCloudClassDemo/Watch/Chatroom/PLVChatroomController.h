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

/// 从外层获取当前频道的SessionId
- (NSString *)currentChannelSessionId:(PLVChatroomController *)chatroom;

/// 登录成功后，返回登录消息里的user信息，调用PLVPPTViewController里的setUser
- (void)chatroom:(PLVChatroomController *)chatroom userInfo:(NSDictionary *)userInfo;

@optional
/// 输入键盘弹出弹入回调，由外层实现相关逻辑
- (void)chatroom:(PLVChatroomController *)chatroom followKeyboardAnimation:(BOOL)flag;

/// 发言回调，可用于弹幕显示
- (void)chatroom:(PLVChatroomController *)chatroom didSendSpeakContent:(NSString *)content;

/// 自定义消息回调
- (void)chatroom:(PLVChatroomController *)chatroom emitCustomEvent:(NSString *)event emitMode:(int)emitMode data:(NSDictionary *)data tip:(NSString *)tip;

/// 回调HUD消息
- (void)chatroom:(PLVChatroomController *)chatroom showMessage:(NSString *)message;

/// 查看公告
- (void)readBulletin:(PLVChatroomController *)chatroom;

/// 当前userId已在别处登录，确认后自动退出直播间
- (void)reLogin:(PLVChatroomController *)chatroom;

/// 刷新连麦窗口的当前在线人数
- (void)refreshLinkMicOnlineCount:(PLVChatroomController *)chatroom number:(NSUInteger)number;

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

/// 直播间开关信息
@property (nonatomic, strong) NSDictionary *switchInfo;

/// 只看讲师模式下是否允许发言、点赞、送花等操作，默认 YES（公聊模式属性）
@property (nonatomic, assign) BOOL allowToSpeakInTeacherMode;

/**
 是否有观看直播权限（0.9.0废弃，由服务器处理）
 参看SocketIO -socketIO: didLoginFailed: 回调方法

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
- (void)loadSubViews:(UIView *)tapSuperView;

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

/**
 发送一条自己文字评论
 
 @param text 自己文本消息
 */
- (void)sendTextMessage:(NSString *)text;

/// 取消键盘的输入
- (void)tapChatInputView;

/// 在连麦时需要调整聊天室的窗口大小
- (void)resetChatroomFrame:(CGRect)rect;

@end
