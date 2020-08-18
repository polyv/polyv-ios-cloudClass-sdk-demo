//
//  PLVChatPlaybackController+DataProcessing.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/8/1.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatPlaybackController.h"
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import "PLVChatPlaybackModel.h"
#import <objc/runtime.h>

@interface PLVChatPlaybackController ()

@property (nonatomic, strong) NSMutableArray *tempDataStack;

@end

@implementation PLVChatPlaybackController (DataProcessing)

#pragma mark - setter/getter

- (NSMutableArray *)tempDataStack {
    return objc_getAssociatedObject(self, @"tempArr");
}

- (void)setTempDataStack:(NSMutableArray *)tempArr {
    objc_setAssociatedObject(self, @"tempArr", tempArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - interface

- (void)configUserInfoWithNick:(NSString *)nick pic:(NSString *)pic userId:(NSString *)userId {
    if (!nick || [nick isEqualToString:@""]) {
        nick = [@"手机用户/" stringByAppendingFormat:@"%05d",arc4random() % 100000];
    }
    if (!pic || [pic isEqualToString:@""]) {
        pic = @"https://www.polyv.net/images/effect/effect-device.png";
    }
    if (!userId || [userId isEqualToString:@""]) {
        NSUInteger userIdInt =(NSUInteger)[[NSDate date] timeIntervalSince1970];
        userId = @(userIdInt).stringValue;
    }
    self.userInfo = @{@"nick":nick, @"pic":pic, @"userId":userId, @"userType":@"student"};
}

// 此方法最先调用，保证tempDataStack已初始化
- (void)seekToTime:(NSTimeInterval)newTime {
    if (!self.tempDataStack) {
        self.tempDataStack = [NSMutableArray array];
    }
    
    [self emptyAllData];
    [self prepareToLoad:newTime];
    
    self.isSeekRequest = YES;
}

- (void)prepareToLoad:(NSTimeInterval)time {
    self.isSeekRequest = NO;
    NSLog(@"Load time: %lf",time);
    if (self.loadingRequest) {
        return;
    }
    self.startTime = time;
    self.loadingRequest = YES;
    
    [self loadDanmuWithTime:time msgId:0];
}

- (void)loadDanmuWithTime:(NSTimeInterval)newTime msgId:(NSUInteger)msgId {
    NSUInteger limit = 300;
    NSString *time = [PLVFdUtil secondsToString2:newTime];
    __weak typeof(self)weakSelf = self;
    [PLVLiveVideoAPI loadDanmuWithVid:self.vid time:time msgId:msgId limit:limit completion:^(NSArray *danmuArr, NSError *error) {
        if (error) {
            NSLog(@"%s error:%@",__FUNCTION__,error);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf loadDanmuWithTime:newTime msgId:msgId];
            });
        } else if (danmuArr) {
            //NSLog(@"danmuArr: %ld",danmuArr.count);
            if (danmuArr.count == 0) {
                if (msgId != 0) { // 非首次加载
                    [weakSelf enqueuePlaybackQueue];
                }
                weakSelf.loadingRequest = NO;
                return;
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                id lastDanmu = danmuArr.lastObject;
                if ([lastDanmu isKindOfClass:[NSDictionary class]]) {
                    for (int i = msgId?1:0; i < danmuArr.count; i ++) { // 去重
                        PLVChatPlaybackModel *model = [weakSelf chatModelWithJsonDict:danmuArr[i]];
                        if (model) {
                            if (model.showTime < weakSelf.startTime+300) {
                                [weakSelf.tempDataStack addObject:model];
                            } else {
                                break;
                            }
                        }
                    }
                    
                    NSString *lastTime = [(NSDictionary *)lastDanmu objectForKey:@"time"];
                    NSUInteger lastMsgId = [[(NSDictionary *)lastDanmu objectForKey:@"id"] unsignedIntegerValue];
                    NSUInteger timeInt = [PLVFdUtil secondsToTimeInterval:lastTime];
                    
                    if (danmuArr.count == limit && timeInt < weakSelf.startTime+300) {
                        if (msgId == 0) { // 首次加载，快速刷新数据
                            [weakSelf enqueuePlaybackQueue];
                        }
                        [weakSelf loadDanmuWithTime:timeInt msgId:lastMsgId];
                    } else {
                        weakSelf.loadingRequest = NO;
                        [weakSelf enqueuePlaybackQueue];
                    }
                }
            });
        }
    }];
}

#pragma mark -- data

- (void)emptyAllData {
    [self.tempDataStack removeAllObjects];
    [self.playbackQueue removeAllObjects];
    [self.dataArray removeAllObjects];
    
    [self refreshTableView];
}

- (void)enqueuePlaybackQueue {
    [self.playbackQueue addObjectsFromArray:[self.tempDataStack copy]];
    [self.tempDataStack removeAllObjects];
    
    if (self.isSeekRequest) {
        self.isSeekRequest = NO;
        [self refreshTableView];
    }
}

#pragma mark -- data

- (void)sendMesage:(id)msg time:(NSTimeInterval)time msgType:(NSString *)msgType {
    if (!msg || !msgType) {
        return;
    }
    if (!self.userInfo) {
        NSLog(@"未配置发言用户信息，请调动%@",NSStringFromSelector(_cmd));
        return;
    }
    if (![NSJSONSerialization isValidJSONObject:self.userInfo]) {
        NSLog(@"userInfo 非有效json字符串！");
        return;
    }
    
    NSString *userJsonStr = [self convertToJsonString:self.userInfo];
    if (!userJsonStr) {
        return;
    }
    NSString *msgStr;
    if ([msg isKindOfClass:[NSString class]]) {
        msgStr = msg;
    } else if ([msg isKindOfClass:[NSDictionary class]]) {
        msgStr = [self convertToJsonString:msg];
    }
    
    [PLVLiveVideoAPI addDanmuWithVid:self.vid msg:msgStr time:[PLVFdUtil secondsToString2:time] sessionId:self.sessionId msgType:msgType user:userJsonStr completion:^(NSDictionary *respondDict, NSError *error) {
        if (error) {
            NSLog(@"addDanmu error:%@",error);
        } else {
            NSLog(@"addDanmu success.");
        }
    }];
}

- (void)addSpeakModel:(NSString *)message time:(NSTimeInterval)time {
    PLVChatPlaybackModel *model = [[PLVChatPlaybackModel alloc] init];
    model.type = PLVChatModelTypeMySpeak;
    model.showTime = time;
    model.user = [[PLVChatUser alloc] initWithUserInfo:self.userInfo];
    model.speakContent = message;
    
    [self.dataArray addObject:model];
    [self refreshTableView];
    [self scrollsToBottom:YES];
}

- (PLVChatModel *)addImageModel:(UIImage *)image imgId:(NSString *)imgId time:(NSTimeInterval)time {
    PLVChatPlaybackModel *model = [[PLVChatPlaybackModel alloc] init];
    model.type = PLVChatModelTypeMyImage;
    model.showTime = time;
    model.user = [[PLVChatUser alloc] initWithUserInfo:self.userInfo];
    model.imageContent = [[PLVChatImageContent alloc] initWithImage:image imgId:imgId size:image.size];

    [self.dataArray addObject:model];
    [self refreshTableView];
    [self scrollsToBottom:YES];
    
    return model;
}

#pragma mark - Private

- (PLVChatPlaybackModel *)chatModelWithJsonDict:(NSDictionary *)jsonDict {
    if (!jsonDict || jsonDict.allKeys.count == 0) {
        return nil;
    }
    NSString *type = [NSString stringWithFormat:@"%@", jsonDict[@"msgType"]];
    if (type) {
        PLVChatPlaybackModel *model = [[PLVChatPlaybackModel alloc] init];
        model.msgId = [jsonDict[@"id"] unsignedIntegerValue];
        model.time = [NSString stringWithFormat:@"%@", jsonDict[@"time"]];
        //该消息的发送者
        model.user = [[PLVChatUser alloc] initWithUserInfo:jsonDict[@"user"]];
        //当前登录的用户id
        NSString *currentUserId = self.userInfo[@"userId"];
        if ([type isEqualToString:@"speak"]) {
            model.type = [model.user.userId isEqualToString:currentUserId] ? PLVChatModelTypeMySpeak : PLVChatModelTypeOtherSpeak;
            model.speakContent = jsonDict[@"msg"];
        } else if ([type isEqualToString:@"chatImg"]) {
            model.type = [model.user.userId isEqualToString:currentUserId] ? PLVChatModelTypeMyImage : PLVChatModelTypeOtherImage;
                NSDictionary * content = jsonDict[@"content"];
            if (content && [content isKindOfClass:[NSDictionary class]]) {
                NSDictionary *size = content[@"size"];
                model.imageContent = [[PLVChatImageContent alloc] initWithImage:content[@"uploadImgUrl"] imgId:content[@"id"] size:CGSizeMake([size[@"width"] floatValue], [size[@"height"] floatValue])];
            }
        } else {
            return nil;
        }
        return model;
    } else {
        return nil;
    }
}

- (NSString *)convertToJsonString:(id)object {
    NSData *jsonData = nil;
    NSError *error;
    if (@available(iOS 11.0, *)) {
        // Pass NSJSONWritingSortedKeys if you don't care about the readability of the generated string
        jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                   options:NSJSONWritingSortedKeys
                                                     error:&error];
    } else {
        // format output may be error when server handle, like「 {\n  \"size\" : {\n    \"width\" 」
        jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    }
    if (jsonData) {
        NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        //NSLog(@"dict:%@\nconvertTo:\n%@",object,jsonString);
        return jsonString;
    } else {
        NSLog(@"convertToJson error: %@", error);
        return nil;
    }
}

@end
