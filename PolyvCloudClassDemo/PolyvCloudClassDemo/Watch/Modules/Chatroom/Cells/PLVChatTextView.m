//
//  PLVChatTextView.m
//  TextViewLink
//
//  Created by MissYasiky on 2019/11/12.
//  Copyright © 2019 MissYasiky. All rights reserved.
//

#import "PLVChatTextView.h"
#import "PCCUtils.h"
#import "PLVEmojiManager.h"

// 我的消息 PLVChatTextView 宽度
static float kMyChatTextViewWidth = 270.0;
// 他人消息 PLVChatTextView 宽度
static float kOtherChatTextViewWidth = 260.0;

// 文本字体大小
static float kChatTextViewFontSize = 14.0;

// 链接文本色号
static NSString *kChatLinkTextColor = @"#0092FA";
// 普通文本色号
static NSString *kChatNormalTextColor = @"#333333";
// 我的消息时背景色号
static NSString *kMyChatBackgroundColor = @"#AFCBEC";
// 他人消息时背景色号
static NSString *kOtherChatBackgroundColor = @"#FFFFFF";

static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";


@interface PLVChatTextView ()

@property (nonatomic, strong) NSDictionary *normalAttributes;
@property (nonatomic, strong) NSDictionary *linkAttributes;

@property (nonatomic, assign) BOOL showingMenu;
@property (nonatomic, assign) NSRange lastSelectedRange;

@end

@implementation PLVChatTextView

#pragma mark - Life Cycle

- (instancetype)initWithMine:(BOOL)mine {
    self = [super init];
    if (self) {
        _mine = mine;
        
        self.backgroundColor = [PCCUtils colorFromHexString:(mine ? kMyChatBackgroundColor : kOtherChatBackgroundColor)];
        self.editable = NO;
        self.scrollEnabled = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.textContainer.lineFragmentPadding = 0;
        self.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
        
        self.normalAttributes = @{NSForegroundColorAttributeName:[PCCUtils colorFromHexString:kChatNormalTextColor],
                                           NSFontAttributeName:[UIFont systemFontOfSize:kChatTextViewFontSize]};
        self.linkAttributes = @{NSForegroundColorAttributeName:[PCCUtils colorFromHexString:kChatLinkTextColor],
                                         NSFontAttributeName:[UIFont systemFontOfSize:kChatTextViewFontSize],
                                NSUnderlineColorAttributeName:[PCCUtils colorFromHexString:kChatLinkTextColor],
                                NSUnderlineStyleAttributeName:@(1)};
    }
    return self;
}

- (instancetype)init {
    return [self initWithMine:NO];
}

#pragma mark - NSNotification

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerWillShow) name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerDidShow) name:UIMenuControllerDidShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerDidHide) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)menuControllerDidHide {
    self.showingMenu = NO;
    [self performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.1];
}

- (void)menuControllerWillShow {
    self.showingMenu = YES;
}

- (void)menuControllerDidShow {
    self.lastSelectedRange = self.selectedRange;
}

#pragma mark - Override

- (BOOL)becomeFirstResponder {
    [self addObserver];
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    if (self.showingMenu || self.lastSelectedRange.location != self.selectedRange.location || self.lastSelectedRange.length != self.selectedRange.length) {
        return NO;
    }
    [self removeObserver];
    return [super resignFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:));
}

#pragma mark - Getter & Setter

- (void)setMine:(BOOL)mine {
    if (_mine == mine) {
        return;
    }
    _mine = mine;
    self.backgroundColor = [PCCUtils colorFromHexString:(mine ? kMyChatBackgroundColor : kOtherChatBackgroundColor)];
}

#pragma mark - Public

- (CGSize)setMessageContent:(NSString *)content admin:(BOOL)admin {

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content];
    [attributedString addAttributes:self.normalAttributes range:NSMakeRange(0, content.length)];
    
    if (admin) { // 将消息中的 url 设置为不同的显示属性
        NSArray *linkRanges = [self linkRangesWithContent:content];
        for (NSTextCheckingResult *result in linkRanges) {
            NSString *originString = [content substringWithRange:result.range];
            NSString *resultString = [self packageURLStringWithHTTPS:originString];
            [attributedString addAttribute:NSLinkAttributeName value:resultString range:result.range];
            [attributedString addAttributes:self.linkAttributes range:result.range];
        }
        self.linkTextAttributes = self.linkAttributes;
    }
    
// 将消息中的 emoji 编码转换为图片
    NSMutableAttributedString *emojiAttributedString = [[PLVEmojiManager sharedManager] convertTextEmotionToAttachmentWithAttributedString:attributedString font:[UIFont systemFontOfSize:kChatTextViewFontSize]];
    self.attributedText = emojiAttributedString;
    
    // 调整 PLVChatTextView 的大小到刚好显示完全部文本
    CGRect originRect = self.frame;
    CGSize newSize = [self sizeThatFits:CGSizeMake((self.mine ? kMyChatTextViewWidth : kOtherChatTextViewWidth), MAXFLOAT)];
    self.frame = CGRectMake(originRect.origin.x, originRect.origin.y, newSize.width, newSize.height);
    
    // 绘制气泡圆角
    [self drawCornerRadiusWithSize:newSize];
    
    return newSize;
}

+ (NSMutableAttributedString *)attributedStringWithContent:(NSString *)content {
    NSMutableAttributedString *attributedString = [[PLVEmojiManager sharedManager] convertTextEmotionToAttachment:content
                                                                                                          font:[UIFont systemFontOfSize:kChatTextViewFontSize]];
    return attributedString;
}

#pragma mark - Private

/// 获得字符串中 https、http 链接所在位置，并将这些结果放入数组中返回
- (NSArray *)linkRangesWithContent:(NSString *)content {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:kFilterRegularExpression options:0 error:nil];
    return [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
}

/// 根据属性 mine 绘制 PLVChatTextView 的外边框
- (void)drawCornerRadiusWithSize:(CGSize)size {
    UIRectCorner corners;
    if (self.mine) {
        corners = UIRectCornerTopLeft|UIRectCornerBottomLeft|UIRectCornerBottomRight;
    } else {
        corners = UIRectCornerTopRight|UIRectCornerBottomLeft|UIRectCornerBottomRight;
    }
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
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
