//
//  PLVChatCell.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/31.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "PLVChatModel.h"
#import "PCCUtils.h"
#import "PLVChatTextView.h"

#define DEFAULT_CELL_HEIGHT 44.0

#pragma mark - Public Classes

@implementation PLVChatCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.avatarImgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 35, 35)];
        self.avatarImgView.layer.cornerRadius = 35.0/2;
        self.avatarImgView.layer.masksToBounds = YES;
        [self addSubview:self.avatarImgView];
        
        self.actorLable = [[UILabel alloc] init];
        self.actorLable.layer.cornerRadius = 9.0;
        self.actorLable.layer.masksToBounds = YES;
        self.actorLable.textColor = [UIColor whiteColor];
        if (@available(iOS 8.2, *)) {
            self.actorLable.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium];
        } else {
            self.actorLable.font = [UIFont systemFontOfSize:10.0];
        }
        self.actorLable.backgroundColor = UIColorFromRGB(0x2196F3);
        self.actorLable.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.actorLable];
        
        self.nickNameLabel = [[UILabel alloc] init];
        self.nickNameLabel.backgroundColor = [UIColor clearColor];
        self.nickNameLabel.textColor = [UIColor colorWithWhite:135/255.0 alpha:1.0];
        self.nickNameLabel.font = [UIFont systemFontOfSize:11.0];
        [self addSubview:self.nickNameLabel];
        
        [self.actorLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarImgView.mas_top);
            make.height.mas_equalTo(@(18));
            make.leading.equalTo(self.avatarImgView.mas_trailing).offset(10);
        }];
        [self.nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarImgView.mas_top);
            make.height.mas_equalTo(@(18));
            make.leading.equalTo(self.actorLable.mas_trailing).offset(5);
        }];
    }
    return self;
}

- (void)setupChatUser:(PLVChatUser *)chatUser {
    [self.avatarImgView sd_setImageWithURL:[NSURL URLWithString:chatUser.avatar] placeholderImage:[PCCUtils getChatroomImage:@"plv_img_default_avatar"]];
    if (chatUser.actor) {
        self.actorLable.text = chatUser.actor;
        CGSize size = [self.actorLable sizeThatFits:CGSizeMake(MAXFLOAT, 18)];
        [self.actorLable mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(size.width+20, 18));
            make.top.equalTo(self.avatarImgView.mas_top);
            make.leading.equalTo(self.avatarImgView.mas_trailing).offset(10);
        }];
    } else {
        [self.actorLable mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeZero);
            make.top.equalTo(self.avatarImgView.mas_top);
            make.leading.equalTo(self.avatarImgView.mas_trailing).offset(5);
        }];
    }
    self.nickNameLabel.text = chatUser.nickName;
}

@end

@implementation PLVChatSpeakCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.messageTextView = [[PLVChatTextView alloc] init];
        self.messageTextView.delegate = self;
        [self addSubview:self.messageTextView];
    }
    return self;
}

- (void)layoutCell {
    if (![self.model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    self.actorLable.hidden = self.model.localMessage;
    self.nickNameLabel.hidden = self.model.localMessage;
    self.avatarImgView.hidden = self.model.localMessage;
    
    PLVChatModel *chatModel = (PLVChatModel *)self.model;
    self.messageTextView.mine = self.model.localMessage;
    BOOL admin = ![chatModel.user isAudience] || chatModel.user.guest;
    CGSize newSize = [self.messageTextView setMessageContent:chatModel.speakContent admin:admin];
    
    if (self.model.localMessage) {
        
        chatModel.cellHeight = newSize.height + 10;
        [self.messageTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(newSize);
            make.top.equalTo(self.mas_top).offset(10.0);
            make.right.equalTo(self.mas_right).offset(-10);
        }];
    } else {
        [self setupChatUser:chatModel.user];
        
        chatModel.cellHeight =  newSize.height + 33; // 10+18+5
        [self.messageTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(newSize);
            make.top.equalTo(self.nickNameLabel.mas_bottom).offset(5);
            make.leading.equalTo(self.avatarImgView.mas_trailing).offset(10);
        }];
    }
}

+ (CGFloat)cellHeightWithModel:(PLVCellModel *)model {
    if (![model isKindOfClass:[PLVChatModel class]]) {
        return 0.0;
    }
    
    PLVChatModel *chatModel = (PLVChatModel *)model;
    NSMutableAttributedString *attributedStr = [PLVChatTextView attributedStringWithContent:chatModel.speakContent];
    if (chatModel.type == PLVChatModelTypeMySpeak) {
        // 10(顶部间隔)+10(PLVCRLabel上内边距)+10(PLVCRLabel上内边距)
        return [self autoCalculateSize:CGSizeMake(270, MAXFLOAT)
        attributedContent:attributedStr].height + 30.0;
    } else if (chatModel.type == PLVChatModelTypeOtherSpeak) {
        // 10+18+5(顶部间隔)+10(PLVCRLabel上内边距)+10(PLVCRLabel上内边距)
        return [self autoCalculateSize:CGSizeMake(260, MAXFLOAT)
                     attributedContent:attributedStr].height + 53.0;
    } else {
        return 0;
    }
}

#pragma mark - Private

- (void)drawCornerRadiusWithView:(UIView *)view size:(CGSize)size roundingCorners:(UIRectCorner)corners {
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
}

/// 计算属性字符串文本的宽或高
+ (CGSize)autoCalculateSize:(CGSize)size attributedContent:(NSAttributedString *)attributedContent {
    CGRect rect = [attributedContent boundingRectWithSize:size
                                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  context:nil];
    return rect.size;
}

#pragma mark - UITextView Delegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (URL) {
        if (@available(iOS 10.0, *)) {
            if (self.urlDelegate) {
                [self.urlDelegate interactWithURL:URL];
            }
            return !self.urlDelegate;
        } else {
            if (self.urlDelegate) {
                [self.urlDelegate interactWithURL:URL];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:URL];
                });
            }
            return NO; // iOS 10 以下不响应长按时间
        }
    } else {
        return NO;
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    if (@available(iOS 10.0, *)) {
        return YES;
    } else {
        return NO;
    }
}

@end

@interface PLVChatImageCell ()

@property (nonatomic, strong) PLVPhotoBrowser *phototBrowser;
@end

@implementation PLVChatImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentImgView = [[UIImageView alloc] init];
        self.contentImgView.contentMode = UIViewContentModeScaleAspectFit;
        self.contentImgView.backgroundColor = UIColorFromRGB(0xD3D3D3);
        self.contentImgView.layer.cornerRadius = 5.0;
        self.contentImgView.layer.masksToBounds = YES;
        self.contentImgView.userInteractionEnabled = YES;
        [self addSubview:self.contentImgView];
        
        self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.contentImgView addSubview:self.activityView];
        [self.activityView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentImgView.mas_centerX);
            make.centerY.equalTo(self.contentImgView.mas_centerY).offset(-12.0);
        }];
        
        self.progressLabel = [[UILabel alloc] init];
        self.progressLabel.textColor = [UIColor whiteColor];
        self.progressLabel.font = [UIFont systemFontOfSize:12.0];
        self.progressLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentImgView addSubview:self.progressLabel];
        [self.progressLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.height.mas_equalTo(24.0);
            make.left.right.equalTo(self.contentImgView);
            make.centerX.equalTo(self.contentImgView.mas_centerX);
            make.centerY.equalTo(self.contentImgView.mas_centerY).offset(12.0);
        }];
        
        self.refreshBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.refreshBtn setImage:[PCCUtils getChatroomImage:@"plv_resend"] forState:UIControlStateNormal];
        [self.refreshBtn addTarget:self action:@selector(refreshDownload:) forControlEvents:UIControlEventTouchUpInside];
        self.refreshBtn.hidden = YES;
        [self.contentImgView addSubview:self.refreshBtn];
        
        self.loadingBgView = [[UIView alloc] initWithFrame:self.contentImgView.bounds];
        self.loadingBgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.loadingBgView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.3];
        [self.contentImgView addSubview:self.loadingBgView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageView:)];
        [self.contentImgView addGestureRecognizer:tapGesture];
        
        self.phototBrowser = [PLVPhotoBrowser new];
    }
    return self;
}

- (void)layoutCell {
    if (![self.model isKindOfClass:[PLVChatModel class]]) {
        return;
    }
    self.actorLable.hidden = self.model.localMessage;
    self.nickNameLabel.hidden = self.model.localMessage;
    self.avatarImgView.hidden = self.model.localMessage;
    self.loadingBgView.hidden = !self.model.localMessage;
    
    PLVChatModel *chatModel = (PLVChatModel *)self.model;
    if (self.model.localMessage) {
        self.contentImgView.image = chatModel.imageContent.image;
        self.contentImgView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(chatModel.imageContent.size);
            make.top.equalTo(self.mas_top).offset(10.0);
            make.trailing.equalTo(self.mas_trailing).offset(-10.0);
        }];
        [self.refreshBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(30.0, 30.0));
            make.centerY.equalTo(self.contentImgView.mas_centerY);
            make.right.equalTo(self.contentImgView.mas_left).offset(-10.0);
        }];
    } else {
        [self setupChatUser:chatModel.user];
        [self.refreshBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.contentImgView);
            make.size.mas_equalTo(CGSizeMake(30.0, 30.0));
        }];
        
        __weak typeof(self)weakSelf = self;
        if (CGSizeEqualToSize(chatModel.imageContent.size, CGSizeZero)) { // 兼容无 size 数据
            chatModel.cellHeight = 165.0; // 10+18+5+132
            
            [self.contentImgView sd_setImageWithURL:[NSURL URLWithString:chatModel.imageContent.url] placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (error) {
                    [weakSelf uploadProgress:-1.0];
                } else {
                    [weakSelf uploadProgress:1.0];
                    if (image.size.width > 132 || image.size.height > 132) {
                        weakSelf.contentImgView.contentMode = UIViewContentModeScaleAspectFit;
                    } else {
                        weakSelf.contentImgView.contentMode = UIViewContentModeCenter;
                    }
                }
            }];
            [self.contentImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(132, 132));
                make.top.equalTo(self.nickNameLabel.mas_bottom).offset(5);
                make.leading.equalTo(self.avatarImgView.mas_trailing).offset(10);
            }];
        } else { // 有 size 数据
            chatModel.cellHeight = chatModel.imageContent.size.height + 33;
            
            self.contentImgView.contentMode = UIViewContentModeScaleAspectFill;
            [self.contentImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(chatModel.imageContent.size);
                make.top.equalTo(self.nickNameLabel.mas_bottom).offset(5);
                make.leading.equalTo(self.avatarImgView.mas_trailing).offset(10);
            }];
            [self.contentImgView sd_setImageWithURL:[NSURL URLWithString:chatModel.imageContent.url] placeholderImage:nil options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                CGFloat progress = (CGFloat)receivedSize/expectedSize;
                [weakSelf uploadProgress:progress];
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (error) {
                    [weakSelf uploadProgress:-1.0];
                } else {
                    [weakSelf uploadProgress:1.0];
                }
            }];
        }
    }
}

+ (CGFloat)cellHeightWithModel:(PLVCellModel *)model {
    if (![model isKindOfClass:[PLVChatModel class]]) {
        return 0.0;
    }
    
    PLVChatModel *chatModel = (PLVChatModel *)model;
    switch (chatModel.type) {
        case PLVChatModelTypeMyImage: {
            if (CGSizeEqualToSize(chatModel.imageContent.size, CGSizeZero)) {
                return 142.0;
            } else {
                return chatModel.imageContent.size.height + 10.0;
            }
        } break;
        case PLVChatModelTypeOtherImage: {
            if (CGSizeEqualToSize(chatModel.imageContent.size, CGSizeZero)) {
                return 165;
            } else {
                return chatModel.imageContent.size.height + 33;
            }
        } break;
        default:
            break;
    }
    return 0.0;
}

#pragma mark - Private

- (void)uploadProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (progress < 0.0) {
            self.refreshBtn.hidden = NO;
            self.progressLabel.hidden = YES;
            [self.activityView stopAnimating];
        } else if (progress >= 1.0) {
            self.refreshBtn.hidden = YES;
            self.progressLabel.hidden = YES;
            [self.activityView stopAnimating];
        } else {
            self.refreshBtn.hidden = YES;
            self.progressLabel.hidden = NO;
            [self.activityView startAnimating];
            self.progressLabel.text = [NSString stringWithFormat:@"%0.2f%%", progress == -0.0 ? 0.0 : progress*100.0];
        }
    });
}

- (void)checkFail:(BOOL)fail {
    if (fail) {
        self.contentImgView.layer.borderWidth = 3.0;
        self.contentImgView.layer.borderColor = [UIColor redColor].CGColor;
    } else {
        self.contentImgView.layer.borderWidth = 0.0;
    }
}

- (void)tapImageView:(UIGestureRecognizer *)sender {
    UIImageView *imageView = (UIImageView *)sender.view;
    [self.phototBrowser scaleImageViewToFullScreen:imageView];
}

- (void)refreshDownload:(UIButton *)sender {
    sender.hidden = YES;
    [self layoutCell];
}
    
@end
