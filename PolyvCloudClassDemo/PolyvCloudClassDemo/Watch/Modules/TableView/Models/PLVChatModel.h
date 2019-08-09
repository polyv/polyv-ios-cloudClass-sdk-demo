//
//  PLVChatModel.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/31.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVCellModel.h"
#import "PLVChatCell.h"

NS_ASSUME_NONNULL_BEGIN

/// 用户类型
typedef NS_ENUM(NSInteger, PLVChatUserType) {
    /// 讲师
    PLVChatUserTypeTeacher   = 1,
    /// 助教
    PLVChatUserTypeAssistant = 2,
    /// 管理员
    PLVChatUserTypeManager   = 3,
    /// 学生
    PLVChatUserTypeStudent   = 4,
    /// 云课堂学员
    PLVChatUserTypeSlice     = 5,
    /// Unknown
    PLVChatUserTypeUnknown   = 6,
};

@interface PLVChatUser : NSObject

/// 用户头衔
@property (nonatomic, strong) NSString *actor;
/// 用户头衔字体颜色
@property (nonatomic, strong) UIColor *actorTextColor;
/// 用户头衔背景颜色
@property (nonatomic, strong) UIColor *actorBackgroundColor;
/// 用户昵称
@property (nonatomic, strong) NSString *nickName;
/// 用户头像
@property (nonatomic, strong) NSString *avatar;

/// 用户Id
@property (nonatomic, strong) NSString *userId;
/// 用户类型
@property (nonatomic, assign) PLVChatUserType userType;

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo;

/// 非teacher、assistant、manager用户类型
- (BOOL)isAudience;

@end

@interface PLVChatTextContent : NSObject

/// 消息文本内容
@property (nonatomic, strong) NSString *text;
/// 聊天表情图片的文本内容
@property (nonatomic, strong) NSAttributedString *attributedText;
/// 文本颜色
@property (nonatomic, strong) UIColor *textColor;

- (instancetype)initWithText:(NSString *)text;

/// other message invoke
- (instancetype)initWithText:(NSString *)text audience:(BOOL)audience;

@end

@interface PLVChatImageContent : NSObject

/// 图片Id
@property (nonatomic, strong) NSString *imgId;

/// 图片地址
@property (nonatomic, strong) NSString *url;
/// 图片大小
@property (nonatomic, assign) CGSize size;

/// 本地上传的图片（TODO:优化为地址）
@property (nonatomic, strong) UIImage *image;
/// 上传图片进度
@property (nonatomic, assign) CGFloat uploadProgress;
/// 上传图片失败标志位
@property (nonatomic, assign) BOOL uploadFail;
/// 上传图片鉴黄失败的标志位
@property (nonatomic, assign) BOOL checkFail;

/**
 便利初始化方法
 @param image NSString or UIImage
 */
- (instancetype)initWithImage:(id)image imgId:(NSString *)imgId size:(CGSize)size;

@end

typedef NS_ENUM(NSUInteger, PLVChatModelType) {
    PLVChatModelTypeOtherSpeak,
    PLVChatModelTypeOtherImage,
    PLVChatModelTypeMySpeak,
    PLVChatModelTypeMyImage,
};

@interface PLVChatModel : PLVCellModel

/// 聊天信息类型
@property (nonatomic, assign) PLVChatModelType type;

/// 用户信息
@property (nonatomic, strong) PLVChatUser *user;

/// 文本消息
@property (nonatomic, strong) PLVChatTextContent *textContent;

/// 图片信息
@property (nonatomic, strong) PLVChatImageContent *imageContent;

@end

NS_ASSUME_NONNULL_END
