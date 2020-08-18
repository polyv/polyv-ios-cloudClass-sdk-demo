//
//  PLVChatroomReplyBubble.m
//  PolyvCloudClassDemo
//
//  Created by MissYasiky on 2020/7/8.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVChatroomReplyBubble.h"
#import "PLVChatroomModel.h"
#import "PCCUtils.h"
#import "PLVEmojiManager.h"
#import <SDWebImage/UIImageView+WebCache.h>

// 文本最大宽度
static float kBubbleMaxWidth = 260.0;
// 文本字体大小
static float kChatTextFontSize = 12.0;
// 昵称文本 label 高度
static float kNickLabelHeight = 13.0;
// 分割线高度
static float kLineHeight = 1.0;
// 文本色号
static NSString *kChatTextColor = @"#757575";
// 文本与文本上下间距、文本与气泡间距
static float kPadding = 8.0;
// 被回复的文本的最大高度（只允许最多显示2行）
static float kQuoteSpeakContentMaxHeight = 36.0f;

@interface PLVChatroomReplyBubble ()

@property (nonatomic, strong) UILabel *nickLabel;

@property (nonatomic, strong) UILabel *repliedContent;

@property (nonatomic, strong) UIImageView *repliedImageView;

@property (nonatomic, assign) CGSize imageViewSize;

@property (nonatomic, strong) UIView *line;

@end

@implementation PLVChatroomReplyBubble

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.nickLabel = [[UILabel alloc] init];
        self.nickLabel.font = [UIFont systemFontOfSize:kChatTextFontSize];
        self.nickLabel.textColor = [PCCUtils colorFromHexString:kChatTextColor];
        [self addSubview:self.nickLabel];
        
        self.repliedContent = [[UILabel alloc] init];
        self.repliedContent.font = [UIFont systemFontOfSize:kChatTextFontSize];
        self.repliedContent.textColor = [PCCUtils colorFromHexString:kChatTextColor];
        self.repliedContent.numberOfLines = 2;
        [self addSubview:self.repliedContent];
        
        self.repliedImageView = [[UIImageView alloc] init];
        self.repliedImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.repliedImageView.layer.masksToBounds = YES;
        self.repliedImageView.layer.cornerRadius = 2;
        self.repliedImageView.clipsToBounds = YES;
        [self addSubview:self.repliedImageView];
        
        self.line = [[UIView alloc] init];
        self.line.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
        [self addSubview:self.line];
    }
    return self;
}

#pragma mark - Public

- (void)setModel:(PLVChatroomModel *)model size:(CGSize)size {
    
    self.nickLabel.text = [NSString stringWithFormat:@"%@：", model.quoteUserNickName];
    [self.nickLabel sizeToFit];
    
    CGSize quoteSize = CGSizeZero;
    if (model.quoteSpeakContent && model.quoteSpeakContent.length > 0) {
        NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:model.quoteSpeakContent];
        NSMutableAttributedString *emojiAttributedString = [[PLVEmojiManager sharedManager] convertTextEmotionToAttachmentWithAttributedString:content font:[UIFont systemFontOfSize:kChatTextFontSize]];
        self.repliedContent.attributedText = [emojiAttributedString copy];
        quoteSize = [self.repliedContent sizeThatFits:CGSizeMake(kBubbleMaxWidth, kQuoteSpeakContentMaxHeight)];
    }
    
    self.repliedImageView.hidden = !model.quoteImageUrl;
    if (model.quoteImageUrl) {
        NSString *imageUrlString = [self packageURLStringWithHTTPS:model.quoteImageUrl];
        [self.repliedImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString]
                                 placeholderImage:nil
                                          options:SDWebImageRetryFailed
                                        completed:nil];
    }
    
    self.nickLabel.frame = CGRectMake(kPadding, kPadding, kBubbleMaxWidth, kNickLabelHeight);
    self.repliedContent.frame = CGRectMake(kPadding, self.nickLabel.frame.origin.y + self.nickLabel.frame.size.height + kPadding, quoteSize.width, quoteSize.height);
    self.repliedImageView.frame = CGRectMake(kPadding, kPadding + kNickLabelHeight + 4, self.imageViewSize.width, self.imageViewSize.height);
    
    if (self.repliedImageView.hidden) {
        self.line.frame = CGRectMake(kPadding, self.repliedContent.frame.origin.y + self.repliedContent.frame.size.height + kPadding, size.width - 2 * kPadding, kLineHeight);
    } else {
        self.line.frame = CGRectMake(kPadding, self.repliedImageView.frame.origin.y + self.repliedImageView.frame.size.height + kPadding, size.width - 2 * kPadding, kLineHeight);
    }
    
    [self drawCornerRadiusWithSize:size];
}

- (CGSize)bubbleSizeWithModel:(PLVChatroomModel *)model speakContentSize:(CGSize)speakSize {
    CGSize quoteSize = CGSizeZero;
    if (model.quoteSpeakContent && model.quoteSpeakContent.length > 0) {
        quoteSize = [model.quoteSpeakContent boundingRectWithSize:CGSizeMake(kBubbleMaxWidth, kQuoteSpeakContentMaxHeight)
                                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                       attributes:nil
                                                          context:nil].size;
    }
    
    self.imageViewSize = [self calculateQuoteImageViewSizeWithImageSize:CGSizeMake(model.quoteImageWidth, model.quoteImageHeight)];
    
    CGFloat height = kPadding + kNickLabelHeight + kPadding + kLineHeight + kPadding + speakSize.height + kPadding;
    if (quoteSize.height == 0) {
        height += 4 + self.imageViewSize.height;
    } else {
        height += kPadding + quoteSize.height;
    }
    CGFloat width = MAX(quoteSize.width, speakSize.width) + 2 * kPadding;
    CGFloat screenWidth = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    CGFloat minWidth = screenWidth * 0.512;
    width = MAX(minWidth, width);
    return CGSizeMake(width, height);
}

#pragma mark - Private

- (void)drawCornerRadiusWithSize:(CGSize)size {
    UIRectCorner corners = UIRectCornerTopRight|UIRectCornerBottomLeft|UIRectCornerBottomRight;
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

- (CGSize)calculateQuoteImageViewSizeWithImageSize:(CGSize)size {
    if (size.width < size.height) { // 竖图
        CGFloat height = 60;
        CGFloat width = MAX(height * size.width / size.height, 45);
        return CGSizeMake(width, height);
    } else if (size.width > size.height) { // 横图
        CGFloat width = 60;
        CGFloat height = MAX(width * size.height / size.width, 45);
        return CGSizeMake(width, height);
    } else {
        return CGSizeMake(45, 45);
    }
}

- (NSString *)packageURLStringWithHTTPS:(NSString *)urlString {
    while ([urlString hasPrefix:@"/"] || [urlString hasPrefix:@":"]) {
        urlString = [urlString substringFromIndex:1];
    }
    
    NSString *resultString = urlString;
    if ([urlString rangeOfString:@"http"].location == NSNotFound) {
        resultString = [NSString stringWithFormat:@"https://%@", urlString];
    }

    return resultString;
}

@end
