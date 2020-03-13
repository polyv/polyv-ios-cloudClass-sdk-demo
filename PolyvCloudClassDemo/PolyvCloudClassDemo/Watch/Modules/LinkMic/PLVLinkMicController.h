//
//  PLVLinkMicController.h
//  PolyvCloudClassSDK
//
//  Created by zykhbl on 2018/10/17.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PolyvBusinessSDK/PLVSocketObject.h>
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>
#import "PLVLinkMicView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVLinkMicStatus) {
    PLVLinkMicStatusNone = 0,       //无状态（可连麦，但未加入连麦）
    PLVLinkMicStatusWait = 1,       //等待允许中（举手中）
    PLVLinkMicStatusJoining = 2,    //加入连麦中（加入中）
    PLVLinkMicStatusJoin = 3,       //发言中（连麦中）
    PLVLinkMicStatusDisabe = 4      //讲师未开启连麦
};

@protocol PLVLinkMicControllerDelegate;

/// 连麦控制器
@interface PLVLinkMicController : UIViewController

/// delegate
@property (nonatomic, weak) id<PLVLinkMicControllerDelegate> delegate;
/// 是否参与者
@property (nonatomic, assign) BOOL viewer;
/// 是否开启“看我”功能
@property (nonatomic, assign) BOOL viewerSignalEnabled;
/// 是否开启"奖杯"功能
@property (nonatomic, assign) BOOL awardTrophyEnabled;
/// 连麦类型（普通直播连麦，或云课堂连麦）
@property (nonatomic, assign) PLVLinkMicType linkMicType;
/// 登录对象，连麦时需要使用
@property (nonatomic, strong) PLVSocketObject *login;
/// 当前直播的sessionId
@property (nonatomic, strong) NSString *sessionId;
/// 播放器皮肤上的连麦按钮，由demo设置
@property (nonatomic, strong) UIButton *linkMicBtn;
/// 播放器皮肤上的"看我"按钮，由demo设置
@property (nonatomic, strong) UIButton *lookAtMeBtn;
/// 聊天室的bar高度
@property (nonatomic, assign) CGFloat pageBarHeight;
/// 页面初始化前，记住竖屏时连麦窗口大小
@property (nonatomic, assign) CGSize originSize;
/// 记住当前频道讲师开启的连麦类型（YES：声音；NO：视频）
@property (nonatomic, assign, readonly) BOOL linkMicOnAudio;
/// 连麦人的关联窗口集合(避免 linkMicViewDic 导致的先后顺序问题，方便顺序查找连麦人的窗口)
@property (nonatomic, strong, readonly) NSMutableArray *linkMicViewArray;
/// 连麦相关控制按钮
@property (nonatomic, strong, readonly) UIView *controlView;
/// 是否横屏
@property (nonatomic, assign) BOOL fullscreen;
/// 设备方向
@property (nonatomic, assign) UIDeviceOrientation orientation;
/// 一行显示多少列的连麦窗口
@property (nonatomic, assign, readonly) int colNum;
/// 副屏是否关闭
@property (nonatomic, assign) BOOL secondaryClosed;
/// PPT相关的控制器，在连麦学员开启了画笔权限后使用
@property (nonatomic, weak) PLVPPTViewController *PPTVC;
/// token不为空时，重连后要发送reJoinMic事件
@property (nonatomic, strong) NSString *token;

/// 当前用户连麦状态
@property (nonatomic, assign, readonly) PLVLinkMicStatus linkMicStatus;

// UI control
@property (nonatomic, strong, readonly) UIScrollView *scrollView;//连麦列表的展示窗口
@property (nonatomic, strong, readonly) UIView *liveInfoView;//直播间信息
@property (nonatomic, assign, readonly) BOOL liveInfoLoaded;//讲师头像和昵称加载完成
@property (nonatomic, strong, readonly) UIImageView *avatarImgView;//讲师头像
@property (nonatomic, strong, readonly) UILabel *nickNameLabel;//讲师昵称
@property (nonatomic, strong, readonly) UIView *spaceLine;//分隔线
@property (nonatomic, strong, readonly) UILabel *onLineCountLabel;//在线人数（非连麦在线人数）
@property (nonatomic, assign, readonly) CGFloat controlHeight;//控制按钮窗口的高度
@property (nonatomic, strong, readonly) UILabel *tipLabel;//连麦状态提示
@property (nonatomic, strong, readonly) UIButton *penBtn;//画笔按钮
@property (nonatomic, strong, readonly) UIButton *micPhoneBtn;//麦克风控制按钮
@property (nonatomic, strong, readonly) UIButton *cameraBtn;//摄像头控制按钮
@property (nonatomic, strong, readonly) UIButton *switchCameraBtn;//前后置摄像头切换按钮
@property (nonatomic, strong, readonly) UIButton *arrowBtn;//切换按钮

/// 准备退出时，必须清空连麦资源
- (void)clearResource;

/// 处理连麦的Socket消息对象，该对象由外层的Socket接收传递进来
- (void)handleLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject;

/// 隐藏或显示连麦窗口
- (void)hiddenLinkMic:(BOOL)hidden;

/// 调整连麦窗口的frame
- (void)resetLinkMicFrame:(CGRect)layoutFrame;

/// 关闭或打开副屏时，调整顶部窗口的frame
- (void)resetLinkMicTopControlFrame:(BOOL)close;

/// 刷新连麦窗口的当前在线人数
- (void)refreshOnlineCount:(NSUInteger)number;

/// 刷新讲师头像，昵称
- (void)resetTeacherInfo:(NSString *)avatar nickName:(NSString *)nickName;

/// 更新某个用户的奖杯数
- (void)updateUser:(NSString *)userId trophyNumber:(NSInteger)trophyNumber;

@end


@protocol PLVLinkMicControllerDelegate <NSObject>

/// 显示toast信息
- (void)linkMicController:(PLVLinkMicController *)lickMic toastTitle:(NSString *)toast detail:(NSString *)detail;

/// 发送连麦的相关请求的回调
- (void)linkMicController:(PLVLinkMicController *)lickMic emitLinkMicObject:(PLVSocketLinkMicEventType)eventType;

/// 发送连麦的相关请求，并处理ACK回调
- (void)linkMicController:(PLVLinkMicController *)lickMic emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback;

/// 连麦过程中，学员（当前的本地用户）主动关闭和打开自己的摄像头/麦克风回调
- (void)emitMuteSocketMessage:(NSString *)uid type:(NSString *)type mute:(BOOL)mute;

/// 连麦成功
- (void)linkMicSuccess:(PLVLinkMicController *)lickMic;

/// 退出连麦
- (void)cancelLinkMic:(PLVLinkMicController *)lickMic;

/// 切换连麦人的位置，manualControl为YES时，是自己主动切换主副屏窗口，为NO时是推流端的讲师切换主副屏窗口
- (void)linkMicSwitchViewAction:(PLVLinkMicController *)lickMic manualControl:(BOOL)manualControl;

/// 讲师主动切换PPT和视频窗口（status为YES代表视频在主窗口，为NO代表PPT在主窗口）
- (void)linkMicSwitchViewAction:(PLVLinkMicController *)lickMic status:(BOOL)status;

/// 改变连麦窗口的大小
- (void)changeLinkMicFrame:(PLVLinkMicController *)lickMic whitChatroom:(BOOL)chatroom;

/// 画笔权限的开启和关闭（控制视频区域主窗口的皮肤显示隐藏的逻辑）
- (void)linkMicController:(PLVLinkMicController *)lickMic paint:(BOOL)paint;

/// 发出“看我”请求
- (void)lookAtMeWithLinkMicController:(PLVLinkMicController *)lickMic;

@end

NS_ASSUME_NONNULL_END
