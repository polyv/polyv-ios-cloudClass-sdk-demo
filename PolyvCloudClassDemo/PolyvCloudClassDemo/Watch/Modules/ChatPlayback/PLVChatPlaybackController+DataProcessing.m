//
//  PLVChatPlaybackController+DataProcessing.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/8/1.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatPlaybackController.h"
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>
#import <PolyvFoundationSDK/PLVDateUtil.h>
#import "PLVChatPlaybackModel.h"
#import <objc/runtime.h>

@interface PLVChatPlaybackController ()

@property (nonatomic, strong) NSMutableArray *tempArr;

@end

@implementation PLVChatPlaybackController (DataProcessing)

#pragma mark - setter/getter

- (NSMutableArray *)tempArr {
    return objc_getAssociatedObject(self, @"tempArr");
}

- (void)setTempArr:(NSMutableArray *)tempArr {
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

- (void)seekToTime:(NSTimeInterval)newTime {
    [self prepareToLoad:newTime];
    self.playbackData = [NSMutableArray array];
    self.dataArray = [NSMutableArray array];
    [self reloadData];
}

- (void)prepareToLoad:(NSTimeInterval)time {
    NSLog(@"load time: %lf",time);
    if (self.loadingRequest) {
        return;
    }
    self.loadingRequest = YES;
    [self loadDanmuWithTime:time msgId:0];
    self.startTime = time;
    self.tempArr = [[NSMutableArray alloc] init];
}


- (void)loadDanmuWithTime:(NSTimeInterval)newTime msgId:(NSUInteger)msgId {
    NSString *time = [PLVDateUtil secondsToString2:newTime];
    NSUInteger limit = 300;
    __weak typeof(self)weakSelf = self;
    [PLVLiveVideoAPI loadDanmuWithVid:self.vid time:time msgId:msgId limit:limit completion:^(NSArray *danmuArr, NSError *error) {
        if (error) {
            NSLog(@"%s error:%@",__FUNCTION__,error);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf loadDanmuWithTime:newTime msgId:msgId];
            });
        } else {
            if (danmuArr) {
                //NSLog(@"danmuArr: %ld",danmuArr.count);
                if (danmuArr.count == 0) {
                    if (msgId != 0) { // 非首次加载
                        weakSelf.loadingRequest = NO;
                        [weakSelf.playbackData addObjectsFromArray:[weakSelf.tempArr mutableCopy]];
                        [weakSelf reloadData];
                    }
                    return;
                }
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    id lastDanmu = danmuArr.lastObject;
                    if ([lastDanmu isKindOfClass:[NSDictionary class]]) {
                        for (int i = msgId?1:0; i < danmuArr.count; i ++) { // 去重
                            NSDictionary *dict = danmuArr[i];
                            PLVChatPlaybackModel *model = [weakSelf chatModelWithJsonDict:dict];
                            if (model) {
                                if (model.showTime < weakSelf.startTime+300) {
                                    [weakSelf.tempArr addObject:model];
                                } else {
                                    break;
                                }
                            }
                        }
                        
                        NSString *lastTime = [(NSDictionary *)lastDanmu objectForKey:@"time"];
                        NSUInteger lastMsgId = [[(NSDictionary *)lastDanmu objectForKey:@"id"] unsignedIntegerValue];
                        NSUInteger timeInt = [PLVDateUtil secondsToTimeInterval:lastTime];
                        
                        if (danmuArr.count == limit && timeInt < weakSelf.startTime+300) {
                            // 优化首次加载，待测试
//                            if (msgId == 0) { // 首次加载，快速刷新数据
//                                weakSelf.loadingRequest = NO;
//                                [weakSelf.playbackData addObjectsFromArray:[weakSelf.tempArr copy]];
//                                [weakSelf.tempArr removeAllObjects];
//                                dispatch_async(dispatch_get_main_queue(), ^{
//                                    [weakSelf reloadData];
//                                });
//                            }
                            [weakSelf loadDanmuWithTime:timeInt msgId:lastMsgId];
                        } else {
                            weakSelf.loadingRequest = NO;
                            [weakSelf.playbackData addObjectsFromArray:[weakSelf.tempArr mutableCopy]];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf reloadData];
                            });
                        }
                    }
                });
            }
        }
    }];
}

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
    
    [PLVLiveVideoAPI addDanmuWithVid:self.vid msg:msgStr time:[PLVDateUtil secondsToString2:time] sessionId:self.sessionId msgType:msgType user:userJsonStr completion:^(NSDictionary *respondDict, NSError *error) {
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
    model.textContent = [[PLVChatTextContent alloc] initWithText:message];
    
    [self.dataArray addObject:model];
    [self reloadData];
    [self scrollsToBottom:YES];
}

- (PLVChatModel *)addImageModel:(UIImage *)image imgId:(NSString *)imgId time:(NSTimeInterval)time {
    PLVChatPlaybackModel *model = [[PLVChatPlaybackModel alloc] init];
    model.type = PLVChatModelTypeMyImage;
    model.showTime = time;
    model.user = [[PLVChatUser alloc] initWithUserInfo:self.userInfo];
    model.imageContent = [[PLVChatImageContent alloc] initWithImage:image imgId:imgId size:image.size];

    [self.dataArray addObject:model];
    [self reloadData];
    [self scrollsToBottom:YES];
    
    return model;
}

#pragma mark - Private

- (PLVChatPlaybackModel *)chatModelWithJsonDict:(NSDictionary *)jsonDict {
    if (!jsonDict || jsonDict.allKeys.count == 0) {
        return nil;
    }
    NSString *type = [NSString stringWithFormat:@"%@",jsonDict[@"msgType"]];
    if (type) {
        PLVChatPlaybackModel *model = [[PLVChatPlaybackModel alloc] init];
        model.msgId = [jsonDict[@"id"] unsignedIntegerValue];
        model.time = [NSString stringWithFormat:@"%@", jsonDict[@"time"]];
        model.user = [[PLVChatUser alloc] initWithUserInfo:jsonDict[@"user"]];
        if ([type isEqualToString:@"speak"]) {
            model.type = PLVChatModelTypeOtherSpeak;
            model.textContent = [[PLVChatTextContent alloc] initWithText:jsonDict[@"msg"] audience:model.user.isAudience];
        } else if ([type isEqualToString:@"chatImg"]) {
            model.type = PLVChatModelTypeOtherImage;
            NSDictionary *content = jsonDict[@"content"];
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
