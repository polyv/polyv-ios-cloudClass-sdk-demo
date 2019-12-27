//
//  PLVChatroomModel.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 24/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PolyvBusinessSDK/PolyvBusinessSDK.h>
#import "PLVChatroomCell.h"

/// model 类型
typedef NS_ENUM(NSInteger, PLVChatroomModelType) {
    /// 未定义消息类型（默认）
    PLVChatroomModelTypeNotDefine      = 0,
    /// 自己发言类型
    PLVChatroomModelTypeSpeakOwn       = 1,
    /// 服务器返回的自己发言消息类型（开启聊天审核后）
    PLVChatroomModelTypeSpeakOwnCensor = 2,
    /// 别人发言类型
    PLVChatroomModelTypeSpeakOther     = 3,
    /// 发送图片类型
    PLVChatroomModelTypeImageSend      = 4,
    /// 接收图片类型
    PLVChatroomModelTypeImageReceived  = 5,
    /// 送花消息类型
    PLVChatroomModelTypeFlower         = 6,
    /// 点赞消息类型
    PLVChatroomModelTypeLike           = 7,
    /// 系统消息类型
    PLVChatroomModelTypeSystem         = 8,
    /// 时间类型
    PLVChatroomModelTypeTime           = 9,
    /// 自定义类型
    PLVChatroomModelTypeCustom         = 10,
};

/// 用户类型
typedef NS_ENUM(NSInteger, PLVChatroomUserType) {
    /// 无
    PLVChatroomUserTypeNone      = 0,
    /// 讲师
    PLVChatroomUserTypeTeacher   = 1,
    /// 助教
    PLVChatroomUserTypeAssistant = 2,
    /// 管理员
    PLVChatroomUserTypeManager   = 3,
    /// 嘉宾
    PLVChatroomUserTypeGuest     = 4,
    /// 学生
    PLVChatroomUserTypeStudent   = 5,
    /// 云课堂学员
    PLVChatroomUserTypeSlice     = 6,
};

/// 聊天室Model
@interface PLVChatroomModel : NSObject

/// cell高度
@property (nonatomic, readonly) CGFloat cellHeight;

/// 聊天室类型
@property (nonatomic, readonly) PLVChatroomModelType type;

/// 本地消息模型
@property (nonatomic, assign) BOOL localMessageModel;

/// 消息唯一 id，maybe nil.
@property (nonatomic, strong, readonly) NSString *msgId;

/// 以下为包含用户信息的属性
/// 用户类型
@property (nonatomic, readonly) PLVChatroomUserType userType;
/// 身份用户，userType: Teacher、Assistant、Manager、Guest
@property (nonatomic, getter=isTeacher, readonly) BOOL teacher;

/// 发言内容，maybe nil.
@property (nonatomic, strong, readonly) NSString *speakContent;

/// 图片地址
@property (nonatomic, strong, readonly) NSString *imgUrl;
/// 图片ID
@property (nonatomic, strong, readonly) NSString *imgId;
/// 图片
@property (nonatomic, strong, readonly) UIImage *image;
/// 图片大小
@property (nonatomic, assign, readonly) CGSize imageViewSize;
/// 上传图片的进度
@property (nonatomic, assign) CGFloat uploadProgress;
/// 上传图片识别标志位
@property (nonatomic, assign) BOOL uploadFail;
/// 上传图片鉴黄失败的标志位
@property (nonatomic, assign) BOOL checkFail;

/*
 初始化
 
 @param object 聊天室Socket对象.
 */
+ (instancetype)modelWithObject:(PLVSocketChatRoomObject *)object;

/*
 初始化点赞或送花Model
 
 @param object 聊天室点赞或送花的Socket对象.
 @param flower Yes 送花；No 点赞
 */
+ (instancetype)modelWithObject:(PLVSocketChatRoomObject *)object flower:(BOOL)flower;

/// 根据当前的Model生成对应的UITableCellView
- (PLVChatroomCell *)cellFromModelWithTableView:(UITableView *)tableView;

@end
