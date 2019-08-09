//
//  PLVChatCell.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/31.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVBaseCell.h"
#import "PLVPhotoBrowser.h"

NS_ASSUME_NONNULL_BEGIN

UIFont *plv_chat_text_font(void);

@class PLVChatUser;
@interface PLVChatCell : PLVBaseCell

/// 头像
@property (nonatomic, strong) UIImageView *avatarImgView;
/// 昵称
@property (nonatomic, strong) UILabel *nickNameLabel;
/// 头衔
@property (nonatomic, strong) UILabel *actorLable;

@property (nonatomic, getter=isMyMessage) BOOL myMessage;

- (void)setupChatUser:(PLVChatUser *)chatUser;

@end

@class PLVChatLabel;
@interface PLVChatSpeakCell : PLVChatCell

/// 聊天内容
@property (nonatomic, strong) PLVChatLabel *contentLabel;

@end

@interface PLVChatImageCell : PLVChatCell

/// 图像内容
@property (nonatomic, strong) UIImageView *contentImgView;

@property (nonatomic, strong) UIButton *refreshBtn;
@property (nonatomic, strong) UIView *loadingBgView;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

/// 更新上传进度
- (void)uploadProgress:(CGFloat)progress;

/// 鉴黄失败
- (void)checkFail:(BOOL)fail;

@end

NS_ASSUME_NONNULL_END
