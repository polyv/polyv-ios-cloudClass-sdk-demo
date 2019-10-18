//
//  PLVChatroomQueue.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/28.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVChatroomQueue.h"
#import <PolyvBusinessSDK/PolyvBusinessSDK.h>

@interface PLVChatroomQueue ()

@property (nonatomic, strong) PLVSocketChatRoomObject *chatRoomObjectOfMe;
@property (nonatomic, strong) NSMutableArray *welcomeArray;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSUInteger timing;

@end

@implementation PLVChatroomQueue

#pragma mark - life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        self.welcomeArray = [NSMutableArray arrayWithCapacity:10];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(pollOneSecond) userInfo:nil repeats:YES];
        [self.timer fire];
    }
    return self;
}

#pragma mark - public
- (void)clearTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)addSocketChatRoomObject:(PLVSocketChatRoomObject *)chatRoomObject me:(BOOL)me {
    @synchronized (self) {
        if (me) {
            self.chatRoomObjectOfMe = chatRoomObject;
        } else {
            [self.welcomeArray addObject:chatRoomObject];
        }
    }
}

#pragma mark - timer
- (void)popWelcomeMessage:(BOOL)all {
    PLVSocketChatRoomObject *chatRoomObject = [self.welcomeArray lastObject];
    [self.welcomeArray removeLastObject];
    NSString *nickNames = chatRoomObject.jsonDict[PLVSocketIOChatRoom_LOGIN_userKey][PLVSocketIOChatRoomUserNickKey];
    NSUInteger length = nickNames.length;
    if (all) {
        for (NSInteger i = 0; i < 2; i++) {
            chatRoomObject = self.welcomeArray[i];
            nickNames = [nickNames stringByAppendingString:[NSString stringWithFormat:@"、%@", chatRoomObject.jsonDict[PLVSocketIOChatRoom_LOGIN_userKey][PLVSocketIOChatRoomUserNickKey]]];
        }
        length = nickNames.length;
        nickNames = [nickNames stringByAppendingString:[NSString stringWithFormat:@"等%d人", (int)self.welcomeArray.count + 1]];
        [self.welcomeArray removeAllObjects];
    }
    [self pop:nickNames length:length];
}

- (void)pop:(NSString *)nickNames length:(NSUInteger)length {
    NSMutableAttributedString *welcomeMessage = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"欢迎%@加入", nickNames]];
    [welcomeMessage setAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:130.0 / 255.0 green:179.0 / 255.0 blue:201.0 / 255.0 alpha:1.0]} range:NSMakeRange(2, length)];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pop:welcomeMessage:)]) {
        [self.delegate pop:self welcomeMessage:welcomeMessage];
    }
}

- (void)pollOneSecond {
    @synchronized (self) {
        if (self.chatRoomObjectOfMe != nil) {
            NSString *nickNames = self.chatRoomObjectOfMe.jsonDict[PLVSocketIOChatRoom_LOGIN_userKey][PLVSocketIOChatRoomUserNickKey];
            [self pop:nickNames length:nickNames.length];
            self.chatRoomObjectOfMe = nil;
        } else {
            NSUInteger count = self.welcomeArray.count;
            if (count > 0) {
                if ((self.timing++) % 3 == 0) {
                    if (count >= 10) {
                        [self popWelcomeMessage:YES];
                    } else {
                        [self popWelcomeMessage:NO];
                    }
                }
            }
        }
    }
}

@end
