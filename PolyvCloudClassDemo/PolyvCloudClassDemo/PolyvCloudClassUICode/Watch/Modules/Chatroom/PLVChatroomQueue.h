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

/// 聊天室队列管理器（主要应用于欢迎语队列）
@interface PLVChatroomQueue : NSObject

/// delegate
@property (nonatomic, weak) id<PLVChatroomQueueDeleage> delegate;

/// 退出前必须清空定时器资源
- (void)clearTimer;

/// 入队
- (void)addSocketChatRoomObject:(PLVSocketChatRoomObject *)chatRoomObject me:(BOOL)me;

@end

@protocol PLVChatroomQueueDeleage <NSObject>

/// 出队（由内部定时器决定弹出的策略）
- (void)pop:(PLVChatroomQueue *)queue welcomeMessage:(NSMutableAttributedString *)welcomeMessage;

@end
