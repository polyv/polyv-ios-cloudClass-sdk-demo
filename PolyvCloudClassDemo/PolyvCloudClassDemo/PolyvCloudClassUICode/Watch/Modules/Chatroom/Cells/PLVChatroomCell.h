//
//  PLVChatroomCell.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 24/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>
#import "PLVPhotoBrowser.h"
#import "PLVChatroomDefine.h"

@class PLVChatroomModel;

/// cell 类型
typedef NS_ENUM(NSInteger, PLVChatroomCellType) {
    /// 自己发言
    PLVChatroomCellTypeSpeakOwn,
    /// 他人发言
    PLVChatroomCellTypeSpeakOther,
    /// 发送图片
    PLVChatroomCellTypeImageSend,
    /// 接收图片
    PLVChatroomCellTypeImageReceived,
    /// 送花效果
    PLVChatroomCellTypeFlower,
    /// 系统样式
    PLVChatroomCellTypeSystem,
    /// 时间标签
    PLVChatroomCellTypeTime,
    /// 文本回复
    PLVChatroomCellTypeContentReply,
};

/// 聊天室单元格基类
@interface PLVChatroomCell : UITableViewCell

@property (nonatomic, weak) id<PLVChatCellProtocol> urlDelegate;

/// cell高度
@property (nonatomic, readonly) CGFloat height;

/// 自己的消息
@property (nonatomic, assign) BOOL mine;

/// 模型数据
@property (nonatomic, strong) NSDictionary *modelDict;

/// 获取类的 indentifier
+ (NSString *)cellIndetifier;

/// 初始化
- (instancetype)initWithReuseIdentifier:(NSString *)indentifier;

/// 根据content计算cell高度
- (CGFloat)calculateCellHeightWithContent:(NSString *)content;

/// 根据modelDict计算cell高度
+ (CGFloat)calculateCellHeightWithModelDict:(NSDictionary *)modelDict mine:(BOOL)mine;

@end

/// 自己发言的Cell
@interface PLVChatroomSpeakOwnCell : PLVChatroomCell

/// 发言内容
@property (nonatomic, strong) NSString *speakContent;

@end

/// 其他人发言的Cell
@interface PLVChatroomSpeakOtherCell : PLVChatroomCell

/// 发言者的头像URL
@property (nonatomic, strong) NSString *avatar;
/// 发言者的头衔
@property (nonatomic, strong) NSString *actor;
/// 发言者的昵称
@property (nonatomic, strong) NSString *nickName;
/// 发言者的发言内容
@property (nonatomic, strong) NSString *speakContent;
/// 发言者的发言内容字体颜色
@property (nonatomic, strong) UIColor *speakContentColor;
/// 头衔字体颜色
@property (nonatomic, strong) UIColor *actorTextColor;
/// 头衔背景颜色
@property (nonatomic, strong) UIColor *actorBackgroundColor;

- (void)setSpeakContent:(NSString *)speakContent admin:(BOOL)admin;

@end

/// 文本回复他人发言的Cell
@interface PLVChatroomContentReplyCell : PLVChatroomCell

/// 发言者的头像URL
@property (nonatomic, strong) NSString *avatar;
/// 发言者的头衔
@property (nonatomic, strong) NSString *actor;
/// 发言者的昵称
@property (nonatomic, strong) NSString *nickName;
/// 发言者的发言内容
@property (nonatomic, strong) NSString *speakContent;
/// 头衔字体颜色
@property (nonatomic, strong) UIColor *actorTextColor;
/// 头衔背景颜色
@property (nonatomic, strong) UIColor *actorBackgroundColor;

- (void)setModel:(PLVChatroomModel *)model;

- (CGFloat)calculateCellHeightWithModel:(PLVChatroomModel *)model;

@end

@protocol PLVChatroomImageSendCellDelegate;

/// 上传图片的Cell
@interface PLVChatroomImageSendCell : PLVChatroomCell

/// delegate（上传失败，点击刷新时回调）
@property (nonatomic, weak) id<PLVChatroomImageSendCellDelegate> delegate;
/// 图片Id
@property (nonatomic, strong) NSString *imgId;
/// 图片
@property (nonatomic, strong) UIImage *image;
/// 图片大小
@property (nonatomic, assign) CGSize imageViewSize;
/// 刷新按钮
@property (nonatomic, strong) UIButton *refreshBtn;
/// 图片URL
@property (nonatomic, strong) NSString *imgUrl;
/// 更新上传进度
- (void)uploadProgress:(CGFloat)progress;

/// 鉴黄失败
- (void)checkFail:(BOOL)fail;

@end

@protocol PLVChatroomImageSendCellDelegate <NSObject>

/// 上传失败，点击刷新时回调
- (void)refreshUpload:(PLVChatroomImageSendCell *)sendCell;

@end

/// 接收图片的Cell
@interface PLVChatroomImageReceivedCell : PLVChatroomCell

/// 发送人头像URL
@property (nonatomic, strong) NSString *avatar;
/// 发送人头衔
@property (nonatomic, strong) NSString *actor;
/// 发送人昵称
@property (nonatomic, strong) NSString *nickName;
/// 图片URL
@property (nonatomic, strong) NSString *imgUrl;
/// 图片大小
@property (nonatomic, assign) CGSize imageViewSize;
// 头衔字体颜色
@property (nonatomic, strong) UIColor *actorTextColor;
// 头衔背景颜色
@property (nonatomic, strong) UIColor *actorBackgroundColor;

@end

/// 送花或点赞的Cell
@interface PLVChatroomFlowerCell : PLVChatroomCell

/// icon图片（送花）
@property (nonatomic, strong) UIImageView *imgView;
/// 送花语或点赞语
@property (nonatomic, strong) NSString *content;

@end

/// 打赏的Cell
@interface PLVChatroomRewardCell : PLVChatroomCell

/// icon图片
@property (nonatomic, strong) UIImageView *imgView;
/// 图片链接
@property (nonatomic, strong) NSString *imgUrl;
/// 打赏语
@property (nonatomic, strong) NSString *content;
/// 打赏数量
@property (nonatomic, assign) NSInteger goodNum;

@end

/// 系统信息的Cell
@interface PLVChatroomSystemCell : PLVChatroomCell

/// 系统信息内容
@property (nonatomic, strong) NSString *content;

@end

/// 时间Cell
@interface PLVChatroomTimeCell : PLVChatroomCell

@end
