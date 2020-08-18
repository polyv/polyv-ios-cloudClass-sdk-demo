//
//  PLVChatTextView.h
//  TextViewLink
//
//  Created by MissYasiky on 2019/11/12.
//  Copyright © 2019 MissYasiky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVChatTextView : UITextView

/// 是否是用来展示自己发出的消息，YES 为是，必须在调用 '-setMessageContent:' 之前设置 mine 的值
@property (nonatomic, assign) BOOL mine;

/// PLVChatTextView 的初始化方法之一
/// 参数 mine 为 YES 表示自己发出的消息，气泡右上角为直角，其余为圆角
/// 参数 mine 为 NO 表示他人发出的消息，气泡左上角为直角，其余为圆角
- (instancetype)initWithMine:(BOOL)mine;

/// PLVChatTextView 的初始化方法之二
/// 参数 reply 为 YES 表示回复他人的消息，默认 mine 为 YES
/// 此时不生成气泡外框，背景色为 clearColor
- (instancetype)initWithReply:(BOOL)reply;

/// 设置消息内容并进行格式转换，返回格式转换后 PLVChatTextView 的大小
/// 参数 admin 为 YES 表示是官方人员（讲师、助教、管理员）发出的消息
/// 参数 admin 为 NO 表示是非官方人员（学员）发出的消息
- (CGSize)setMessageContent:(NSString *)content admin:(BOOL)admin;

+ (NSMutableAttributedString *)attributedStringWithContent:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
