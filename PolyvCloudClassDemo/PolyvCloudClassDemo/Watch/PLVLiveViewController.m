//
//  PLVLiveViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVLiveViewController.h"
#import "objc/runtime.h"
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>
#import <PolyvBusinessSDK/PolyvBusinessSDK.h>
#import "PLVNormalLiveMediaViewController.h"
#import "PLVPPTLiveMediaViewController.h"
#import "FTPageController.h"
#import "PLVChatroomManager.h"
#import "PLVChatroomController.h"
#import "PCCUtils.h"
#import "PLVEmojiModel.h"

#define PPTPlayerViewScale (3.0 / 4.0)
#define NormalPlayerViewScale (9.0 / 16.0)
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PLVLiveViewController () <PLVBaseMediaViewControllerDelegate, PLVTriviaCardViewControllerDelegate,  PLVLinkMicControllerDelegate, PLVSocketIODelegate, PLVChatroomDelegate>

@property (nonatomic, assign) NSUInteger channelId;//当前直播的频道号
@property (nonatomic, strong) PLVSocketIO *socketIO;
@property (nonatomic, strong) PLVSocketObject *login;//登录对象

@property (nonatomic, strong) PLVBaseMediaViewController<PLVLiveMediaProtocol> *mediaVC;//播放器控件
@property (nonatomic, strong) PLVTriviaCardViewController *triviaCardVC;//答题卡控件
@property (nonatomic, strong) PLVLinkMicController *linkMicVC;//连麦控件
@property (nonatomic, strong) FTPageController *pageController;
@property (nonatomic, strong) PLVChatroomController *publicChatroomController;
@property (nonatomic, strong) PLVChatroomController *privateChatroomController;
@property (nonatomic, assign) BOOL idleTimerDisabled;

@end

@implementation PLVLiveViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self switchKeyboardMethod];
    self.idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    self.channelId = liveConfig.channelId.integerValue;
    
    __weak typeof(self) weakSelf = self;
    if ([PLVChatroomController havePermissionToWatchLive:self.channelId]) {
        [weakSelf initUI];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf showNoPermissionAlert:@"您未被授权观看本直播"];
        });
    }
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    [UIApplication sharedApplication].idleTimerDisabled = self.idleTimerDisabled;
    Method fromMethod = class_getInstanceMethod(objc_getClass("UIInputWindowController"), @selector(supportedInterfaceOrientations));
    Method toMethod = class_getInstanceMethod([self class], @selector(app_supportedAllInterfaceOrientations));
    method_exchangeImplementations(fromMethod, toMethod);
}

#pragma mark - runtime switch keyboard supportedInterfaceOrientations
- (void)switchKeyboardMethod {//必须，runtime置换UIInputWindowController的supportedInterfaceOrientations方法，防止横屏时，键盘接收到弹出事件崩溃
    Method fromMethod = class_getInstanceMethod(objc_getClass("UIInputWindowController"), @selector(supportedInterfaceOrientations));
    Method toMethod = class_getInstanceMethod([self class], @selector(app_supportedPortraitInterfaceOrientations));
    method_exchangeImplementations(fromMethod, toMethod);
}

- (UIInterfaceOrientationMask)app_supportedPortraitInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientationMask)app_supportedAllInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - init
- (void)initUI {
    CGFloat mediaViewControllerHeight = self.view.bounds.size.width * (self.liveType == PLVLiveViewControllerTypeCloudClass ? PPTPlayerViewScale : NormalPlayerViewScale);
    mediaViewControllerHeight += [UIApplication sharedApplication].statusBarFrame.size.height;
    
    [self addChatRoom:mediaViewControllerHeight];
    [self addMediaViewController:mediaViewControllerHeight];
    
    [self loadChannelMenuInfos];
    [self loadChatroomInfos];
}

- (void)addMediaViewController:(CGFloat)h {
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    CGRect originSecondaryFrame = CGRectZero;
    if (self.liveType == PLVLiveViewControllerTypeCloudClass) {
        self.mediaVC = [[PLVPPTLiveMediaViewController alloc] init];
        CGFloat w = (int)([UIScreen mainScreen].bounds.size.width / 3.0);
        originSecondaryFrame = CGRectMake(self.view.frame.size.width - w, h + 44.0, w, (int)(w * PPTPlayerViewScale));
    } else {
        self.mediaVC = [[PLVNormalLiveMediaViewController alloc] init];
        CGFloat w = (int)([UIScreen mainScreen].bounds.size.width / 3.0);
        originSecondaryFrame = CGRectMake(self.view.frame.size.width - w, h + 44.0, w, (int)(w * NormalPlayerViewScale));
    }
    
    self.mediaVC.delegate = self;
    self.mediaVC.playAD = self.playAD;
    self.mediaVC.channelId = liveConfig.channelId;//必须，不能为空
    self.mediaVC.userId = liveConfig.userId;//必须，不能为空
    self.mediaVC.view.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, h);
    [self.view addSubview:self.mediaVC.view];
    
    self.triviaCardVC = [[PLVTriviaCardViewController alloc] init];
    self.triviaCardVC.delegate = self;
    self.triviaCardVC.view.frame = [UIApplication sharedApplication].delegate.window.bounds;
    [[UIApplication sharedApplication].delegate.window addSubview:self.triviaCardVC.view];
    
    self.linkMicVC = [[PLVLinkMicController alloc] init];
    self.linkMicVC.delegate = self;
    if (self.liveType == PLVLiveViewControllerTypeLive) {
        self.linkMicVC.linkMicType = PLVLinkMicTypeLive;//开启视频连麦时，普通直播的连麦窗口是音频模式
        self.linkMicVC.originSecondaryFrame = CGRectMake(0.0, originSecondaryFrame.origin.y, 60.0, 60.0);
    } else {
        self.linkMicVC.linkMicType = PLVLinkMicTypeCloudClass;//开启视频连麦时，云课堂的是视频模式
        self.linkMicVC.originSecondaryFrame = originSecondaryFrame;
    }
    self.linkMicVC.view.frame = CGRectMake(0.0, self.linkMicVC.originSecondaryFrame.origin.y, self.view.bounds.size.width, self.linkMicVC.originSecondaryFrame.size.height);
    self.linkMicVC.linkMicBtn = self.mediaVC.skinView.linkMicBtn;
    [self.view insertSubview:self.linkMicVC.view belowSubview:self.mediaVC.view];
    
    self.mediaVC.linkMicVC = self.linkMicVC;
    if (self.liveType == PLVLiveViewControllerTypeCloudClass) {
        [(PLVPPTLiveMediaViewController *)self.mediaVC loadSecondaryView:originSecondaryFrame];
    }
}

- (void)addChatRoom:(CGFloat)top {
    CGRect pageCtrlFrame = CGRectMake(0, top, SCREEN_WIDTH, SCREEN_HEIGHT - top);
    CGRect chatroomFrame = CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight);
    
    // public chatroom
    self.publicChatroomController = [PLVChatroomController chatroomWithType:self.liveType == PLVLiveViewControllerTypeLive ? PLVTextInputViewTypeNormalPublic : PLVTextInputViewTypeCloudClassPublic roomId:self.channelId frame:chatroomFrame];
    self.publicChatroomController.delegate = self;
    //self.publicChatroomController.allowToSpeakInTeacherMode = NO;
    [self.publicChatroomController loadSubViews];
    
    self.pageController = [[FTPageController alloc] initWithTitles:@[@"聊天"] controllers:@[self.publicChatroomController]];
    self.pageController.view.backgroundColor = [UIColor colorWithWhite:236/255.0 alpha:1];
    self.pageController.view.frame = pageCtrlFrame;
    [self.view addSubview:self.pageController.view];
    [self addChildViewController:self.pageController];
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {//设备方向旋转，横竖屏切换，但UIViewController不需要旋转，在播放器的父类里自己实现旋转的动画效果
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    if (self.mediaVC.skinView.fullscreen) {//横屏时，隐藏Status Bar
        return YES;
    } else {
        return NO;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {//Status Bar颜色随底色高亮变化
    return UIStatusBarStyleLightContent;
}

#pragma mark - network request
- (void)loadChannelMenuInfos {
    __weak typeof(self)weakSelf = self;
    [PLVLiveVideoAPI getChannelMenuInfos:self.channelId completion:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
        for (PLVLiveVideoChannelMenu *menu in channelMenuInfo.channelMenus) {
            if ([menu.menuType isEqualToString:@"quiz"]) {
                // private chatroom
                weakSelf.privateChatroomController = [PLVChatroomController chatroomWithType:PLVTextInputViewTypePrivate roomId:self.channelId frame:self.publicChatroomController.view.frame];
                weakSelf.privateChatroomController.delegate = weakSelf;
                [weakSelf.privateChatroomController loadSubViews];
                [weakSelf.pageController addPageWithTitle:@"私聊" controller:weakSelf.privateChatroomController];
                break;
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"频道菜单获取失败！%@",error);
    }];
}

- (void)loadChatroomInfos {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI loadChatroomFunctionSwitchWithRoomId:self.channelId completion:^(NSDictionary *switchInfo) {
        PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
        [PLVLiveVideoAPI requestAuthorizationForLinkingSocketWithChannelId:weakSelf.channelId Appld:liveConfig.appId appSecret:liveConfig.appSecret success:^(NSDictionary *responseDict) {
            [weakSelf initSocketIOWithTokenInfo:responseDict];
        } failure:^(NSError *error) {
            [PCCUtils showHUDWithTitle:@"聊天室Token获取失败！" detail:error.localizedDescription view:weakSelf.view];
        }];
        [weakSelf.publicChatroomController setSwitchInfo:switchInfo];
    } failure:^(NSError *error) {
        [PCCUtils showHUDWithTitle:@"聊天室状态获取失败！" detail:error.localizedDescription view:weakSelf.view];
    }];
}

#pragma mark - exit
- (void)exitCurrentController {//退出前释放播放器，连麦，socket资源
    [PCCUtils deviceOnInterfaceOrientationMaskPortrait];
    [self.mediaVC clearResource];
    [self.linkMicVC clearResource];
    [self.publicChatroomController clearResource];
    [self.privateChatroomController clearResource];
    [self clearSocketIO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showNoPermissionAlert:(NSString *)message {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf exitCurrentController];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - SocketIO init / clear
- (void)initSocketIOWithTokenInfo:(NSDictionary *)responseDict {
    self.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:responseDict[@"chat_token"] enableLog:NO];//初始化 socketIO 连接对象
    self.socketIO.delegate = self;
//    self.socketIO.debugMode = YES;
    [self.socketIO connect];
    
    self.login = [PLVSocketObject socketObjectForLoginEventWithRoomId:self.channelId nickName:self.nickName avatar:self.avatarUrl userType:PLVSocketObjectUserTypeSlice];//初始化登录对象，nickName、avatarUrl 为空时会使用默认昵称、头像地址
    self.mediaVC.linkMicVC.login = self.login;
    self.mediaVC.linkMicVC.linkMicParams = responseDict;
}

- (void)clearSocketIO {
    if (self.socketIO) {
        [self.socketIO disconnect];
        [self.socketIO removeAllHandlers];
        self.socketIO = nil;
    }
}

#pragma mark - PLVSocketIODelegate
// 此方法可能多次调用，如锁屏后返回会重连聊天室
- (void)socketIO:(PLVSocketIO *)socketIO didConnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@", NSStringFromSelector(_cmd), info);
    [socketIO emitMessageWithSocketObject:self.login];//登录聊天室
}

- (void)socketIO:(PLVSocketIO *)socketIO didUserStateChange:(PLVSocketUserState)userState {
    NSLog(@"%@--userState:%ld", NSStringFromSelector(_cmd), (long)userState);
    [PCCUtils showChatroomMessage:PLVNameStringWithSocketUserState(userState) addedToView:self.pageController.view];
    if (userState == PLVSocketUserStateLogined) {
        [PLVChatroomManager sharedManager].socketUser = socketIO.user;
        self.publicChatroomController.socketUser = socketIO.user;
        if (self.privateChatroomController) {
            self.privateChatroomController.socketUser = socketIO.user;
        }
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceivePublicChatMessage:(PLVSocketChatRoomObject *)chatObject {
//    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)chatObject.eventType, chatObject.event);
    [self.publicChatroomController addNewChatroomObject:chatObject];
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceivePrivateChatMessage:(PLVSocketChatRoomObject *)chatObject {
//    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)chatObject.eventType, chatObject.event);
    if (self.privateChatroomController) {
        [self.privateChatroomController addNewChatroomObject:chatObject];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveLinkMicMessage:(PLVSocketLinkMicObject *)linkMicObject {
    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)linkMicObject.eventType, linkMicObject.event);
    [self.mediaVC.linkMicVC handleLinkMicObject:linkMicObject];
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceivePPTMessage:(NSString *)json {
    if ([self.mediaVC isKindOfClass:PLVPPTLiveMediaViewController.class]) {
        [(PLVPPTLiveMediaViewController *)self.mediaVC refreshPPT:json];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveQuestionMessage:(NSString *)json result:(int)result {
    if (result == 0) {
        [self.triviaCardVC openQuestionContent:json];
    } else if (result == 1) {
        [self.triviaCardVC openQuestionResult:json];
    } else if (result == 2) {
        [self.triviaCardVC testQuestion:json];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didDisconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PCCUtils showChatroomMessage:@"聊天室失去连接" addedToView:self.pageController.view];
}

- (void)socketIO:(PLVSocketIO *)socketIO connectOnErrorWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PCCUtils showChatroomMessage:@"聊天室连接失败" addedToView:self.pageController.view];
}

- (void)socketIO:(PLVSocketIO *)socketIO reconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PCCUtils showChatroomMessage:@"聊天室重连中..." addedToView:self.pageController.view];
}

- (void)socketIO:(PLVSocketIO *)socketIO localError:(NSString *)description {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),description);
}

#pragma mark - PLVChatroomDelegate
- (void)chatroom:(PLVChatroomController *)chatroom didOpenError:(PLVChatroomErrorCode)code {
    if (code == PLVChatroomErrorCodeBeKicked) {
        [self showNoPermissionAlert:@"您未被授权观看本直播"];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom emitSocketObject:(PLVSocketChatRoomObject *)object {
    if (self.socketIO.socketIOState == PLVSocketIOStateConnected) {
        [self.socketIO emitMessageWithSocketObject:object];
    } else {
        [PCCUtils showChatroomMessage:@"聊天室未连接！" addedToView:self.pageController.view];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom nickNameRenamed:(NSString *)newName success:(BOOL)success message:(NSString *)message {
    [PCCUtils showChatroomMessage:message addedToView:self.pageController.view];
    if (success) {
        self.nickName = newName;
        [self.login renameNickname:newName];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom followKeyboardAnimation:(BOOL)flag {
    CGRect rect = self.view.frame;
    if (!self.mediaVC.skinView.fullscreen) {
        rect.origin.y = flag ? -100.0 : 0.0;//在 PLVTextInputView.m 键盘控件里的 followKeyboardAnimation 方法需要使用 100.0 这个值，两边要一致
        if (flag) {
            rect.size.height = [UIScreen mainScreen].bounds.size.height + 100.0;
        } else {
            rect.size.height = [UIScreen mainScreen].bounds.size.height;
        }
    } else {
        rect.origin.y = 0.0;
    }
    self.view.frame = rect;
    if (flag) {
        CGRect linkMicRect = self.linkMicVC.view.frame;
        linkMicRect = CGRectMake(0.0, self.mediaVC.view.frame.origin.y + self.mediaVC.view.frame.size.height - linkMicRect.size.height, linkMicRect.size.width, linkMicRect.size.height);
        self.linkMicVC.view.frame = linkMicRect;
        [self.mediaVC.view insertSubview:self.linkMicVC.view belowSubview:self.mediaVC.skinView];
    } else {
        self.linkMicVC.view.frame = CGRectMake(0.0, self.linkMicVC.originSecondaryFrame.origin.y, self.view.bounds.size.width, self.linkMicVC.originSecondaryFrame.size.height);
        [self.view insertSubview:self.linkMicVC.view belowSubview:self.mediaVC.view];
    }
    if ([self.mediaVC isKindOfClass:PLVPPTLiveMediaViewController.class]) {
        [(PLVPPTLiveMediaViewController *)self.mediaVC secondaryViewFollowKeyboardAnimation:flag];
    }
}

- (NSString *)currentChannelSessionId:(PLVChatroomController *)chatroom {
    return [self.mediaVC currentChannelSessionId];
}

- (void)chatroom:(PLVChatroomController *)chatroom didSendSpeakContent:(NSString *)content {
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:content font:[UIFont systemFontOfSize:14]];
    [self.mediaVC danmu:attributedStr];
}

#pragma mark - PLVBaseMediaViewControllerDelegate
- (void)quit:(PLVBaseMediaViewController *)mediaVC {
    [self exitCurrentController];
}

- (void)statusBarAppearanceNeedsUpdate:(PLVBaseMediaViewController *)mediaVC {
    [self setNeedsStatusBarAppearanceUpdate];//横竖屏切换前，更新Status Bar的状态
    
    BOOL fullscreen = self.mediaVC.skinView.fullscreen;
    self.triviaCardVC.view.alpha = fullscreen ? 0.0 : 1.0;//横屏时隐藏答题卡
    
    if (fullscreen) {
        [self.publicChatroomController.inputView tapAction];
        [self.privateChatroomController.inputView tapAction];
    }
}

#pragma mark - PLVTriviaCardViewControllerDelegate
- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC chooseAnswer:(NSDictionary *)dict {
    NSString *nickName = self.socketIO.user.nickName;
    NSDictionary *baseJSON = @{@"EVENT" : @"ANSWER_TEST_QUESTION", @"roomId" : [NSString stringWithFormat:@"%lu", (unsigned long)self.socketIO.roomId], @"nick" : nickName, @"userId" : self.socketIO.userId};
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json addEntriesFromDictionary:baseJSON];
    [json addEntriesFromDictionary:dict];
    PLVSocketTriviaCardObject *triviaCard = [PLVSocketTriviaCardObject socketObjectWithJsonDict:json];
    [self.socketIO emitMessageWithSocketObject:triviaCard];
}

#pragma mark - PLVLinkMicControllerDelegate
- (void)linkMicController:(PLVLinkMicController *)lickMic toastTitle:(NSString *)title detail:(NSString *)detail {
    [PCCUtils showHUDWithTitle:title detail:detail view:[UIApplication sharedApplication].delegate.window];
}

- (void)linkMicController:(PLVLinkMicController *)lickMic linkMicStatus:(BOOL)select {
    [self.mediaVC.skinView linkMicStatus:select];
}

- (void)linkMicController:(PLVLinkMicController *)lickMic emitLinkMicObject:(PLVSocketLinkMicEventType)eventType {
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channelId userNick:self.login.nickName userPic:self.login.avatar userId:(NSUInteger)self.login.userId.longLongValue userType:PLVSocketObjectUserTypeSlice];
    [self.socketIO emitMessageWithSocketObject:linkMicObject];
}

- (void)linkMicController:(PLVLinkMicController *)lickMic emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback {
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channelId userNick:self.login.nickName userPic:self.login.avatar userId:(NSUInteger)self.login.userId.longLongValue userType:PLVSocketObjectUserTypeSlice];
    [self.socketIO emitACKWithSocketObject:linkMicObject after:after callback:callback];
}

- (void)linkMicSuccess:(PLVLinkMicController *)lickMic {
    [self.mediaVC linkMicSuccess];
}

- (void)cancelLinkMic:(PLVLinkMicController *)lickMic {
    [self.mediaVC cancelLinkMic];
}

- (void)linkMicSwitchViewAction:(PLVLinkMicController *)lickMic {
    if ([self.mediaVC isKindOfClass:PLVPPTLiveMediaViewController.class]) {
        [(PLVPPTLiveMediaViewController *)self.mediaVC linkMicSwitchViewAction];
    }
}

@end
