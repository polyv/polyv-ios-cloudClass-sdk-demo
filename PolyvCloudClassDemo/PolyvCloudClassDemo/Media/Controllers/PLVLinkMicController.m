//
//  PLVLinkMicController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/10/17.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVLinkMicController.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import <PolyvCloudClassSDK/PLVLivePlayerController.h>
#import <PolyvCloudClassSDK/PLVLiveAPI.h>
#import <PolyvCloudClassSDK/PLVLiveConfig.h>
#import "PLVUtils.h"
#import "PLVAuthorizationManager.h"

typedef NS_ENUM(NSUInteger, PLVLinkMicStatus) {
    PLVLinkMicStatusNone = 0,       //无状态（无连麦）
    PLVLinkMicStatusWait = 1,       //等待发言中（举手中）
    PLVLinkMicStatusJoining = 2,    //连麦中（加入中）
    PLVLinkMicStatusJoin = 3        //发言中（连麦中）
};

@interface PLVLinkMicController () <AgoraRtcEngineDelegate>

@property (nonatomic, assign) BOOL linkMicOnAudio;//记住当前频道讲师开启的连麦类型（YES：声音；NO：视频）
@property (nonatomic, assign) PLVLinkMicStatus linkMicStatus;//当前用户连麦状态
@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;//声网的连麦工具
@property (nonatomic, strong) NSTimer *timer;//定时器，没20秒轮询一次服务器当前频道的连麦信息（状态，连麦列表）,防止sockect重连导致连麦信息丢失而引起当前频道连麦状态不一致的问题
@property (nonatomic, strong) UIScrollView *scrollView;//连麦列表的展示窗口
@property (nonatomic, strong) NSMutableDictionary *linkMicViewDic;//连麦人的关联窗口集合（以声网的userId为key，方便以key来创建新的连麦人窗口）
@property (nonatomic, strong) NSMutableArray *linkMicViewArray;//连麦人的关联窗口集合(避免 linkMicViewDic 导致的先后顺序问题，方便顺序查找连麦人的窗口)
@property (nonatomic, assign) NSUInteger otherIndex;//其他连麦用户的窗口位置排在讲师和自己之后

@end

@implementation PLVLinkMicController

- (void)clearResource {
    [self leaveAgoraRtc];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)viewDidLoad {
    self.view.hidden = YES;
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    self.linkMicViewDic = [[NSMutableDictionary alloc] initWithCapacity:7];
    self.linkMicViewArray = [[NSMutableArray alloc] initWithCapacity:7];
    self.linkMicStatus = PLVLinkMicStatusNone;
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.timer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:weakSelf selector:@selector(onTimeForLickMic) userInfo:nil repeats:YES];
        [weakSelf.timer fire];
    });
}

- (void)handleLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject {
    NSDictionary *jsonDict = linkMicObject.jsonDict;
    switch (linkMicObject.eventType) {
        case PLVSocketLinkMicEventType_OPEN_MICROPHONE: {//教师端/服务器操作（广播消息broadcast）
            if (jsonDict[@"teacherId"]) {
                [self updateRoomLinkMicStatus:jsonDict[@"status"] type:jsonDict[@"type"]];
            } else if ([jsonDict[@"userId"] isEqualToString:self.login.userId]) {//教师端断开学员连麦，该学员接收到广播通知
                [self leaveAgoraRtc];
                [self showEndLinkMicAlert];
            }
            break;
        }
        case PLVSocketLinkMicEventType_TEACHER_INFO: {
            break;
        }
        case PLVSocketLinkMicEventType_MuteUserMedia: {//老师已关闭或打开了你的摄像头或麦克风（单播消息unicast）
            BOOL mute = ((NSNumber *)jsonDict[@"mute"]).boolValue;
            NSString *type = jsonDict[@"type"];
            PLVLinkMicView *linkMicView = [self.linkMicViewDic objectForKey:self.login.userId];
            if ([@"video" isEqualToString:type]) {
                [PLVUtils showHUDWithTitle:mute ? @"摄像头已关闭" : @"摄像头已开启" detail:nil view:[UIApplication sharedApplication].delegate.window];
                [self.agoraKit muteLocalVideoStream:mute];
                linkMicView.videoView.hidden = mute;
            } else {
                [PLVUtils showHUDWithTitle:mute ? @"麦克风已关闭" : @"麦克风已开启" detail:nil view:[UIApplication sharedApplication].delegate.window];
                [self.agoraKit muteLocalAudioStream:mute];
            }
            break;
        }
        case PLVSocketLinkMicEventType_JOIN_RESPONSE: {//老师同意通话事件（单播消息unicast）
            if (self.linkMicStatus == PLVLinkMicStatusWait) {
                [self joinAgoraRtc];
            }
            break;
        }
        default:
            break;
    }
}

- (void)updateRoomLinkMicStatus:(NSString *)status type:(NSString *)type {
    if ([status isEqualToString:@"open"]) {//服务器状态：连麦开启
        self.skinView.linkMicBtn.hidden = NO;
        self.linkMicOnAudio = [type isEqualToString:@"audio"];
    } else {//服务器状态：连麦未开启
        self.skinView.linkMicBtn.hidden = YES;
        switch (self.linkMicStatus) {
            case PLVLinkMicStatusJoin: {//教师端关闭连麦时自己在连麦状态
                [self showEndLinkMicAlert];
            }
            case PLVLinkMicStatusJoining: {//教师端关闭连麦时自己在举手状态
                [self leaveAgoraRtc];
                break;
            }
            default:
                break;
        }
        self.linkMicStatus = PLVLinkMicStatusNone;
    }
}

- (void)showEndLinkMicAlert {
    [PLVUtils showHUDWithTitle:@"老师已结束与您的通话" detail:nil view:[UIApplication sharedApplication].delegate.window];
}

- (void)makeupAgoraKit {
    if (self.agoraKit == nil) {
        self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:self.linkMicParams[@"connect_appId"] delegate:self];
        [self.agoraKit setChannelProfile:AgoraChannelProfileCommunication];
        AgoraVideoEncoderConfiguration *configuration = [[AgoraVideoEncoderConfiguration alloc] init];
        configuration.dimensions = AgoraVideoDimension320x240;
        configuration.orientationMode = AgoraVideoOutputOrientationModeFixedPortrait;
        configuration.bitrate = 200 * 1024 * 1024;
        configuration.frameRate = 15;
        [self.agoraKit setVideoEncoderConfiguration:configuration];
        [self.agoraKit setClientRole:AgoraClientRoleBroadcaster];
    }
}

- (void)joinAgoraRtc {
    self.otherIndex = 2;
    self.linkMicStatus = PLVLinkMicStatusJoining;
    self.skinView.linkMicBtn.enabled = NO;
    [self makeupAgoraKit];
    [self.agoraKit enableVideo];
    if (self.linkMicOnAudio) {
        [self.agoraKit enableLocalVideo:NO];
    } else {
        [self.agoraKit enableLocalVideo:YES];
    }
    [self.agoraKit setDefaultAudioRouteToSpeakerphone:YES];
    
    __weak typeof(self) weakSelf = self;
    NSString *channelId = [NSString stringWithFormat:@"%lu", (unsigned long)self.login.roomId];
    int code = [self.agoraKit joinChannelByToken:self.linkMicParams[@"connect_channel_key"] channelId:channelId info:nil uid:self.login.userId.integerValue joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        NSLog(@"Join rtc success, channel:%@, uid:%lu, elapsed:%ld", channel, (unsigned long)uid, (long)elapsed);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.linkMicStatus = PLVLinkMicStatusJoin;
            weakSelf.skinView.linkMicBtn.enabled = YES;
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            [weakSelf.agoraKit startPreview];
        });
    }];
    if (code != 0) {
        self.skinView.linkMicBtn.enabled = YES;
        [PLVUtils showHUDWithTitle:@"连麦提示：加入失败！" detail:[NSString stringWithFormat:@"Join channel failed: %d", code] view:[UIApplication sharedApplication].delegate.window];
    }
}

- (void)leaveAgoraOK {
    for (PLVLinkMicView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
    [self.linkMicViewDic removeAllObjects];
    [self.linkMicViewArray removeAllObjects];
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.scrollView.bounds.size.height);
    self.view.hidden = YES;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.agoraKit stopPreview];
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelLinkMic:)]) {
        [self.delegate cancelLinkMic:self];
    }
}

- (void)leaveAgoraRtc {
    __weak typeof(self) weakSelf = self;
    [self.agoraKit leaveChannel:^(AgoraChannelStats *stat) {
        [AgoraRtcEngineKit destroy];
        weakSelf.agoraKit = nil;
        [weakSelf leaveAgoraOK];
        [weakSelf emitAck:PLVSocketLinkMicEventType_JOIN_LEAVE callback:^(NSArray *ackArray) {
            weakSelf.linkMicStatus = PLVLinkMicStatusNone;
            weakSelf.skinView.linkMicBtn.enabled = YES;
        }];
    }];
}

- (void)setLinkMicStatus:(PLVLinkMicStatus)status {
    _linkMicStatus = status;
    switch (self.linkMicStatus) {
        case PLVLinkMicStatusNone: {
            [self.skinView linkMicStatus:NO];
            break;
        }
        case PLVLinkMicStatusWait:
        case PLVLinkMicStatusJoining:
        case PLVLinkMicStatusJoin: {
            [self.skinView linkMicStatus:YES];
            break;
        }
        default:
            break;
    }
}

- (void)onTimeForLickMic {
    __weak typeof(self) weakSelf = self;
    [PLVLiveAPI requestLinkMicStatusWithRoomId:self.login.roomId completion:^(NSString *status, NSString *type) {
        [weakSelf updateRoomLinkMicStatus:status type:type];
    } failure:nil];
    
    [PLVLiveAPI requestLinkMicOnlineListWithRoomId:self.login.roomId completion:^(NSDictionary *dict) {
        [weakSelf updateCurrentLinkMicStatus:dict[@"joinList"]];
        [weakSelf updateCurrentLinkMicStatus:dict[@"waitList"]];
//        BOOL findMeOnJoin = [weakSelf updateCurrentLinkMicStatus:dict[@"joinList"]];
//        BOOL findMeOnWait = [weakSelf updateCurrentLinkMicStatus:dict[@"waitList"]];
//        if (!findMeOnJoin && !findMeOnWait && weakSelf.agoraKit != nil) {//当前状态不为None（同时连麦列表中找不到此人）
//            [weakSelf leaveAgoraRtc];//非None状态时更新
//            [PLVUtils showHUDWithTitle:@"连麦列表无当前用户" detail:@"恢复至申请发言状态" view:[UIApplication sharedApplication].delegate.window];
//        }
    } failure:nil];
}

- (BOOL)updateCurrentLinkMicStatus:(NSArray *)linkMicList {
    BOOL findMe = NO;
    for (NSDictionary *userInfo in linkMicList) {
        NSString *userId = userInfo[@"userId"];
        PLVLinkMicView *linkMicView = [self.linkMicViewDic objectForKey:userId];
        if ([userId isEqualToString:self.login.userId]) {//当前用户为自己
            findMe = YES;
            linkMicView.nickNameLabel.text = [NSString stringWithFormat:@"%@(自己)", userInfo[@"nick"]];
        } else {
            linkMicView.nickNameLabel.text = userInfo[@"nick"];
        }
    }
    return findMe;
}

- (void)emitLinkMicObjectWithEventType:(PLVSocketLinkMicEventType)eventType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicController:emitLinkMicObject:)]) {
        [self.delegate linkMicController:self emitLinkMicObject:eventType];
    }
}

- (void)emitAck:(PLVSocketLinkMicEventType)eventType callback:(void (^)(NSArray * _Nonnull))callback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicController:emitAck:after:callback:)]) {
        [self.delegate linkMicController:self emitAck:eventType after:2.0 callback:^(NSArray * ackArray) {
            callback(ackArray);
        }];
    }
}

- (void)linkMic {
    __weak typeof(self) weakSelf = self;
    if (weakSelf.linkMicStatus == PLVLinkMicStatusNone || weakSelf.linkMicStatus == PLVLinkMicStatusWait) {
        if (weakSelf.linkMicStatus == PLVLinkMicStatusNone) {
            [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {//音视频权限处理
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        weakSelf.skinView.linkMicBtn.enabled = NO;
                        [weakSelf emitAck:PLVSocketLinkMicEventType_JOIN_REQUEST callback:^(NSArray *ackArray) {
                            weakSelf.skinView.linkMicBtn.enabled = YES;
                            if (ackArray.count > 0 && [@"joinRequest" isEqualToString:ackArray[0]]) {
                                weakSelf.linkMicStatus = PLVLinkMicStatusWait;
                            }
                        }];
                    } else {
                        [PLVAuthorizationManager showAlertWithTitle:nil message:@"连麦需要获取您的音视频权限，请前往设置" viewController:weakSelf];
                    }
                });
            }];
        } else if (weakSelf.linkMicStatus == PLVLinkMicStatusWait) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认取消连线" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"是的" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                weakSelf.skinView.linkMicBtn.enabled = NO;
                if (weakSelf.linkMicStatus == PLVLinkMicStatusWait) {
                    [weakSelf emitAck:PLVSocketLinkMicEventType_JOIN_LEAVE callback:^(NSArray *ackArray) {
                        weakSelf.skinView.linkMicBtn.enabled = YES;
                        if (ackArray.count > 0 && [@"joinLeave" isEqualToString:ackArray[0]]) {
                            weakSelf.linkMicStatus = PLVLinkMicStatusNone;
                        }
                    }];
                } else {
                    [PLVUtils showHUDWithTitle:@"连麦状态已经改变" detail:nil view:[UIApplication sharedApplication].delegate.window];
                }
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"再等等" style:UIAlertActionStyleCancel handler:nil]];
            [weakSelf presentViewController:alertController animated:YES completion:nil];
        }
    } else if (weakSelf.linkMicStatus == PLVLinkMicStatusJoin) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"挂断当前连线" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"挂断" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            weakSelf.skinView.linkMicBtn.enabled = NO;
            [weakSelf leaveAgoraRtc];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [weakSelf presentViewController:alertController animated:YES completion:nil];
    }
}

//============AgoraRtcEngineDelegate============
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraWarningCode)warningCode {
    NSLog(@"%@, %ld",NSStringFromSelector(_cmd), (long)warningCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"%@, %ld", NSStringFromSelector(_cmd), (long)errorCode);
    [PLVUtils showHUDWithTitle:@"连麦出错！" detail:[NSString stringWithFormat:@"错误码：%ld", (long)errorCode] view:[UIApplication sharedApplication].delegate.window];
    if (errorCode != AgoraErrorCodeLeaveChannelRejected) {
        [self leaveAgoraRtc];
    }
}

- (void)rtcEngineRequestChannelKey:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [PLVLiveAPI requestAuthorizationForLinkingSocketWithChannelId:self.login.roomId Appld:[PLVLiveConfig sharedInstance].appId appSecret:[PLVLiveConfig sharedInstance].appSecret success:^(NSDictionary *responseDict) {
        [engine renewToken:responseDict[@"connect_channel_key"]];
    } failure:^(NSError *error) {
        NSLog(@"ChannelKey获取失败:%ld %@", (long)error.code, error.description);
    }];
}

- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didRejoinChannel:(NSString * _Nonnull)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"%@, uid: %lu", NSStringFromSelector(_cmd), (unsigned long)uid);
}

- (void)rtcEngineCameraDidReady:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)rtcEngineVideoDidStop:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (IBAction)switchCamera:(id)sender {
    [self.agoraKit switchCamera];
}

- (PLVLinkMicView *)addLinkMicView:(NSUInteger)uid remote:(BOOL)remote atIndex:(NSInteger)index {
    NSString *key = @(uid).stringValue;
    PLVLinkMicView *linkMicView = [self.linkMicViewDic objectForKey:key];
    if (linkMicView == nil) {
        CGRect rect = CGRectMake(index * self.originSecondaryFrame.size.width, 0.0, self.originSecondaryFrame.size.width, self.originSecondaryFrame.size.height);
        linkMicView = [[PLVLinkMicView alloc] initWithFrame:rect];
        [linkMicView loadSubViews:self.linkMicOnAudio me:index == 1];
        self.linkMicViewDic[key] = linkMicView;
        if (index < 2) {
            [self.linkMicViewArray insertObject:linkMicView atIndex:index];
        } else {
            [self.linkMicViewArray addObject:linkMicView];
        }
        [self.scrollView addSubview:linkMicView];
        self.scrollView.contentSize = CGSizeMake(self.linkMicViewDic.count * rect.size.width, self.scrollView.bounds.size.height);
        
        if (!self.linkMicOnAudio || index == 0) {
            if (index > 0) {
                [linkMicView.switchCameraBtn addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
            }
            AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
            canvas.uid = uid;
            canvas.view = linkMicView.videoView;
            canvas.renderMode = AgoraVideoRenderModeHidden;
            if (remote) {
                [self.agoraKit setupRemoteVideo:canvas];
            } else {
                [self.agoraKit setupLocalVideo:canvas];
            }
        }
        
        __weak typeof(self) weakSelf = self;
        [PLVLiveAPI requestLinkMicOnlineListWithRoomId:self.login.roomId completion:^(NSDictionary *dict) {
            [weakSelf updateCurrentLinkMicStatus:dict[@"joinList"]];
        } failure:^(NSError *error) {
            [PLVUtils showHUDWithTitle:@"连麦信息获取失败！" detail:error.description view:[UIApplication sharedApplication].delegate.window];
        }];
    }
    return linkMicView;
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    if (uid == self.login.roomId) {
        [self emitLinkMicObjectWithEventType:PLVSocketLinkMicEventType_JOIN_SUCCESS];
        
        self.view.hidden = NO;
        PLVLinkMicView *teacheView = [self addLinkMicView:uid remote:YES atIndex:0];
        teacheView.nickNameLabel.text = @"讲师";
        PLVLinkMicView *myView = [self addLinkMicView:self.login.userId.integerValue remote:NO atIndex:1];
        myView.nickNameLabel.text = @"(自己)";
        if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSuccess:)]) {
            [self.delegate linkMicSuccess:self];
        }
    } else {
        [self addLinkMicView:uid remote:YES atIndex:self.otherIndex++];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    if (uid != self.login.userId.integerValue) {
        NSString *key = @(uid).stringValue;
        PLVLinkMicView *offlineView = [self.linkMicViewDic objectForKey:key];
        [offlineView removeFromSuperview];
        [self.linkMicViewDic removeObjectForKey:key];
        [self.linkMicViewArray removeObject:offlineView];
        for (NSInteger i = 0; i < self.linkMicViewArray.count; i++) {
            CGRect rect = CGRectMake(i * self.originSecondaryFrame.size.width, 0.0, self.originSecondaryFrame.size.width, self.originSecondaryFrame.size.height);
            PLVLinkMicView *view = [self.linkMicViewArray objectAtIndex:i];
            view.frame = rect;
        }
        self.scrollView.contentSize = CGSizeMake(self.linkMicViewDic.count * self.originSecondaryFrame.size.width, self.scrollView.bounds.size.height);
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid {
    
}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid {
    NSString *key = @(uid).stringValue;
    PLVLinkMicView *offlineView = [self.linkMicViewDic objectForKey:key];
    offlineView.videoView.hidden = muted;
}

@end
