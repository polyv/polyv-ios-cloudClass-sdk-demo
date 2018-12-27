//
//  PLVChatroomManager.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2018/11/5.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PolyvBusinessSDK/PLVSocketObject.h>

/// 聊天室管理类
@interface PLVChatroomManager : NSObject

/// 当前用户对象，可能为 nil，使用前需先判断
@property (nonatomic, strong) PLVSocketObject *socketUser;

/// 单例方法
+ (instancetype)sharedManager;

@end
