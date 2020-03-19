//
//  PLVLinkMicController.m
//  PolyvCloudClassSDK
//
//  Created by zykhbl on 2018/10/17.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVLinkMicController.h"
#import <PolyvCloudClassSDK/PLVLivePlayerController.h>
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>
#import "PLVLinkMicPenView.h"

#define BackgroundColor [UIColor colorWithWhite:31.0 / 255.0 alpha:1.0]
#define DeviceiPad [@"iPad" isEqualToString:[UIDevice currentDevice].model]

@interface PLVLinkMicController () <PLVLinkMicManagerDelegate, PLVLinkMicViewDelegate, PLVLinkMicPenViewDelegate>

@property (nonatomic, strong) UIView *liveInfoView;//直播间信息
@property (nonatomic, assign) BOOL liveInfoLoaded;//讲师头像和昵称加载完成
@property (nonatomic, strong) UIImageView *avatarImgView;//讲师头像
@property (nonatomic, strong) UILabel *nickNameLabel;//讲师昵称
@property (nonatomic, strong) UIView *spaceLine;//分隔线
@property (nonatomic, strong) UILabel *onLineCountLabel;//在线人数
@property (nonatomic, strong) UIView *controlView;//连麦相关按钮
@property (nonatomic, assign) CGFloat controlHeight;//控制按钮窗口的高度
@property (nonatomic, strong) UIButton *arrowBtn;//切换按钮
@property (nonatomic, strong) UILabel *tipLabel;//连麦状态提示
@property (nonatomic, strong) UIButton *penBtn;//画笔按钮
@property (nonatomic, strong) UIButton *micPhoneBtn;//麦克风控制按钮
@property (nonatomic, strong) UIButton *cameraBtn;//摄像头控制按钮
@property (nonatomic, strong) UIButton *switchCameraBtn;//前后置摄像头切换按钮
@property (nonatomic, strong) UIScrollView *scrollView;//连麦列表的展示窗口
@property (nonatomic, strong) NSMutableDictionary *linkMicViewDic;//连麦人的关联窗口集合
@property (nonatomic, strong) NSMutableArray *linkMicViewArray;//连麦人的关联窗口集合(避免 linkMicViewDic 导致的先后顺序问题，方便顺序查找连麦人的窗口)
@property (nonatomic, assign) int colNum;//一行显示多少列的连麦窗口
@property (nonatomic, strong) PLVLinkMicPenView *penView;//画笔颜色选择器
@property (nonatomic, strong) NSString *permission;//记住当前推流端开启的权限
@property (nonatomic, strong) NSString *speakerUid;//记住授权为讲师的uid
@property (nonatomic, strong) NSMutableArray *viewerArray;//记住当前所有的参与者（允许上麦和未允许的）
@property (nonatomic, strong) NSMutableArray *voiceArray;//记住已经被允许上麦的参与者

@property (nonatomic, assign) NSUInteger teacherId;
@property (nonatomic, strong) PLVLinkMicManager * linkMicManager; // 连麦管理器
@property (nonatomic, strong) NSTimer *timer;//定时器，每20秒轮询一次服务器当前频道的连麦信息（状态，连麦列表）,防止sockect重连导致连麦信息丢失而引起当前频道连麦状态不一致的问题

@property (nonatomic, assign) BOOL linkMicOnAudio;//记住当前频道讲师开启的连麦类型（YES：声音；NO：视频）
@property (nonatomic, assign) BOOL viewerAllow;//讲师端允许viewer上麦的标志位
@property (nonatomic, assign) BOOL idleTimerDisabled;
@property (nonatomic, assign) BOOL liveInfoClose;
@property (nonatomic, assign) BOOL liveInfoFlag;
@property (nonatomic, assign) BOOL linkMicOpen;//讲师端是否开启了连麦

@property (nonatomic, strong) NSTimer *lookAtMeTimer;

@end

@implementation PLVLinkMicController

#pragma mark - [ Life Periods ]
- (void)dealloc{
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if(DeviceiPad) {
            self.colNum = 4;
        } else {
            self.colNum = 3;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = BackgroundColor;
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    self.idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    self.controlHeight = 88.0;
    
    self.teacherId = 0;
    self.linkMicViewDic = [[NSMutableDictionary alloc] initWithCapacity:7];
    self.linkMicViewArray = [[NSMutableArray alloc] initWithCapacity:7];
    
    [self addLiveInfoView];
    [self addControllView];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.autoresizingMask = UIViewAutoresizingNone;
    [self.view addSubview:self.scrollView];
    self.scrollView.hidden = YES;
    
    [self resetLinkMicTopControlFrame:self.secondaryClosed];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(linkMicTimeEvent) userInfo:nil repeats:YES];
    [self.timer fire];
    
    self.viewerArray = [[NSMutableArray alloc] initWithCapacity:5];
    self.voiceArray = [[NSMutableArray alloc] initWithCapacity:5];
}

#pragma mark - [ Public Methods ]
- (void)clearResource {
    self.linkMicManager.delegate = nil;
    [self.linkMicManager leaveRtcChannel];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)handleLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject {
    NSDictionary *jsonDict = linkMicObject.jsonDict;
    switch (linkMicObject.eventType) {
        case PLVSocketLinkMicEventType_OPEN_MICROPHONE: {//教师端/服务器操作（广播消息broadcast）
            if (jsonDict[@"teacherId"]) {
                if (self.teacherId <= 0) {
                    self.teacherId = ((NSString *)jsonDict[@"teacherId"]).integerValue;
                }
                [self updateRoomLinkMicStatus:jsonDict[@"status"] type:jsonDict[@"type"] source:YES];
            } else if ([jsonDict[@"userId"] isEqualToString:self.login.linkMicId] && !self.viewer) {//教师端断开学员连麦，该学员接收到广播通知
                if (self.viewer) {
                    return;
                }
                [self.linkMicManager leaveRtcChannel];
                [self toastTitle:@"老师已结束与您的通话" detail:nil];
            }
            break;
        }
        case PLVSocketLinkMicEventType_TEACHER_INFO: {
            if (self.teacherId <= 0) {
                NSDictionary *data = jsonDict[@"data"];
                self.teacherId = ((NSString *)data[@"userId"]).integerValue;
            }
            break;
        }
        case PLVSocketLinkMicEventType_JOIN_RESPONSE: {//老师同意通话事件（单播消息unicast）
            if (self.linkMicStatus == PLVLinkMicStatusWait) {
                [self joinRTCChannel];
            }
            break;
        }
        case PLVSocketLinkMicEventType_MuteUserMedia: {//老师已关闭或打开了你的摄像头或麦克风（单播消息unicast）
            BOOL mute = ((NSNumber *)jsonDict[@"mute"]).boolValue;
            NSString *type = jsonDict[@"type"];
            if ([@"video" isEqualToString:type]) {
                self.cameraBtn.selected = mute;
            } else {
                self.micPhoneBtn.selected = mute;
            }
            [self mute:self.login.linkMicId.integerValue type:type mute:mute];
            break;
        }
        case PLVSocketLinkMicEventType_SwitchView: {//老师切换连麦人的主副屏位置
            NSString *switchUserId = jsonDict[@"userId"];
            PLVLinkMicView *switchLinkMicView = self.linkMicViewDic[switchUserId];
            
            PLVLinkMicView *linkMicViewOnBig = [self findLinkMicViewOnBig];
            if (linkMicViewOnBig) {
                if (!switchLinkMicView.onBigView) {
                    [self switchLinkMicViewTOMain:switchUserId manualControl:NO];
                }
            } else {
                NSInteger index = [self findIndexOfLinkMicView:switchLinkMicView];
                if (index > 0) {
                    [self swapLinkMicViewToFirst:switchLinkMicView index:index];
                }
            }
            
            break;
        }
        case PLVSocketLinkMIcEventType_TEACHER_SET_PERMISSION: {
            NSString *type = linkMicObject.jsonDict[@"type"];
            NSString *userId = linkMicObject.jsonDict[@"userId"];
            BOOL status = [@"1" isEqualToString:linkMicObject.jsonDict[@"status"]];
            BOOL me = self.login.roomId == ((NSString *)(linkMicObject.jsonDict[@"roomId"])).integerValue && [self.login.linkMicId isEqualToString:userId];
            if (me) {
                self.permission = type;
                if ([@"paint" isEqualToString:self.permission] || [@"speaker" isEqualToString:self.permission]) {
                    BOOL controlPPT = [@"paint" isEqualToString:self.permission] ? NO : status;
                    [self.PPTVC setPaintPermission:status controlPPT:controlPPT];
                    
                    self.penBtn.alpha = status ? 1.0 : 0.0;
                    [self layoutControll];
                    if (self.penBtn.alpha == 0.0) {
                        self.penBtn.selected = YES;
                        [self penAction:self.penBtn];
                        self.permission = nil;
                    } else {
                        self.penBtn.selected = NO;
                        [self penAction:self.penBtn];
                        [self.penView chooseRedPen];
                    }
                    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicController:paint:)]) {
                        [self.delegate linkMicController:self paint:status];
                    }
                }
            }
            if ([@"speaker" isEqualToString:type]) {
                self.speakerUid = status ? userId : @(self.teacherId).stringValue;
                [self refreshSpeakerIcon];
            } else if ([@"voice" isEqualToString:type] && !status && self.linkMicStatus == PLVLinkMicStatusJoin) {
                if (self.viewer && me) {
                    self.viewerAllow = NO;
                    [self.linkMicManager enableLocalAudio:NO];
                    [self.linkMicManager muteLocalVideoStream:YES];
                    [self.linkMicManager switchClientRoleTo:PLVLinkMicRoleAudience];
                    [self didOfflineOfUid:self.login.linkMicId.integerValue];
                    self.penBtn.selected = YES;
                    [self penAction:self.penBtn];
                } else {
                    [self.voiceArray removeObject:userId];
                    [self didOfflineOfUid:userId.integerValue];
                }
            }
            break;
        }
        case PLVSocketLinkMIcEventType_switchJoinVoice: {
            NSString *userId = linkMicObject.jsonDict[@"user"][@"userId"];
            BOOL status = [@"1" isEqualToString:[NSString stringWithFormat:@"%@", linkMicObject.jsonDict[@"status"]]];
            BOOL me = self.login.roomId == ((NSString *)(linkMicObject.jsonDict[@"roomId"])).integerValue && [self.login.linkMicId isEqualToString:userId];
            if (self.linkMicStatus == PLVLinkMicStatusJoin) {
                if (status) {
                    if (self.viewer && me) {
                        [self.linkMicManager switchClientRoleTo:PLVLinkMicRoleBroadcaster];
                        [self openLocalLinkMicForViewer];
                    } else if ([@"viewer" isEqualToString:linkMicObject.jsonDict[@"user"][@"userType"]]) {
                        [self.voiceArray addObject:userId];
                        PLVLinkMicView *linkMicView = [self addLinkMicView:userId.integerValue remote:YES atIndex:-1 linkMicList:nil];
                        linkMicView.viewer = YES;
                    }
                }
            }
            break;
        }
        case PLVSocketLinkMIcEventType_changeVideoAndPPTPosition: {
            BOOL status = [@"1" isEqualToString:((NSNumber *)linkMicObject.jsonDict[@"status"]).stringValue];
            if (self.linkMicViewArray.count == 0) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSwitchViewAction:status:)]) {
                    [self.delegate linkMicSwitchViewAction:self status:status];
                }
            } else {
                NSString *speakerKey = self.speakerUid.length > 0 ? self.speakerUid : @(self.teacherId).stringValue;
                PLVLinkMicView *speakerLinkMicView = self.linkMicViewDic[speakerKey];
                if (status) {
                    if (!speakerLinkMicView.onBigView) {
                        [self switchLinkMicViewTOMain:speakerKey manualControl:NO];
                    }
                } else {
                    PLVLinkMicView *linkMicViewOnBig = [self findLinkMicViewOnBig];
                    if (linkMicViewOnBig) {
                        if (!speakerLinkMicView.onBigView) {
                            [self switchLinkMicViewTOMain:speakerKey manualControl:NO];
                        }
                        if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSwitchViewAction:manualControl:)]) {
                            [self.delegate linkMicSwitchViewAction:self manualControl:NO];
                        }
                    }
                }
            }
            break;
        }
        default:
            break;
    }
}

- (void)hiddenLinkMic:(BOOL)hidden {
    self.view.alpha = hidden ? 0.0 : 1.0;
    self.arrowBtn.alpha = self.viewer ? 0.0 : 1.0;
    
    [self viewerHandle];
    if (self.delegate && [self.delegate respondsToSelector:@selector(changeLinkMicFrame:whitChatroom:)]) {
        [self.delegate changeLinkMicFrame:self whitChatroom:!hidden ? YES : NO];
    }
}

- (void)resetLinkMicFrame:(CGRect)layoutFrame {
    if (self.fullscreen) {
        if (self.orientation == UIDeviceOrientationLandscapeLeft) {
            self.view.frame = CGRectMake(layoutFrame.origin.x, 0.0, self.originSize.width, layoutFrame.size.height);
            self.controlView.frame = CGRectMake(layoutFrame.size.width - self.controlHeight, 0.0, self.controlHeight, layoutFrame.size.height);
        } else if (self.orientation == UIDeviceOrientationLandscapeRight) {
            self.view.frame = CGRectMake(0.0, 0.0, self.originSize.width, layoutFrame.size.height);
            self.controlView.frame = CGRectMake(layoutFrame.size.width - self.controlHeight - layoutFrame.origin.x, 0.0, self.controlHeight, layoutFrame.size.height);
        }
        [self layoutControll];
        self.tipLabel.alpha = 0.0;
    } else {
        self.view.frame = layoutFrame;
        self.tipLabel.alpha = 1.0;
    }
    [self layoutScrollView];
}

- (void)resetLinkMicTopControlFrame:(BOOL)close {
    self.secondaryClosed = close;
    if (!self.fullscreen) {
        CGFloat x = self.secondaryClosed || self.linkMicType != PLVLinkMicTypeCloudClass ? 0.0 : self.originSize.width;
        self.liveInfoView.frame = CGRectMake(x, 0.0, self.view.bounds.size.width - x, self.originSize.height);
        [self refreshLiveInfoFlag:close];
        
        self.controlView.frame = [self makeControlRect];
        [self layoutControll];
        
        self.arrowBtn.frame = [self makeArrowRect];
    }
}

- (void)refreshOnlineCount:(NSUInteger)number {
    self.onLineCountLabel.text = [NSString stringWithFormat:@"在线%lu人", (unsigned long)number];
}

- (void)resetTeacherInfo:(NSString *)avatar nickName:(NSString *)nickName {
    if (!self.liveInfoLoaded) {
        __weak typeof(self) weakSelf = self;
        [PLVFdUtil setImageWithURL:[self picTOHttpURL:avatar] inImageView:self.avatarImgView completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
            weakSelf.liveInfoLoaded = YES;
        }];
    }
    self.nickNameLabel.text = nickName;
}

- (void)updateUser:(NSString *)userId trophyNumber:(NSInteger)trophyNumber {
    if (self.awardTrophyEnabled == NO) {
        return;
    }
    
    PLVLinkMicView *linkMicView = self.linkMicViewDic[userId];
    if (linkMicView) {
        [linkMicView updateTrophyNumber:trophyNumber];
    }
}

#pragma mark Setter
- (void)setViewer:(BOOL)viewer {
    if (![PLVLiveVideoConfig sharedInstance].linkMicStr) {
        NSLog(@"设置参与者失败，需linkMicParams不为空");
        return;
    }
    _viewer = viewer;
    [self viewerHandle];
}

#pragma mark - [ Private Methods ]
- (void)viewerHandle {
    if (self.viewer) {
        if (self.view.alpha == 1.0) {
            if (self.linkMicManager == nil) {
                __weak typeof(self) weakSelf = self;
                [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {//音视频权限处理
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf joinRTCChannel];
                    });
                }];
            }
        } else {
            if (self.linkMicManager != nil) {
                [self.linkMicManager leaveRtcChannel];
            }
        }
    }
}

- (void)createLinkMicManager{
    if (self.linkMicManager == nil) {
        self.linkMicManager = [[PLVLinkMicManager alloc]init];
        self.linkMicManager.delegate = self;
        self.linkMicManager.viewer = self.viewer;
        self.linkMicManager.viewerAllow = self.viewerAllow;
        self.linkMicManager.linkMicOnAudio = self.linkMicOnAudio;
        self.linkMicManager.linkMicType = (PLVLinkMicSceneType)self.linkMicType;
    }
}

- (void)joinRTCChannel{
    self.linkMicBtn.enabled = NO;
    [self createLinkMicManager];
    
    int code = [self.linkMicManager joinRtcChannelWithChannelId:@(self.login.roomId).stringValue userLinkMicId:self.login.linkMicId];
    if (code == 0) {
        self.linkMicStatus = PLVLinkMicStatusJoining;
    }else{
        self.linkMicBtn.enabled = YES;
        [self toastTitle:@"连麦提示：加入失败！" detail:[NSString stringWithFormat:@"Join channel failed: %d", code]];
    }
}

- (void)openLocalLinkMicForViewer{
    if (!self.viewerAllow && self.linkMicManager != nil) {
        self.viewerAllow = YES;
        [self.linkMicManager enableLocalAudio:YES];
        [self.linkMicManager muteLocalVideoStream:NO];
        
        [self addLocalLinkMicView];
    }
}

- (void)didJoinedOfUid:(NSUInteger)uid count:(NSInteger)count after:(CGFloat)after {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:self.login.roomId sessionId:self.sessionId completion:^(NSDictionary *dict) {
            [weakSelf updateTrophyNumber:dict];
            BOOL added = [weakSelf updateCurrentLinkMicList:dict[@"joinList"] joinedOfUid:@(uid).stringValue];
            if (!added && count < 4) {
                [weakSelf didJoinedOfUid:uid count:count + 1 after:after + 2.0];
            }
        } failure:^(NSError *error) { }];
    });
}

- (void)didOfflineOfUid:(NSUInteger)uid {
    if ((self.viewer || uid != self.login.linkMicId.integerValue) && uid != self.teacherId) {
        NSString *key = @(uid).stringValue;
        PLVLinkMicView *offlineView = self.linkMicViewDic[key];
        if (offlineView == nil) {
            return;
        }
        
        NSString *teacherKey = @(self.teacherId).stringValue;
        PLVLinkMicView *speakerView = self.linkMicViewDic[self.speakerUid.length > 0 ? self.speakerUid : teacherKey];
        if (offlineView == speakerView) {
            speakerView = self.linkMicViewDic[teacherKey];
        }
        
        if (offlineView.onBigView) {
            offlineView.onBigView = NO;
            speakerView.onBigView = YES;
            
            NSInteger index = [self findIndexOfLinkMicView:speakerView];
            if (index > 0) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSwitchViewAction:manualControl:)]) {
                    [self.delegate linkMicSwitchViewAction:self manualControl:NO];
                }
                
                [self swapLinkMicViewToFirst:speakerView index:index];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSwitchViewAction:manualControl:)]) {
                    [self.delegate linkMicSwitchViewAction:self manualControl:NO];
                }
            } else {
                NSLog(@"+++++++++++++ SwitchView teacher error +++++++++++++");
            }
        } else {
            NSInteger index = [self findIndexOfLinkMicView:speakerView];
            NSInteger first = [self findIndexOfLinkMicView:offlineView];
            if (first == 0 || index > 0) {
                [self swapLinkMicViewToFirst:speakerView index:index];
            }
        }
        
        [offlineView removeFromSuperview];
        [self.linkMicViewDic removeObjectForKey:key];
        [self.linkMicViewArray removeObject:offlineView];
        [self layoutScrollView];
        
        [self resetPPTPermission];
    }
}

- (void)mute:(NSUInteger)uid type:(NSString *)type mute:(BOOL)mute {
    PLVLinkMicView *linkMicView = [self.linkMicViewDic objectForKey:@(uid).stringValue];
    if (linkMicView) {
        if ([@"video" isEqualToString:type]) {
            NSString *toast = [NSString stringWithFormat:@"%@的%@", linkMicView.nickName, mute ? @"摄像头已关闭" : @"摄像头已开启"];
            [self toastTitle:toast detail:nil];
            linkMicView.videoView.hidden = mute;
            if (linkMicView.onBigView) {
                linkMicView.mainView.superview.backgroundColor = [UIColor colorWithRed:215.0 / 255.0 green:242.0 / 255.0 blue:254.0 / 255.0 alpha:1.0];
            } else {
                linkMicView.mainView.superview.backgroundColor = LinkMicViewBackgroundColor;
            }
            if (self.login.linkMicId.integerValue == uid) {
                [self.linkMicManager muteLocalVideoStream:mute];
            }
        } else {
            NSString *toast = [NSString stringWithFormat:@"%@的%@", linkMicView.nickName, mute ? @"麦克风已关闭" : @"麦克风已开启"];
            [self toastTitle:toast detail:nil];
            linkMicView.micPhoneImgView.hidden = !mute;
            if (self.login.linkMicId.integerValue == uid) {
                [self.linkMicManager muteLocalAudioStream:mute];
                [self.linkMicManager enableLocalAudio:!mute];
            }
        }
    }
}

- (void)resetPPTPermission {
    if (self.linkMicViewArray.count > 0) {
        PLVLinkMicView *linkMicView = self.linkMicViewArray[0];
        if (self.linkMicType == PLVLinkMicTypeCloudClass && ([@"paint" isEqualToString:self.permission] || [@"speaker" isEqualToString:self.permission])) {
            [self.PPTVC setPaintPermission:!linkMicView.onBigView controlPPT:[@"paint" isEqualToString:self.permission] ? NO : !linkMicView.onBigView];
        }
    }
}

- (void)toastTitle:(NSString *)title detail:(NSString *)detail {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicController:toastTitle:detail:)]) {
        [self.delegate linkMicController:self toastTitle:title detail:detail];
    }
}

- (void)presentAlertViewController:(NSString *)title message:(NSString *)message actionBlock:(void (^ __nullable)(void))handler actionTitle:(NSString *)actionTitle cancleTitle:(NSString *)cancleTitle{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:(actionTitle?actionTitle:@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (handler) { handler(); }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:(cancleTitle?cancleTitle:@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (NSURL *)picTOHttpURL:(NSString *)picStr {
    // 处理"//"类型开头的地址和 HTTP 协议地址为 HTTPS
    if ([picStr hasPrefix:@"//"]) {
        picStr = [@"https:" stringByAppendingString:picStr];
    }
    // URL percent-Encoding，头像地址中含有中文字符问题
    picStr = [PLVFdUtil stringBySafeAddingPercentEncoding:picStr];
    return [NSURL URLWithString:picStr];
}

#pragma mark Setter
- (void)setViewerSignalEnabled:(BOOL)viewerSignalEnabled {
    _viewerSignalEnabled = viewerSignalEnabled;
}

- (void)setLinkMicStatus:(PLVLinkMicStatus)status {
    _linkMicStatus = status;
    [self refreshLinkMicBtnStatus];
}

- (void)setLinkMicOnAudio:(BOOL)linkMicOnAudio{
    _linkMicOnAudio = linkMicOnAudio;
    self.linkMicManager.linkMicOnAudio = _linkMicOnAudio;
}

- (void)setViewerAllow:(BOOL)viewerAllow{
    _viewerAllow = viewerAllow;
    self.linkMicManager.viewerAllow = _viewerAllow;
}

- (void)setAwardTrophyEnabled:(BOOL)awardTrophyEnabled {
    if (_awardTrophyEnabled == awardTrophyEnabled) {
        return;
    }
    _awardTrophyEnabled = awardTrophyEnabled;
    for (PLVLinkMicView *linkMicView in self.linkMicViewArray) {
        [linkMicView showTrophy:_awardTrophyEnabled];
    }
}

#pragma mark - [ Add View ]
- (void)addLiveInfoView {
    self.liveInfoView = [[UIView alloc] init];
    [self.view addSubview:self.liveInfoView];
    
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size:DeviceiPad ? 18.0 : 14.0];
    
    // 讲师头像
    self.avatarImgView = [[UIImageView alloc] init];
    self.avatarImgView.clipsToBounds = YES;
    self.avatarImgView.layer.cornerRadius = DeviceiPad ? 30.0 : 20.0;
    [self.liveInfoView addSubview:self.avatarImgView];
    
    // 讲师昵称
    self.nickNameLabel = [[UILabel alloc] init];
    self.nickNameLabel.textColor = [UIColor whiteColor];
    self.nickNameLabel.font = font;
    self.nickNameLabel.numberOfLines = 3;
    [self.liveInfoView addSubview:self.nickNameLabel];
    
    // 竖线
    self.spaceLine = [[UIView alloc] init];
    self.spaceLine.backgroundColor = [UIColor blackColor];
    [self.liveInfoView addSubview:self.spaceLine];
    
    // 在线人数
    self.onLineCountLabel = [[UILabel alloc] init];
    self.onLineCountLabel.textColor = [UIColor whiteColor];
    self.onLineCountLabel.textAlignment = NSTextAlignmentCenter;
    self.onLineCountLabel.font = font;
    self.onLineCountLabel.numberOfLines = 2;
    [self.liveInfoView addSubview:self.onLineCountLabel];
    self.onLineCountLabel.text = @"在线1人";
    
    [self refreshLiveInfoFlag:NO];
}

- (void)addControllView {
    self.controlView = [[UIView alloc] init];
    self.controlView.backgroundColor = BackgroundColor;
    [self.view addSubview:self.controlView];
    
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:DeviceiPad ? 18.0 : 14.0];
    self.tipLabel.textAlignment = NSTextAlignmentRight;
    [self.controlView addSubview:self.tipLabel];
    
    // ‘画笔’按钮
    self.penBtn = [self addButtonOnControlViewWithNormalImgName:@"plv_pen" selectedImgName:@"plv_pened" action:@selector(penAction:)];
    self.penBtn.alpha = 0.0;
    
    // ‘麦克风’按钮
    self.micPhoneBtn = [self addButtonOnControlViewWithNormalImgName:@"plv_closeMicPhone" selectedImgName:@"plv_closeMicPhoned" action:@selector(micAction:)];
    
    // ‘开关摄像头’按钮
    self.cameraBtn = [self addButtonOnControlViewWithNormalImgName:@"plv_closeCamera" selectedImgName:@"plv_closeCameraed" action:@selector(cameraAction:)];
    
    // ‘切换前后摄像头’按钮
    self.switchCameraBtn = [self addButtonOnControlViewWithNormalImgName:@"plv_switchCamera" selectedImgName:@"plv_switchCamera" action:@selector(switchCameraAction:)];
    
    // ‘连麦’按钮
    self.linkMicBtn = [self addButtonOnControlViewWithNormalImgName:nil selectedImgName:nil action:@selector(linkMicAction:)];
    self.linkMicBtn.enabled = NO;
    self.linkMicStatus = PLVLinkMicStatusDisabe;
    
    // ‘看我’按钮
    self.lookAtMeBtn = [self addButtonOnControlViewWithNormalImgName:@"plv_btn_lookAtMe" selectedImgName:nil action:nil];
    [self.lookAtMeBtn addTarget:self action:@selector(lookAtMeAction:) forControlEvents:UIControlEventTouchDown];
    [self.lookAtMeBtn addTarget:self action:@selector(cancelLookAtMeAction:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    self.lookAtMeBtn.alpha = 0.0;
    
    [self hiddenControlBtns:YES];

    // ‘箭头’按钮
    self.arrowBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.arrowBtn setImage:[UIImage imageNamed:@"plv_arrow"] forState:UIControlStateNormal];
    [self.arrowBtn setImage:[UIImage imageNamed:@"plv_arrowed"] forState:UIControlStateSelected];
    [self.arrowBtn addTarget:self action:@selector(showControlView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.arrowBtn];
}

- (UIButton *)addButtonOnControlViewWithNormalImgName:(NSString *)normalImgName selectedImgName:(NSString *)selectedImgName action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (normalImgName && normalImgName.length > 0) {
        [btn setImage:[UIImage imageNamed:normalImgName] forState:UIControlStateNormal];
    }
    if (selectedImgName && selectedImgName.length > 0) {
        [btn setImage:[UIImage imageNamed:selectedImgName] forState:UIControlStateSelected];
    }
    if (action) {
        [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    [self.controlView addSubview:btn];
    return btn;
}

- (void)addLocalLinkMicView {
    PLVLinkMicView * localView = [self addLinkMicView:self.login.linkMicId.integerValue remote:NO atIndex:1 linkMicList:nil];
    localView.nickName = @"自己";
    localView.nickNameLabel.text = @"自己";
    [self emitJoinSuccessSocketMessage];
}

- (PLVLinkMicView *)addLinkMicView:(NSUInteger)uid remote:(BOOL)remote atIndex:(NSInteger)index linkMicList:(NSArray *)linkMicList {
    NSString *key = @(uid).stringValue;
    PLVLinkMicView *linkMicView = self.linkMicViewDic[key];
    if (linkMicView == nil) {
        linkMicView = [[PLVLinkMicView alloc] init];
        linkMicView.delegate = self;
        linkMicView.userId = key;
        linkMicView.frame = CGRectMake(0.0, 0.0, self.originSize.width, self.originSize.height);
        [self.scrollView addSubview:linkMicView];
        
        linkMicView.linkMicType = self.linkMicType;
        [linkMicView loadSubViews:self.linkMicOnAudio teacher:index == 0 me:index == 1 showTrophy:self.awardTrophyEnabled];
        self.linkMicViewDic[key] = linkMicView;
        if (index >= 0) {
            if ([self.linkMicViewArray count] == 0) {
                [self.linkMicViewArray addObject:linkMicView];
            } else {
                [self.linkMicViewArray insertObject:linkMicView atIndex:index];
            }
        } else {
            [self.linkMicViewArray addObject:linkMicView];
        }
        [self resetScrollFrameAndContentSize];
        
        if (((self.linkMicType == PLVLinkMicTypeCloudClass || self.linkMicType == PLVLinkMicTypeNormalLive) && !self.linkMicOnAudio) || index == 0) {
            [self.linkMicManager addRTCCanvasAtSuperView:linkMicView.videoView uid:uid remoteUser:remote];
        }
        
        if (linkMicList != nil) {
            [self updateLinkMicViewNickNameAndAvatar:linkMicList];
        } else {
            __weak typeof(self) weakSelf = self;
            [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:self.login.roomId sessionId:self.sessionId completion:^(NSDictionary *dict) {
                [weakSelf updateTrophyNumber:dict];
                if (uid == weakSelf.teacherId) {
                    [weakSelf updateCurrentLinkMicList:dict[@"joinList"] joinedOfUid:nil];
                } else {
                    [weakSelf updateLinkMicViewNickNameAndAvatar:dict[@"joinList"]];
                }
            } failure:^(NSError *error) { }];
        }
        [self layoutScrollView];
    }
    return linkMicView;
}

#pragma mark - [ Layout ]
- (void)viewWillLayoutSubviews{
    CGSize avatarSize = DeviceiPad ? CGSizeMake(60.0, 60.0) : CGSizeMake(40.0, 40.0);
    self.avatarImgView.frame = CGRectMake((self.liveInfoClose ? 32.0 : 15.0),
                                          (CGRectGetHeight(self.liveInfoView.frame)-avatarSize.height)/2,
                                          avatarSize.width,
                                          avatarSize.height);
    
    CGSize nickNameLabelSize = CGSizeMake((self.view.bounds.size.width - (self.liveInfoFlag ? self.originSize.width : 0.0)) * 0.5 - (avatarSize.width + 16.0), self.originSize.height);
    self.nickNameLabel.frame = CGRectMake(CGRectGetMaxX(self.avatarImgView.frame) + 6.0,
                                          (CGRectGetHeight(self.liveInfoView.frame)-nickNameLabelSize.height)/2,
                                          nickNameLabelSize.width,
                                          nickNameLabelSize.height);
    
    self.spaceLine.frame = CGRectMake(0, 0, 1.0, 16.0);
    self.spaceLine.center = self.liveInfoView.center;
    
    CGSize onLineCountLabelSize = CGSizeMake((self.view.bounds.size.width - (self.liveInfoFlag ? self.originSize.width : 0.0)) * 0.5 - 36.0, self.originSize.height);
    self.onLineCountLabel.frame = CGRectMake(CGRectGetWidth(self.liveInfoView.frame) - 36.0 - onLineCountLabelSize.width,
                                             (CGRectGetHeight(self.liveInfoView.frame)-onLineCountLabelSize.height)/2,
                                             onLineCountLabelSize.width,
                                             onLineCountLabelSize.height);
    
    if (!self.fullscreen) {
        CGSize tipLabelSize = CGSizeMake(self.controlView.bounds.size.width - 108.0, self.originSize.height);
        self.tipLabel.frame = CGRectMake(CGRectGetWidth(self.controlView.frame)-tipLabelSize.width-70.0,
                                         (CGRectGetHeight(self.controlView.frame)-tipLabelSize.height)/2,
                                         tipLabelSize.width,
                                         tipLabelSize.height);
    }
}

- (void)layoutControll {
    NSUInteger count = self.penBtn.alpha == 0.0 ? 5 : 6;
    if (self.viewer) {
        self.linkMicBtn.alpha = 0.0;
        count--;
    } else {
        self.linkMicBtn.alpha = 1.0;
    }
    
    if (self.viewer && self.viewerSignalEnabled) {
        self.lookAtMeBtn.alpha = 1.0;
    } else {
        self.lookAtMeBtn.alpha = 0.0;
        count--;
    }
    
    if (self.linkMicOnAudio) {
        self.cameraBtn.alpha = 0.0;
        count--;
        self.switchCameraBtn.alpha = 0.0;
        count--;
    } else {
        self.cameraBtn.alpha = 1.0;
        self.switchCameraBtn.alpha = 1.0;
    }
    
    if (self.viewer) {
        CGFloat alpha = self.viewerAllow ? 1 : 0;
        self.cameraBtn.alpha = alpha;
        self.switchCameraBtn.alpha = alpha;
        self.micPhoneBtn.alpha = alpha;
    }
    
    CGFloat wh = 48.0;
    if ((self.fullscreen && self.view.bounds.size.height <= 320.0) || (!self.fullscreen && self.view.bounds.size.width <= 320.0)) {
        wh = 36.0;
    }
    CGFloat space = 40.0;
    if(DeviceiPad) {
        space = 50.0;
    }
    if (self.fullscreen) {
        CGFloat dx = (self.controlView.bounds.size.width - wh) * 0.5;
        CGFloat baseY = 40.0;
        CGFloat baseSpace = (self.controlView.bounds.size.height - count * wh - baseY * 2.0) / (count - 1);
        if (baseSpace < space) {
            space = baseSpace;
        }
        CGFloat dy = baseY + (self.controlView.bounds.size.height - count * wh - (count - 1) * space - baseY * 2.0) * 0.5;
        NSUInteger index = 0;
        for (UIView *view in self.controlView.subviews) {
            if ([view isKindOfClass:[UIButton class]] && view.alpha == 1.0) {
                CGRect rect = CGRectMake(dx, dy + index * (wh + space), wh, wh);
                view.frame = rect;
                index++;
            }
        }
        
        if (!self.viewer) {
            if (self.linkMicStatus != PLVLinkMicStatusJoin) {
                self.controlView.alpha = 0.0;
                CGRect linkMicRect = self.linkMicBtn.frame;
                linkMicRect.origin.x = dx + self.controlView.frame.origin.x;
                self.linkMicBtn.frame = linkMicRect;
                [self.view.superview insertSubview:self.linkMicBtn aboveSubview:self.view];
            } else {
                self.controlView.alpha = 1.0;
                if (self.linkMicBtn.superview != self.controlView) {
                    self.linkMicBtn.frame = CGRectMake(dx, dy + index * (wh + space), wh, wh);
                    [self.controlView addSubview:self.linkMicBtn];
                }
            }
        } else {
            self.controlView.alpha = 1.0;
        }
        
        [self.view.superview insertSubview:self.controlView aboveSubview:self.view];
    } else {
        CGFloat baseSpace = (self.controlView.bounds.size.width - count * wh) / (count + 1);
        if (baseSpace < space) {
            space = baseSpace;
        }
        CGFloat dx = (self.controlView.bounds.size.width - count * wh - (count - 1) * space) * 0.5;
        CGFloat dy = self.controlView.bounds.size.height - wh - 40.0;
        NSUInteger index = 0;
        for (UIView *view in self.controlView.subviews) {
            if ([view isKindOfClass:[UIButton class]] && view.alpha == 1.0) {
                CGRect rect = CGRectMake(dx + index * (wh + space), dy, wh, wh);
                view.frame = rect;
                index++;
            }
        }
        
        if (!self.viewer) {
            if (self.linkMicStatus != PLVLinkMicStatusJoin) {
                self.linkMicBtn.frame = CGRectMake(self.controlView.bounds.size.width - wh - 8.0, (self.controlView.bounds.size.height - wh) * 0.5, wh, wh);
            }
            [self.controlView addSubview:self.linkMicBtn];
        }
        
        self.controlView.alpha = 1.0;
        [self.view insertSubview:self.controlView atIndex:1];
    }
    [self refreshLinkMicBtnStatus];
    [self layoutPenView];
    
    self.controlView.hidden = NO;
}

- (void)layoutPenView {
    if (!self.penView.hidden) {
        CGFloat wh = 48.0;
        if (self.fullscreen) {
            self.penView.frame = CGRectMake(self.controlView.frame.origin.x - wh, self.controlView.frame.origin.y, wh, self.controlView.frame.size.height);
            [self.view.superview insertSubview:self.penView aboveSubview:self.controlView];
        } else {
            self.penView.frame = CGRectMake(self.controlView.frame.origin.x, self.controlView.frame.origin.y - wh - 20.0, self.controlView.frame.size.width, wh);
            [self.view insertSubview:self.penView aboveSubview:self.scrollView];
        }
        [self.penView layout:self.fullscreen];
    }
}

- (void)layoutScrollView {
    CGFloat maxHeight = self.originSize.height;
    for (NSInteger index = 0; index < self.linkMicViewArray.count; index++) {
        PLVLinkMicView *linkMicView = [self.linkMicViewArray objectAtIndex:index];
        [self resetLinkMicViewFrame:linkMicView index:index];
        maxHeight = linkMicView.frame.origin.y + linkMicView.frame.size.height;
    }
    [self resetScrollFrameAndContentSize];
}

- (CGRect)makeControlRect {
    if (self.scrollView.hidden) {
        CGFloat controlX = self.arrowBtn.selected ? self.liveInfoView.frame.origin.x : self.view.bounds.size.width;
        CGFloat width = self.secondaryClosed || self.linkMicType != PLVLinkMicTypeCloudClass ? self.view.bounds.size.width : self.view.bounds.size.width - self.originSize.width;
        return CGRectMake(controlX, 0.0, width, self.originSize.height);
    } else {
        return CGRectMake(0.0, self.view.frame.size.height - self.controlHeight, self.view.frame.size.width, self.controlHeight);
    }
}

- (CGRect)makeArrowRect {
    CGFloat arrowX = self.arrowBtn.selected ? self.liveInfoView.frame.origin.x : self.view.bounds.size.width - 36.0;
    return CGRectMake(arrowX, 0.0, 36.0, self.originSize.height);
}

- (void)resetLinkMicViewFrame:(PLVLinkMicView *)linkMicView index:(NSInteger)index {
    NSInteger i = self.linkMicType == PLVLinkMicTypeCloudClass ? index : index - 1;
    if (self.fullscreen) {
        linkMicView.frame = CGRectMake(0.0, i * self.originSize.height, self.originSize.width, self.originSize.height);
    } else {
        linkMicView.frame = CGRectMake((i % self.colNum) * self.originSize.width, (i / self.colNum) * self.originSize.height, self.originSize.width, self.originSize.height);
    }
}

- (void)resetScrollFrameAndContentSize {
    CGFloat maxHeight = self.originSize.height;
    for (NSInteger i = 0; i < self.linkMicViewArray.count; i++) {
        PLVLinkMicView *linkMicView = [self.linkMicViewArray objectAtIndex:i];
        CGFloat height = linkMicView.frame.origin.y + linkMicView.frame.size.height;
        if (maxHeight < height) {
            maxHeight = height;
        }
    }
    if (self.fullscreen) {
        self.scrollView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
        self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, maxHeight);
    } else {
        CGFloat remainHeight = [UIScreen mainScreen].bounds.size.height - self.view.frame.origin.y - self.controlHeight - self.pageBarHeight;
        self.scrollView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.linkMicViewArray.count == 0 ? self.originSize.height : remainHeight);
        self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, maxHeight);
        [self resetViewFrame:self.linkMicViewArray.count == 0 ? self.originSize.height : remainHeight + self.controlHeight];
    }
}

- (void)resetViewFrame:(CGFloat)height {
    CGRect rect = self.view.frame;
    rect.size.height = height;
    self.view.frame = rect;
    
    if (self.scrollView.hidden) {
        self.controlView.frame = [self makeControlRect];
    } else {
        self.controlView.frame = CGRectMake(0.0, rect.size.height - self.controlHeight, rect.size.width, self.controlHeight);
    }
    [self layoutControll];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(changeLinkMicFrame:whitChatroom:)]) {
        [self.delegate changeLinkMicFrame:self whitChatroom:NO];
    }
}

- (void)resetUIAfterLeftRTCChannel {
    self.token = @"";
    [self.linkMicViewDic removeAllObjects];
    [self.linkMicViewArray removeAllObjects];
    
    for (PLVLinkMicView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
    self.scrollView.contentSize = self.scrollView.frame.size;
    self.scrollView.hidden = YES;
    self.penBtn.alpha = 0.0;
    [self hiddenControlOtherBtns:NO];
    [self hiddenControlBtns:YES];
    [self layoutControll];
    [self.PPTVC setPaintPermission:NO controlPPT:NO];
    self.micPhoneBtn.selected = NO;
    self.cameraBtn.selected = NO;
    self.penBtn.selected = YES;
    [self penAction:self.penBtn];
    [self resetViewFrame:self.originSize.height];
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelLinkMic:)]) {
        [self.delegate cancelLinkMic:self];
    }
    [UIApplication sharedApplication].idleTimerDisabled = self.idleTimerDisabled;
}

#pragma mark - [ View Interaction ]
- (PLVLinkMicView *)findLinkMicViewOnBig {
    for (PLVLinkMicView *linkMicView in self.linkMicViewArray) {
        if (linkMicView.onBigView) {
            return linkMicView;
        }
    }
    return nil;
}

- (NSInteger)findIndexOfLinkMicView:(PLVLinkMicView *)v {
    NSInteger index = -1;
    for (PLVLinkMicView *linkMicView in self.linkMicViewArray) {
        index++;
        if (linkMicView == v) {
            break;
        }
    }
    return index;
}

- (void)swapLinkMicViewToFirst:(PLVLinkMicView *)linkMicView index:(NSInteger)index {
    PLVLinkMicView *firstLinkMicView = self.linkMicViewArray[0];
    CGRect firstRect = firstLinkMicView.frame;
    CGRect swapRect = linkMicView.frame;
    firstLinkMicView.frame = swapRect;
    linkMicView.frame = firstRect;
    [self.linkMicViewArray exchangeObjectAtIndex:0 withObjectAtIndex:index];
}

- (void)switchLinkMicViewTOMain:(NSString *)switchUserId manualControl:(BOOL)manualControl {
    PLVLinkMicView *switchLinkMicView = self.linkMicViewDic[switchUserId];
    NSInteger index = [self findIndexOfLinkMicView:switchLinkMicView];
    if (index >= 0) {
        PLVLinkMicView *firstLinkMicView = self.linkMicViewArray[0];
        if (firstLinkMicView.onBigView || firstLinkMicView == switchLinkMicView) {
            firstLinkMicView.onBigView = NO;
            switchLinkMicView.onBigView = YES;
            if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSwitchViewAction:manualControl:)]) {
                [self.delegate linkMicSwitchViewAction:self manualControl:manualControl];
            }
            
            if (firstLinkMicView.onBigView && ![firstLinkMicView.userId isEqualToString:[NSString stringWithFormat:@"%lu",(unsigned long)self.teacherId]]) {
                // 第一窗口位于主屏且不是讲师
                firstLinkMicView.nickNameLabel.hidden = YES;
            }else{
                firstLinkMicView.nickNameLabel.hidden = NO;
            }
        }
        if (firstLinkMicView != switchLinkMicView) {
            [self swapLinkMicViewToFirst:switchLinkMicView index:index];
            if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSwitchViewAction:manualControl:)]) {
                [self.delegate linkMicSwitchViewAction:self manualControl:manualControl];
            }
            
            if (switchLinkMicView.onBigView && ![switchLinkMicView.userId isEqualToString:[NSString stringWithFormat:@"%lu",(unsigned long)self.teacherId]]) {
                // 被点窗口位于主屏且不是讲师
                switchLinkMicView.nickNameLabel.hidden = YES;
            }else{
                switchLinkMicView.nickNameLabel.hidden = NO;
            }
        }
    } else {
        NSLog(@"+++++++++++++ SwitchView error +++++++++++++");
    }
    
    [self resetPPTPermission];
}

- (IBAction)showControlView:(id)sender {
    self.arrowBtn.selected = !self.arrowBtn.selected;
    self.liveInfoView.alpha = 1.0;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.arrowBtn.frame = [weakSelf makeArrowRect];
        weakSelf.controlView.frame = [weakSelf makeControlRect];
        [weakSelf layoutControll];
    } completion:^(BOOL finished) {
        weakSelf.liveInfoView.alpha = weakSelf.arrowBtn.selected ? 0.0 : 1.0;
    }];
}

- (void)hiddenControlBtns:(BOOL)flag {
    self.penBtn.hidden = flag;
    self.micPhoneBtn.hidden = flag;
    self.cameraBtn.hidden = flag;
    self.switchCameraBtn.hidden = flag;
    self.lookAtMeBtn.hidden = flag;
}

- (void)hiddenControlOtherBtns:(BOOL)flag {
    self.liveInfoView.hidden = flag;
    self.arrowBtn.hidden = flag;
    self.tipLabel.hidden = flag;
}

- (void)refreshLiveInfoFlag:(BOOL)close {
    self.liveInfoClose = close;
    BOOL flag = self.linkMicType == PLVLinkMicTypeCloudClass && !close;
    self.liveInfoFlag = flag;
}

- (void)refreshLinkMicBtnStatus {
    if (self.fullscreen) {
        self.linkMicBtn.hidden = self.linkMicStatus == PLVLinkMicStatusDisabe;
    } else {
        self.linkMicBtn.hidden = NO;
    }
    
    switch (self.linkMicStatus) {
        case PLVLinkMicStatusDisabe: {
            self.tipLabel.textColor = [UIColor colorWithWhite:85.0 / 255.0 alpha:1.0];
            self.tipLabel.text = @"讲师尚未开始连线";
            [self.linkMicBtn setImage:[UIImage imageNamed:@"plv_linkMic1_disable"] forState:UIControlStateNormal];
            break;
        }
        case PLVLinkMicStatusNone: {
            self.tipLabel.textColor = [UIColor whiteColor];
            self.tipLabel.text = @"讲师已开始连线";
            [self.linkMicBtn setImage:[UIImage imageNamed:self.fullscreen ? @"plv_linkMic2" : @"plv_linkMic1"] forState:UIControlStateNormal];
            break;
        }
        case PLVLinkMicStatusWait: {
            self.tipLabel.textColor = [UIColor whiteColor];
            self.tipLabel.text = @"请等待讲师允许";
            [self.linkMicBtn setImage:[UIImage imageNamed:self.fullscreen ? @"plv_linkMic2ed" : @"plv_linkMic1ed"] forState:UIControlStateNormal];
            break;
        }
        case PLVLinkMicStatusJoining: {
            self.tipLabel.textColor = [UIColor whiteColor];
            self.tipLabel.text = @"请等待讲师允许";
            [self.linkMicBtn setImage:[UIImage imageNamed:self.fullscreen ? @"plv_linkMic2ed" : @"plv_linkMic1ed"] forState:UIControlStateNormal];
            break;
        }
        case PLVLinkMicStatusJoin: {
            self.tipLabel.textColor = [UIColor whiteColor];
            self.tipLabel.text = @"正在和讲师通话中";
            [self.linkMicBtn setImage:[UIImage imageNamed:@"plv_linkMic2ed"] forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
}

- (void)refreshSpeakerIcon {
    for (PLVLinkMicView *linkMicView in self.linkMicViewArray) {
        if ([linkMicView.userId isEqualToString:self.speakerUid]) {
            linkMicView.permissionImgView.hidden = NO;
            [linkMicView nickNameLabelSizeThatFitsPermission:@"speaker"];
        } else {
            linkMicView.permissionImgView.hidden = YES;
            [linkMicView nickNameLabelSizeThatFitsPermission:nil];
        }
    }
}

- (void)updateRoomLinkMicStatus:(NSString *)status type:(NSString *)type source:(BOOL)socket {
    if (self.viewer) {
        return;
    }
    if ([status isEqualToString:@"open"]) {//服务器状态：连麦开启
        self.linkMicOpen = YES;
        self.linkMicBtn.enabled = YES;
        if (self.linkMicStatus == PLVLinkMicStatusDisabe) {
            self.linkMicStatus = PLVLinkMicStatusNone;
            if (!self.arrowBtn.isSelected) {
                // 讲师打开举手连线且客户端隐藏举手按钮，此时弹出举手按钮（右滑）
                [self showControlView:nil];
            }
        }
        self.linkMicOnAudio = [type isEqualToString:@"audio"];
    } else {//服务器状态：连麦未开启
        self.linkMicOpen = NO;
        switch (self.linkMicStatus) {
            case PLVLinkMicStatusJoin: {//教师端关闭连麦时自己在连麦状态
                [self toastTitle:@"老师已结束与您的通话" detail:nil];
            }
            case PLVLinkMicStatusJoining: {//教师端关闭连麦时自己在举手状态
                [self.linkMicManager leaveRtcChannel];
                break;
            }
            default:
                break;
        }
        self.linkMicBtn.enabled = NO;
        self.linkMicStatus = PLVLinkMicStatusDisabe;
        if (socket && self.arrowBtn.isSelected) {
            // socket 消息，讲师关闭举手连线时举手按钮显示，此时关闭举手（左滑）
            [self showControlView:nil];
        }
    }
}

- (BOOL)updateCurrentLinkMicList:(NSArray *)linkMicList joinedOfUid:(NSString *)uid {
    BOOL added = NO;
    NSString *speakerUserId = nil;
    [self.viewerArray removeAllObjects];
    [self.voiceArray removeAllObjects];
    for (NSDictionary *userInfo in linkMicList) {
        NSString *userId = [NSString stringWithFormat:@"%@", userInfo[@"userId"]]; // userId maybe NSNumber
        NSString *userType = userInfo[@"userType"];
        if (self.teacherId <= 0 && [@"teacher" isEqualToString:userType]) {
            self.teacherId = userId.integerValue;
        }
        
        NSDictionary *classStatus = userInfo[@"classStatus"];
        if (classStatus != nil) {
            NSNumber *speaker = (NSNumber *)classStatus[@"speaker"];
            if (speaker != nil && speaker.integerValue == 1) {
                speakerUserId = userId;
            }
        }
        
        if ([@"viewer" isEqualToString:userType]) {
            [self.viewerArray addObject:userId];
            
            if (classStatus != nil) {
                NSNumber *voice = (NSNumber *)classStatus[@"voice"];
                if (voice != nil && voice.integerValue == 1) {
                    [self.voiceArray addObject:userId];
                }
            }
        } else if (![@"teacher" isEqualToString:userType] && ![userId isEqualToString:self.login.linkMicId]) {
            if (self.linkMicStatus == PLVLinkMicStatusJoin || (self.viewer && self.linkMicManager != nil)) {
                [self addLinkMicView:userId.integerValue remote:YES atIndex:-1 linkMicList:linkMicList];
                if ([userId isEqualToString:uid]) {
                    added = YES;
                }
            }
        }
    }
    
    if (self.linkMicStatus == PLVLinkMicStatusJoin) {
        for (NSString *userId in self.voiceArray) {
            BOOL me = [self.login.linkMicId isEqualToString:userId];
            PLVLinkMicView *linkMicView = [self addLinkMicView:userId.integerValue remote:YES atIndex:me ? 1 : -1 linkMicList:linkMicList];
            linkMicView.viewer = YES;
        }
    }
    
    [self updateLinkMicViewNickNameAndAvatar:linkMicList];
    self.speakerUid = speakerUserId.length > 0 ? speakerUserId : @(self.teacherId).stringValue;
    [self refreshSpeakerIcon];
    
    return added;
}

- (void)updateLinkMicViewNickNameAndAvatar:(NSArray *)linkMicList {
    for (NSDictionary *userInfo in linkMicList) {
        NSString *userId = [NSString stringWithFormat:@"%@", userInfo[@"userId"]]; // userId maybe NSNumber
        NSString *nick = userInfo[@"nick"];
        
        if (self.teacherId == userId.integerValue) {
            [self resetTeacherInfo:userInfo[@"pic"] nickName:nick];
        }
        
        PLVLinkMicView *linkMicView = self.linkMicViewDic[userId];
        if (linkMicView != nil) {
            if (![userId isEqualToString:self.login.linkMicId]) {
                linkMicView.nickName = nick;
                linkMicView.nickNameLabel.text = nick.length <= 4 ? nick : [NSString stringWithFormat:@"%@...", [nick substringToIndex:4]];
            }
        }
    }
}
            
#pragma mark Trophy & Look At Me
- (void)updateTrophyNumber:(NSDictionary *)responseDict {
    NSMutableDictionary *muDict = [[NSMutableDictionary alloc] init];
    
    NSArray *joinList = PLV_SafeArraryForDictKey(responseDict, @"joinList");
    if (joinList && [joinList count] > 0) {
        for (NSDictionary *userDict in joinList) {
            NSString *userId = PLV_SafeStringForDictKey(userDict, @"userId");
            NSInteger cupNum = PLV_SafeIntegerForDictKey(userDict, @"cupNum");
            muDict[userId] = @(cupNum);
        }
    }
    
    NSArray *waitList = PLV_SafeArraryForDictKey(responseDict, @"waitList");
    if (waitList && [waitList count] > 0) {
        for (NSDictionary *userDict in joinList) {
            NSString *userId = PLV_SafeStringForDictKey(userDict, @"userId");
            NSInteger cupNum = PLV_SafeIntegerForDictKey(userDict, @"cupNum");
            muDict[userId] = @(cupNum);
        }
    }
    
    NSDictionary *trophyDict = [muDict copy];
    for (NSString *userId in [trophyDict allKeys]) {
        [self updateUser:userId trophyNumber:[trophyDict[userId] integerValue]];
    }
}

#pragma mark - [ Event ]
- (void)triggerLookAtMeEvent {
    if (self.delegate && [self.delegate respondsToSelector:@selector(lookAtMeWithLinkMicController:)]) {
        [self.delegate lookAtMeWithLinkMicController:self];
    }
}

- (void)linkMicTimeEvent { // 检查连麦在线人数
    if (self.linkMicStatus == PLVLinkMicStatusJoin) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    __weak typeof(self) weakSelf = self;
    BOOL flag = self.teacherId <= 0;
    if (!flag) {
        [PLVLiveVideoAPI requestLinkMicStatusWithRoomId:self.login.roomId completion:^(NSString *status, NSString *type) {
            [weakSelf updateRoomLinkMicStatus:status type:type source:NO];
        } failure:^(NSError *error) {}];
    }
    
    [PLVLiveVideoAPI requestLinkMicOnlineListWithRoomId:self.login.roomId sessionId:self.sessionId completion:^(NSDictionary *dict) {
        [weakSelf updateTrophyNumber:dict];
        [weakSelf updateCurrentLinkMicList:dict[@"joinList"] joinedOfUid:nil];
        if (flag && weakSelf.teacherId > 0) {
            [PLVLiveVideoAPI requestLinkMicStatusWithRoomId:weakSelf.login.roomId completion:^(NSString *status, NSString *type) {
                [weakSelf updateRoomLinkMicStatus:status type:type source:NO];
            } failure:^(NSError *error) {}];
        }
    } failure:^(NSError *error) {}];
}

#pragma mark Action
- (IBAction)penAction:(id)sender {
    if (self.penView == nil) {
        self.penView = [[PLVLinkMicPenView alloc] init];
        self.penView.delegate = self;
        [self.penView addSubViews];
    }
    
    self.penBtn.selected = !self.penBtn.selected;
    self.penView.hidden = !self.penBtn.selected;
    [self layoutPenView];
    
    [self.PPTVC setPaintStatus:self.penBtn.selected ? @"open" : @"close"];
}

- (IBAction)micAction:(id)sender {
    self.micPhoneBtn.selected = !self.micPhoneBtn.selected;
    [self emitMuteSocketMessage:@"audio" mute:self.micPhoneBtn.selected];
}

- (IBAction)cameraAction:(id)sender {
    self.cameraBtn.selected = !self.cameraBtn.selected;
    [self emitMuteSocketMessage:@"video" mute:self.cameraBtn.selected];
}

- (IBAction)switchCameraAction:(id)sender {
    self.switchCameraBtn.selected = !self.switchCameraBtn.selected;
    [self.linkMicManager switchCamera];
}

- (void)linkMicAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    if (self.linkMicStatus == PLVLinkMicStatusNone || self.linkMicStatus == PLVLinkMicStatusWait) {
        if (self.linkMicStatus == PLVLinkMicStatusNone) {
            [PLVAuthorizationManager requestAuthorizationForAudioAndVideo:^(BOOL granted) {//音视频权限处理
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        weakSelf.linkMicBtn.enabled = NO;
                        if (weakSelf.linkMicType == PLVLinkMicTypeLive || weakSelf.linkMicType == PLVLinkMicTypeNormalLive) {
                            [PLVLiveVideoAPI rtcEnabled:[PLVLiveVideoConfig sharedInstance].channelId.integerValue completion:^(BOOL rtcEnabled) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (rtcEnabled) {
                                        weakSelf.linkMicType = PLVLinkMicTypeNormalLive;
                                    } else {
                                        weakSelf.linkMicType = PLVLinkMicTypeLive;
                                    }
                                    
                                    [weakSelf emitJoinRequestSocketMessge];
                                });
                            } failure:^(NSError *error) {
                                weakSelf.linkMicBtn.enabled = YES;
                                weakSelf.linkMicStatus = PLVLinkMicStatusNone;
                                NSLog(@"request rtcEnabled: %@", error);
                            }];
                        } else {
                            [weakSelf emitJoinRequestSocketMessge];
                        }
                    } else {
                        [PLVAuthorizationManager showAlertWithTitle:nil message:@"连麦需要获取您的音视频权限，请前往设置" viewController:weakSelf];
                    }
                });
            }];
        } else if (self.linkMicStatus == PLVLinkMicStatusWait) {
            [self presentAlertViewController:nil message:@"确认取消连线" actionBlock:^{
                weakSelf.linkMicBtn.enabled = NO;
                if (weakSelf.linkMicStatus == PLVLinkMicStatusWait) {
                    [weakSelf emitAck:PLVSocketLinkMicEventType_JOIN_LEAVE callback:^(NSArray *ackArray) {
                        weakSelf.linkMicBtn.enabled = YES;
                        if (ackArray.count > 0 && [@"joinLeave" isEqualToString:ackArray[0]]) {
                            weakSelf.linkMicStatus = PLVLinkMicStatusNone;
                        }
                    }];
                } else {
                    [weakSelf toastTitle:@"连麦状态已经改变" detail:nil];
                }
            } actionTitle:@"是的" cancleTitle:@"再等等"];
        }
    } else if (self.linkMicStatus == PLVLinkMicStatusJoin) {
        [self presentAlertViewController:nil message:@"挂断当前连线" actionBlock:^{
            weakSelf.linkMicBtn.enabled = NO;
            [weakSelf.linkMicManager leaveRtcChannel];
        } actionTitle:@"挂断" cancleTitle:@"取消"];
    }
}

- (void)lookAtMeAction:(id)sender {
    self.lookAtMeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(triggerLookAtMeEvent) userInfo:nil repeats:YES];
    [self.lookAtMeTimer fire];
}

- (void)cancelLookAtMeAction:(id)sender {
    [self.lookAtMeTimer invalidate];
    self.lookAtMeTimer = nil;
}

#pragma mark - [ Socket Handle ]
- (void)emitJoinRequestSocketMessge {
    __weak typeof(self) weakSelf = self;
    [self emitAck:PLVSocketLinkMicEventType_JOIN_REQUEST callback:^(NSArray *ackArray) {
        weakSelf.linkMicBtn.enabled = YES;
        if (ackArray.count > 0 && [@"joinRequest" isEqualToString:ackArray[0]]) {
            weakSelf.linkMicStatus = PLVLinkMicStatusWait;
        }
    }];
}

- (void)emitJoinSuccessSocketMessage{
    __weak typeof(self) weakSelf = self;
    [self emitAck:PLVSocketLinkMicEventType_JOIN_SUCCESS callback:^(NSArray * ackArray) {
        if (ackArray.count > 0) {
            NSString *jsonString = ackArray[0];
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
            if (error == nil && jsonObject) {
                NSDictionary *responseDict = jsonObject;
                weakSelf.token = responseDict[@"token"];
            }
        }
    }];
}

- (void)emitJoinLeaveSocketMessage{
    __weak typeof(self) weakSelf = self;
    [self emitAck:PLVSocketLinkMicEventType_JOIN_LEAVE callback:^(NSArray *ackArray) {
        if (weakSelf.linkMicOpen) {
            weakSelf.linkMicStatus = PLVLinkMicStatusNone;
            weakSelf.linkMicBtn.enabled = YES;
        }else{
            weakSelf.linkMicStatus = PLVLinkMicStatusDisabe;
            weakSelf.linkMicBtn.enabled = NO;
        }
    }];
}

- (void)emitAck:(PLVSocketLinkMicEventType)eventType callback:(void (^)(NSArray * _Nonnull))callback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicController:emitAck:after:callback:)]) {
        [self.delegate linkMicController:self emitAck:eventType after:5.0 callback:^(NSArray * ackArray) {
            callback(ackArray);
        }];
    }
}

- (void)emitMuteSocketMessage:(NSString *)type mute:(BOOL)mute {
    [self mute:self.login.linkMicId.integerValue type:type mute:mute];
    if (self.delegate && [self.delegate respondsToSelector:@selector(emitMuteSocketMessage:type:mute:)]) {
        [self.delegate emitMuteSocketMessage:self.login.linkMicId type:type mute:mute];
    }
}

#pragma mark - [ Delegate ]
#pragma mark PLVLinkMicManagerDelegate
- (void)plvLinkMicManager:(PLVLinkMicManager *)manager joinRTCChannelComplete:(NSString *)channelID uid:(NSUInteger)uid{
    self.linkMicStatus = PLVLinkMicStatusJoin;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.linkMicBtn.enabled = YES;
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager leaveRTCChannelComplete:(NSString * _Nonnull)channelID{
    self.linkMicStatus = PLVLinkMicStatusNone;
    [self resetUIAfterLeftRTCChannel];
    [self emitJoinLeaveSocketMessage];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didOccurError:(NSInteger)errorCode{
    [self toastTitle:@"连麦出错！" detail:[NSString stringWithFormat:@"错误码：%ld", (long)errorCode]];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didJoinedOfUid:(NSUInteger)uid{
    if (uid == self.teacherId) {
        [self hiddenControlOtherBtns:YES];
        [self hiddenControlBtns:NO];
        self.scrollView.hidden = NO;
        
        PLVLinkMicView *teacheView = [self addLinkMicView:uid remote:YES atIndex:0 linkMicList:nil];
        teacheView.nickNameLabel.text = @"讲师";
        teacheView.nickName = @"讲师";
        if (self.speakerUid.length == 0) {
            self.speakerUid = teacheView.userId;
        }
        
        if (!self.viewer) {
            [self addLocalLinkMicView];
        }
        [self refreshSpeakerIcon];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicSuccess:)]) {
            [self.delegate linkMicSuccess:self];
        }
        if (self.fullscreen && self.delegate && [self.delegate respondsToSelector:@selector(changeLinkMicFrame:whitChatroom:)]) {
            [self.delegate changeLinkMicFrame:self whitChatroom:NO];
        }
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [self didJoinedOfUid:uid count:0 after:1.0];
    }
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didOfflineOfUid:(NSUInteger)uid{
    [self didOfflineOfUid:uid];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid{
    [self mute:uid type:@"audio" mute:muted];
}

- (void)plvLinkMicManager:(PLVLinkMicManager *)manager didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid{
    [self mute:uid type:@"video" mute:muted];
}

#pragma mark PLVLinkMicViewDelegate
- (void)switchLinkMicViewAction:(PLVLinkMicView *)linkMicView {
    [self switchLinkMicViewTOMain:linkMicView.userId manualControl:YES];
}

#pragma mark PLVLinkMicPenViewDelegate
- (void)penViewAction:(PLVLinkMicPenView *)penView {
    if (self.penView.penSelectedIndex == 3) {
        [self.PPTVC toDelete];
    } else if (self.penView.penSelectedIndex >= 0 && self.penView.penSelectedIndex <= 2) {
        [self.PPTVC changeColor:self.penView.colorStrArray[self.penView.penSelectedIndex]];
    }
}

@end
