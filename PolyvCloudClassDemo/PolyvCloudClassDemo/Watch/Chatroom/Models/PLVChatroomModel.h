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
    PLVChatroomModelTypeNotDefine     = 0, // 未定义消息类型（默认）
    PLVChatroomModelTypeSpeakOwn      = 1, // 自己发言类型
    PLVChatroomModelTypeSpeakOther    = 2, // 别人发言类型
    PLVChatroomModelTypeImageSend     = 3, // 发送图片类型
    PLVChatroomModelTypeImageReceived = 4, // 接收图片类型
    PLVChatroomModelTypeFlower        = 5, // 送花消息类型
    PLVChatroomModelTypeLike          = 6, // 点赞消息类型
    PLVChatroomModelTypeSystem        = 7, // 系统消息类型
    PLVChatroomModelTypeTime          = 8, // 时间类型
};

/// 用户类型
typedef NS_ENUM(NSInteger, PLVChatroomUserType) {
    PLVChatroomUserTypeNone      = 0, // 无
    PLVChatroomUserTypeTeacher   = 1, // 讲师
    PLVChatroomUserTypeAssistant = 2, // 助教
    PLVChatroomUserTypeManager   = 3, // 管理员
    PLVChatroomUserTypeStudent   = 4, // 学生
    PLVChatroomUserTypeSlice     = 5, // 云课堂学员
};

@interface PLVChatroomModel : NSObject

@property (nonatomic, readonly) CGFloat cellHeight;

@property (nonatomic, readonly) PLVChatroomModelType type;

/// 消息唯一 id，maybe nil.
@property (nonatomic, strong, readonly) NSString *msgId;

/// 以下为包含用户信息的属性
/// 用户类型
@property (nonatomic, readonly) PLVChatroomUserType userType;
/// 身份用户，userType: Teacher、Assistant、Manager
@property (nonatomic, getter=isTeacher, readonly) BOOL teacher;

/// 发言内容，maybe nil.
@property (nonatomic, strong, readonly) NSString *speakContent;

/// 图片资源信息
@property (nonatomic, strong, readonly) NSString *imgUrl;
@property (nonatomic, strong, readonly) NSString *imgId;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, assign, readonly) CGSize imageViewSize;
@property (nonatomic, assign) CGFloat uploadProgress;
@property (nonatomic, assign) BOOL uploadFail;
@property (nonatomic, assign) BOOL checkFail;

+ (instancetype)modelWithObject:(PLVSocketChatRoomObject *)object;

+ (instancetype)modelWithObject:(PLVSocketChatRoomObject *)object flower:(BOOL)flower;

- (PLVChatroomCell *)cellFromModelWithTableView:(UITableView *)tableView;

@end
