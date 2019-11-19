//
//  PLVChatroomManager.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2018/11/5.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVChatroomManager.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>

static PLVChatroomManager *manager = nil;

@implementation PLVChatroomManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PLVChatroomManager alloc] init];
    });
    return manager;
}

- (void)setLoginUser:(PLVSocketObject *)loginUser {
    _loginUser = loginUser;
    _defaultNick = loginUser.defaultUser;
}

#pragma mark - Public

- (void)renameUserNick:(NSString *)newName {
    if (self.loginUser) {
        _defaultNick = NO;
        [self.loginUser renameNickname:newName];
        [self.socketUser renameNickname:newName];
    }
}

+ (PLVChatroomModel *)modelWithHistoryMessageDict:(NSDictionary *)messageDict {
    PLVChatroomModel *model = nil;
    NSString *msgType = Fd_StringValueWithJsonValue(messageDict[@"msgType"]);
    NSString *msgSource = Fd_StringValueWithJsonValue(messageDict[@"msgSource"]);
    
    if (msgType) {
        if ([msgType isEqualToString:@"customMessage"]) { // 自定义消息
            PLVChatroomCustomModel *customModel = [self modelWithCustomMessage:messageDict mine:NO];
            if (customModel.defined) {
                model = customModel;
            }
        }
    } else if (msgSource) {
        if ([msgSource isEqualToString:@"chatImg"]) { // 图片消息
            NSDictionary *imageDict = @{@"EVENT":@"CHAT_IMG", @"values":@[messageDict[@"content"]], @"user":messageDict[@"user"]};
            PLVSocketChatRoomObject * chatroomObject = [PLVSocketChatRoomObject socketObjectWithJsonDict:imageDict];
            model = [PLVChatroomModel modelWithObject:chatroomObject];
        } // redpaper（红包）、get_redpaper（领红包）
    } else {
        NSString *uid = Fd_StringValueWithJsonValue(messageDict[@"user"][@"uid"]);
        if ([uid isEqualToString:@"1"] || [uid isEqualToString:@"2"]) {
            // uid = 1，打赏消息；uid = 2，自定义消息
        }else { // 发言消息
            NSDictionary *speakDict = @{@"EVENT" : @"SPEAK", @"id" : messageDict[@"id"], @"values" : @[messageDict[@"content"]], @"user" : messageDict[@"user"]};
            PLVSocketChatRoomObject * chatroomObject = [PLVSocketChatRoomObject socketObjectWithJsonDict:speakDict];
            model = [PLVChatroomModel modelWithObject:chatroomObject];
        }
    }
    return model;
}

#pragma mark - 自定义消息处理

+ (PLVChatroomCustomModel *)modelWithCustomMessage:(NSDictionary *)customMessage mine:(BOOL)mine {
    if (!customMessage || ![customMessage isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    PLVChatroomCustomModel *customModel;
    NSString *event = customMessage[@"EVENT"];
    if (Fd_IntegerValueWithJsonValue(customMessage[@"version"]) == 1) {
        if (!mine) {
            // 如果提交的消息广播返回了自己需要过滤掉此消息
            NSString *userId = Fd_StringValueWithJsonValue(customMessage[@"user"][@"userId"]);
            if ([userId isEqualToString:manager.socketUser.userId]) {
                return nil;
            }
        }
        
        // 自定义消息
        if ([event isEqualToString:CUSTOM_EVENT_KOU]) {          // 扣1/2消息
            customModel = [PLVChatroomCustomKouModel modelWithCustomMessage:customMessage];
        } else {
            customModel = [PLVChatroomCustomModel modelWithCustomMessage:customMessage];
        }
    }
    
    if (customModel) {
        customModel.localMessageModel = mine;
    }
    return customModel;
}

@end
