//
//  PLVChatPlaybackModel.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/8/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVChatPlaybackModel : PLVChatModel

@property (nonatomic, assign) NSUInteger msgId;

@property (nonatomic, strong) NSString *time;

@property (nonatomic, assign) NSTimeInterval showTime;

@end

NS_ASSUME_NONNULL_END
