//
//  PLVChatroomManager.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2018/11/5.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PolyvBusinessSDK/PLVSocketObject.h>

@interface PLVChatroomManager : NSObject

/// 当前用户对象，可能为 nil，使用前需先判断
@property (nonatomic, strong) PLVSocketObject *socketUser;

+ (instancetype)sharedManager;

@end
