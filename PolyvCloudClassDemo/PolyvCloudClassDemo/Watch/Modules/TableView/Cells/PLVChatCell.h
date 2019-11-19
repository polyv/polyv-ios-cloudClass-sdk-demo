//
//  PLVChatCell.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/31.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVBaseCell.h"
#import "PLVPhotoBrowser.h"
#import "PLVChatroomDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser;

@interface PLVChatCell : PLVBaseCell

@property (nonatomic, weak) id<PLVChatCellProtocol> urlDelegate;

/// 头像
@property (nonatomic, strong) UIImageView *avatarImgView;
/// 昵称
@property (nonatomic, strong) UILabel *nickNameLabel;
/// 头衔
@property (nonatomic, strong) UILabel *actorLable;

- (void)setupChatUser:(PLVChatUser *)chatUser;

@end

@class PLVChatTextView;
@interface PLVChatSpeakCell : PLVChatCell<
UITextViewDelegate
>

/// 聊天内容
@property (nonatomic, strong) PLVChatTextView *messageTextView;

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
