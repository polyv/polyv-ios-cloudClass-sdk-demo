//
//  PLVChatroomReplyBubble.h
//  PolyvCloudClassDemo
//
//  Created by MissYasiky on 2020/7/8.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatroomModel;

NS_ASSUME_NONNULL_BEGIN

@interface PLVChatroomReplyBubble : UIView

- (CGSize)bubbleSizeWithModel:(PLVChatroomModel *)model speakContentSize:(CGSize)speakSize;

- (void)setModel:(PLVChatroomModel *)model size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
