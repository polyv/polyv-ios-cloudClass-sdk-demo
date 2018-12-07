//
//  PLVChatroomQueue.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/28.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PolyvBusinessSDK/PLVSocketObject.h>

@protocol PLVChatroomQueueDeleage;

@interface PLVChatroomQueue : NSObject

@property (nonatomic, weak) id<PLVChatroomQueueDeleage> delegate;

//退出前必须清空定时器资源
- (void)clearTimer;

- (void)addSocketChatRoomObject:(PLVSocketChatRoomObject *)chatRoomObject me:(BOOL)me;

@end

@protocol PLVChatroomQueueDeleage <NSObject>

- (void)pop:(PLVChatroomQueue *)queue welcomeMessage:(NSMutableAttributedString *)welcomeMessage;

@end
