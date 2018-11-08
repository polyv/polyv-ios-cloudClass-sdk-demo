//
//  PLVChatroomCell.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 24/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

/// cell 类型
typedef NS_ENUM(NSInteger, PLVChatroomCellType) {
    PLVChatroomCellTypeSpeakOwn,      // 自己发言
    PLVChatroomCellTypeSpeakOther,    // 他人发言
    PLVChatroomCellTypeImageSend,     // 发送图片
    PLVChatroomCellTypeImageReceived, // 接收图片
    PLVChatroomCellTypeFlower,        // 送花效果
    PLVChatroomCellTypeSystem,        // 系统样式
    PLVChatroomCellTypeTime,          // 时间标签
};

@interface PLVChatroomCell : UITableViewCell

/// cell height
@property (nonatomic, readonly) CGFloat height;

- (instancetype)initWithReuseIdentifier:(NSString *)indentifier;

- (CGFloat)calculateCellHeightWithContent:(NSString *)content;

@end

@interface PLVChatroomSpeakOwnCell : PLVChatroomCell

@property (nonatomic, strong) NSString *speakContent;

@end

@interface PLVChatroomSpeakOtherCell : PLVChatroomCell

@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, strong) NSString *actor;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *speakContent;

// 头衔自定义颜色
@property (nonatomic, strong) UIColor *actorTextColor;
@property (nonatomic, strong) UIColor *actorBackgroundColor;

@end

@interface PLVChatroomImageSendCell : PLVChatroomCell

@property (nonatomic, strong) UIImage *image;

@end

@interface PLVChatroomImageReceivedCell : PLVChatroomCell

@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, strong) NSString *actor;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *imgUrl;

@property (nonatomic, assign) CGSize imageViewSize;

// 头衔自定义颜色
@property (nonatomic, strong) UIColor *actorTextColor;
@property (nonatomic, strong) UIColor *actorBackgroundColor;

@end

@interface PLVChatroomFlowerCell : PLVChatroomCell

@property (nonatomic, strong) NSString *content;

@end

@interface PLVChatroomSystemCell : PLVChatroomCell

@property (nonatomic, strong) NSString *content;

@end

@interface PLVChatroomTimeCell : PLVChatroomCell

@end
