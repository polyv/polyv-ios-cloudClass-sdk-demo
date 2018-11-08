//
//  PLVChatroomManager.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2018/11/5.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVChatroomManager.h"

static PLVChatroomManager *manager = nil;

@implementation PLVChatroomManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PLVChatroomManager alloc] init];
    });
    return manager;
}

@end
