//
//  PLVLiveViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVLiveViewController.h"
#import "objc/runtime.h"
#import <PolyvBusinessSDK/PolyvBusinessSDK.h>
#import "PLVNormalLiveMediaViewController.h"
#import "PLVPPTLiveMediaViewController.h"
#import "FTPageController.h"
#import "PLVChatroomManager.h"
#import "PLVChatroomController.h"
#import "PCCUtils.h"
#import "PLVEmojiManager.h"
#import "PLVLiveInfoViewController.h"

#define PPTPlayerViewScale (9.0 / 16.0)
#define NormalPlayerViewScale (9.0 / 16.0)

@interface PLVLiveViewController () <PLVBaseMediaViewControllerDelegate, PLVTriviaCardViewControllerDelegate,  PLVLinkMicControllerDelegate, PLVSocketIODelegate, PLVChatroomDelegate, FTPageControllerDelegate>

@property (nonatomic, assign) NSUInteger channelId;//当前直播的频道号
@property (nonatomic, strong) PLVSocketIO *socketIO;

@property (nonatomic, strong) PLVBaseMediaViewController<PLVLiveMediaProtocol> *mediaVC;//播放器控件
@property (nonatomic, strong) PLVTriviaCardViewController *triviaCardVC;//答题卡控件
@property (nonatomic, strong) PLVLinkMicController *linkMicVC;//连麦控件
@property (nonatomic, strong) FTPageController *pageController;
@property (nonatomic, strong) PLVLiveInfoViewController *liveInfoViewController;
@property (nonatomic, strong) PLVChatroomController *publicChatroomViewController;
@property (nonatomic, strong) PLVChatroomController *privateChatroomViewController;
@property (nonatomic, assign) CGRect chatroomFrame;
@property (nonatomic, assign) BOOL idleTimerDisabled;
@property (nonatomic, assign) CGFloat mediaViewControllerHeight;
@property (nonatomic, assign) CGSize fullSize;
@property (nonatomic, assign) BOOL movingChatroom;
@property (nonatomic, assign) BOOL moveChatroomUp;

@property (nonatomic, strong) NSTimer *pollingTimer;

@end

@implementation PLVLiveViewController

#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    [UIApplication sharedApplication].idleTimerDisabled = self.idleTimerDisabled;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.fullSize = self.view.frame.size;
    
    self.idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self initData];
    
    [self addMediaViewController];
    [self loadChannelMenuInfos];
    
//    [self playerPolling];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = NO;
    }
}

- (void)playerPolling {
    if (@available(iOS 10.0, *)) {
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"观看时长：%ld，停留时长：%ld", (long)self.mediaVC.player.watchDuration, (long)self.mediaVC.player.stayDuration);
        }];
    }
}

#pragma mark - init
- (void)initData {
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    self.channelId = liveConfig.channelId.integerValue;
    
    PLVSocketObjectUserType userType = self.viewer ? PLVSocketObjectUserTypeViewer : (self.liveType == PLVLiveViewControllerTypeLive ? PLVSocketObjectUserTypeStudent : PLVSocketObjectUserTypeSlice);
    
    /* 初始化登录用户
        1. nickName 为nil时，聊天室首次点击输入栏会弹窗提示输入昵称。可通过设置defaultUser属性为NO屏蔽
        2. 抽奖功能必须固定唯一的 nickName 和 userId，如果忘了填写上次的中奖信息，有固定的 userId 还会再次弹出相关填写页面
     */
    PLVSocketObject *loginUser = [PLVSocketObject socketObjectForLoginWithRoomId:self.channelId nickName:self.nickName avatar:self.avatarUrl userId:nil accountId:[PLVLiveVideoConfig sharedInstance].userId authorization:nil userType:userType];
    loginUser.defaultUser = NO; // 屏蔽聊天室点击输入栏弹窗提示输入昵称
    [PLVChatroomManager sharedManager].loginUser = loginUser;
}

- (void)addMediaViewController {
    self.mediaViewControllerHeight = (int)(self.view.bounds.size.width * (self.liveType == PLVLiveViewControllerTypeCloudClass ? PPTPlayerViewScale : NormalPlayerViewScale));
    self.mediaViewControllerHeight += [UIApplication sharedApplication].statusBarFrame.size.height;
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    PLVSocketObject *loginUser = [PLVChatroomManager sharedManager].loginUser;
    
    if (self.liveType == PLVLiveViewControllerTypeCloudClass) {
        self.mediaVC = [[PLVPPTLiveMediaViewController alloc] init];
    } else {
        self.mediaVC = [[PLVNormalLiveMediaViewController alloc] init];
    }
    
    self.linkMicVC = [[PLVLinkMicController alloc] init];
    self.linkMicVC.delegate = self;
    self.linkMicVC.login = [PLVChatroomManager sharedManager].loginUser;
    if (self.liveType == PLVLiveViewControllerTypeLive) {
        self.linkMicVC.linkMicType = PLVLinkMicTypeNormalLive;//开启视频连麦时，普通直播的连麦窗口是音频模式(旧版推流端)，或者视频模式（新版推流端，对齐云课堂的连麦方式）
    } else {
        self.linkMicVC.linkMicType = PLVLinkMicTypeCloudClass;//开启视频连麦时，云课堂的是视频模式
    }
    
    self.mediaVC.linkMicVC = self.linkMicVC;
    self.mediaVC.delegate = self;
    self.mediaVC.playAD = self.playAD;
    self.mediaVC.channelId = liveConfig.channelId; //必须，不能为空
    self.mediaVC.userId = liveConfig.userId; //必须，不能为空
    self.mediaVC.nickName = loginUser.nickName;
    self.mediaVC.originFrame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.mediaViewControllerHeight);
    self.mediaVC.view.frame = self.mediaVC.originFrame;
    [self.view addSubview:self.mediaVC.view];
    //self.mediaVC.showDanmuOnPortrait = YES; // 竖屏显示弹幕按钮
    
    CGFloat secondaryWidth = (int)([UIScreen mainScreen].bounds.size.width / self.linkMicVC.colNum);
    CGFloat secondaryHeight = (int)(secondaryWidth * PPTPlayerViewScale);
    if (self.liveType == PLVLiveViewControllerTypeCloudClass) {
        self.linkMicVC.secondaryClosed = NO;
        [(PLVPPTLiveMediaViewController *)self.mediaVC loadSecondaryView:CGRectMake(0.0, self.mediaViewControllerHeight, secondaryWidth, secondaryHeight)];
    }
    
    self.linkMicVC.pageBarHeight = 56.0;
    self.linkMicVC.originSize = CGSizeMake(secondaryWidth, secondaryHeight);
    self.linkMicVC.view.frame = CGRectMake(0.0, self.mediaViewControllerHeight, self.view.bounds.size.width, secondaryHeight);
    [self.view insertSubview:self.linkMicVC.view atIndex:0];
    [self.linkMicVC hiddenLinkMic:self.playAD];
    
    // 若需要 [加载静态离线页面]，请解开2处注释代码
    // 1_[加载静态离线页面]
//  NSString *basePath = [NSString stringWithFormat:@"%@/dist", [[NSBundle mainBundle] bundlePath]];
//  NSURL *baseURL = [NSURL fileURLWithPath:basePath isDirectory:YES];
//  NSString *htmlPath = [NSString stringWithFormat:@"%@/index.html", basePath];
//  NSError * htmlError;
//  NSString *htmlString = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:&htmlError];
//  if (htmlError) { NSLog(@"[加载静态离线页面] 错误 Error - %@",htmlError); }
    
    self.triviaCardVC = [[PLVTriviaCardViewController alloc] init];
    self.triviaCardVC.delegate = self;
    
    // 2_[加载静态离线页面]
// self.triviaCardVC.localHtml = htmlString;
// self.triviaCardVC.baseURL = baseURL;
    
    self.triviaCardVC.view.frame = self.view.bounds;
    self.triviaCardVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.triviaCardVC.view];
}

#pragma mark - setup chatroom
- (void)setupChatroomItem {
    CGFloat barHeight = 56.0;
    CGFloat top = self.mediaViewControllerHeight + (self.playAD ? 0.0 : self.linkMicVC.view.frame.size.height);
    CGRect pageCtrlFrame = CGRectMake(0, top, self.fullSize.width, self.fullSize.height - top);
    self.chatroomFrame = CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame) - barHeight);
    
    NSMutableArray *titles = [NSMutableArray new];
    NSMutableArray *controllers = [NSMutableArray new];
    
    for (PLVLiveVideoChannelMenu *menu in self.channelMenuInfo.channelMenus) {
        if ([menu.menuType isEqualToString:@"desc"]) {
            NSString *descTitle = menu.name.length == 0 ? @"直播介绍" : menu.name;
            [self setupLiveInfoViewController:self.channelMenuInfo:menu];
            if (descTitle && self.liveInfoViewController) {
                [titles addObject:descTitle];
                [controllers addObject:self.liveInfoViewController];
            }
        } else if ([menu.menuType isEqualToString:@"chat"]) {
            NSString *chatTitle = menu.name.length == 0 ? @"聊天" : menu.name;
            [self setupPublicChatroomViewController];
            
            if (chatTitle && self.publicChatroomViewController) {
                [titles addObject:chatTitle];
                [controllers addObject:self.publicChatroomViewController];
            }
        } else if ([menu.menuType isEqualToString:@"quiz"]) {
            NSString *quizTitle = menu.name.length == 0 ? @"提问" : menu.name;
            [self setupPrivateChatroomViewController:menu];
            
            if (quizTitle && self.privateChatroomViewController) {
                [titles addObject:quizTitle];
                [controllers addObject:self.privateChatroomViewController];
            }
        }
    }
    
    if (titles.count>0 && controllers.count>0 && titles.count==controllers.count) {
        self.pageController = [[FTPageController alloc] initWithTitles:titles controllers:controllers barHeight:barHeight touchHeight:16.0];
        self.pageController.delegate = self;
        self.pageController.view.frame = pageCtrlFrame;
        [self.view insertSubview:self.pageController.view belowSubview:self.mediaVC.view];  // 需要添加在播放器下面，使得播放器全屏的时候能盖住聊天室
        [self addChildViewController:self.pageController];
        [self.pageController cornerRadius:fabs(top - self.mediaViewControllerHeight) > 1.0];
        self.pageController.touchLineView.hidden = self.playAD;
    }
}

- (void)setupPublicChatroomViewController {
    PLVTextInputViewType type = self.liveType == PLVLiveViewControllerTypeLive ? PLVTextInputViewTypeNormalPublic : PLVTextInputViewTypeCloudClassPublic;
    self.publicChatroomViewController = [PLVChatroomController chatroomWithType:type roomId:self.channelId frame:self.chatroomFrame];
    self.publicChatroomViewController.delegate = self;
//    self.publicChatroomController.allowToSpeakInTeacherMode = NO;
    [self.publicChatroomViewController loadSubViews:self.view];
    
    [self loadChatroomInfos];
}

- (void)setupPrivateChatroomViewController:(PLVLiveVideoChannelMenu *)quizMenu {
    self.privateChatroomViewController = [PLVChatroomController chatroomWithType:PLVTextInputViewTypePrivate roomId:self.channelId frame:self.chatroomFrame];
    self.privateChatroomViewController.delegate = self;
    [self.privateChatroomViewController loadSubViews:self.view];
}

- (void)setupLiveInfoViewController:(PLVLiveVideoChannelMenuInfo *)channelMenuInfo :(PLVLiveVideoChannelMenu *)descMenu {
    self.liveInfoViewController = [[PLVLiveInfoViewController alloc] init];
    self.liveInfoViewController.view.frame = self.chatroomFrame;
    
    [self refreshLiveInfoViewController:channelMenuInfo :descMenu];
}

- (void)refreshLiveInfoViewController:(PLVLiveVideoChannelMenuInfo *)channelMenuInfo :(PLVLiveVideoChannelMenu *)descMenu{
    self.liveInfoViewController.channelMenuInfo = channelMenuInfo;
    self.liveInfoViewController.menu = descMenu;
    [self.liveInfoViewController refreshLiveInfo];
    
    /// 倒计时，如果不需要这个功能，可以先注释掉以下代码
    if (channelMenuInfo.startTime.length > 0 && ![@"live" isEqualToString:channelMenuInfo.watchStatus]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
        NSDate *startTime = [formatter dateFromString:channelMenuInfo.startTime];
        if ([startTime timeIntervalSinceNow] > 0.0) {
            [self.mediaVC loadCountdownTimeLabel:startTime];
        }
    }
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {
    return self.mediaVC != nil && self.mediaVC.canAutorotate && ![PLVLiveVideoConfig sharedInstance].unableRotate && ![PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // 设备为iPhone时，不处理竖屏的UpsideDown方向
    BOOL iPhone = [@"iPhone" isEqualToString:[UIDevice currentDevice].model];
    return iPhone ? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskAll;
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
    if (self.channelMenuInfo) {
        [self setupChatroomItem];
    } else {
        [self getChannelMenuInfosForRefresh:NO];
    }
}

- (void)getChannelMenuInfosForRefresh:(BOOL)refresh{
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI getChannelMenuInfos:self.channelId completion:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
        weakSelf.channelMenuInfo = channelMenuInfo;
        if (refresh) {
            for (PLVLiveVideoChannelMenu *menu in self.channelMenuInfo.channelMenus) {
                if ([menu.menuType isEqualToString:@"desc"]) {
                    [weakSelf refreshLiveInfoViewController:channelMenuInfo :menu];
                    break;
                }
            }
        }else{
            [weakSelf setupChatroomItem];
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
            weakSelf.mediaVC.linkMicVC.linkMicParams = responseDict;
            [weakSelf initSocketIOWithTokenInfo:responseDict];
        } failure:^(NSError *error) {
            [PCCUtils showHUDWithTitle:@"聊天室Token获取失败！" detail:error.localizedDescription view:weakSelf.view];
        }];
        [weakSelf.publicChatroomViewController setSwitchInfo:switchInfo];
    } failure:^(NSError *error) {
        [PCCUtils showHUDWithTitle:@"聊天室状态获取失败！" detail:error.localizedDescription view:weakSelf.view];
    }];
}

#pragma mark - exit
- (void)exitCurrentController {//退出前释放播放器，连麦，socket资源
    [PCCUtils deviceOnInterfaceOrientationMaskPortrait];
    [self.mediaVC clearCountdownTimer];
    [self.mediaVC clearResource];
    [self.linkMicVC clearResource];
    [self.publicChatroomViewController clearResource];
    [self.privateChatroomViewController clearResource];
    [self clearSocketIO];
    if (self.pollingTimer) {
        [self.pollingTimer invalidate];
        self.pollingTimer = nil;
    }
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)exitCurrentControllerWithAlert:(NSString *)title message:(NSString *)message {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf exitCurrentController];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - SocketIO init / clear
- (void)initSocketIOWithTokenInfo:(NSDictionary *)responseDict {
    if (self.socketIO) {
        return;
    }
    self.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:responseDict[@"chat_token"] url:nil enableLog:NO];//初始化 socketIO 连接对象
    self.socketIO.delegate = self;
    [self.socketIO connect];
//  self.socketIO.debugMode = YES;
}

- (void)clearSocketIO {
    if (self.socketIO) {
        [self.socketIO disconnect];
        [self.socketIO removeAllHandlers];
        self.socketIO = nil;
    }
}

#pragma mark - PLVSocketIODelegate
- (void)socketIO:(PLVSocketIO *)socketIO didLoginFailed:(NSDictionary *)jsonDict {
    NSLog(@"%s %@",__FUNCTION__,jsonDict);
    [socketIO disconnect];
    [self exitCurrentControllerWithAlert:nil message:@"您未被授权观看本直播"];
}

// 此方法可能多次调用，如锁屏后返回会重连聊天室
- (void)socketIO:(PLVSocketIO *)socketIO didConnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@", NSStringFromSelector(_cmd), info);
    [socketIO emitMessageWithSocketObject:[PLVChatroomManager sharedManager].loginUser];//登录聊天室
}

- (void)socketIO:(PLVSocketIO *)socketIO didUserStateChange:(PLVSocketUserState)userState {
    NSLog(@"%@--userState:%ld", NSStringFromSelector(_cmd), (long)userState);
    [PCCUtils showChatroomMessage:PLVNameStringWithSocketUserState(userState) addedToView:self.pageController.view];
    if (userState == PLVSocketUserStateLogined) {
        PLVSocketObject *socketObject = socketIO.user;
        socketObject.accountId = [PLVLiveVideoConfig sharedInstance].userId; // 当前需要
        [PLVChatroomManager sharedManager].socketUser = socketObject;
    }
}

#pragma mark Socket message
- (void)socketIO:(PLVSocketIO *)socketIO didReceivePublicChatMessage:(PLVSocketChatRoomObject *)chatObject {
//    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)chatObject.eventType, chatObject.event);
    [self.publicChatroomViewController addNewChatroomObject:chatObject];
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceivePrivateChatMessage:(PLVSocketChatRoomObject *)chatObject {
//    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)chatObject.eventType, chatObject.event);
    if (self.privateChatroomViewController) {
        [self.privateChatroomViewController addNewChatroomObject:chatObject];
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

#pragma mark Interactive message
- (void)socketIO:(PLVSocketIO *)socketIO didReceiveBulletinMessage:(NSString *)json result:(int)result {
    if (result == 0) {
        [self.triviaCardVC openBulletin:json];
    }else if(result == 1){
        [self.triviaCardVC removeBulletin];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveQuestionMessage:(NSString *)json result:(int)result {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (result == 0) {
            [weakSelf.triviaCardVC openQuestionContent:json];
        } else if (result == 1) {
            [weakSelf.triviaCardVC openQuestionResult:json];
        } else if (result == 2) {
            [weakSelf.triviaCardVC testQuestion:json];
        }
    });
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveLotteryMessage:(NSString *)json result:(int)result {
    if (result == 0 || result == 2) {
        [self.triviaCardVC startLottery:json];
    } else if (result == 1 || result == 3) {
        [self.triviaCardVC stopLottery:json socketIO:socketIO];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveQuestionnaireMessage:(NSString *)json result:(int)result {
    if (result == 0) {
        [self.triviaCardVC openQuestionnaireContent:json]; // 打开问卷
    } else if (result == 1) {
        [self.triviaCardVC stopQuestionNaire:json];    // 关闭问卷
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveSignInMessage:(NSString *)json result:(int)result {
    if (result == 0) {
        [self.triviaCardVC startSign:json];
    } else if (result == 1) {
        [self.triviaCardVC stopSign:json];
    }
}

#pragma mark Custom message
- (void)socketIO:(PLVSocketIO *)socketIO didReceiveCustomMessage:(NSDictionary *)customMessage {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),customMessage[@"EVENT"]);
    [self.publicChatroomViewController addCustomMessage:customMessage mine:NO];
}

#pragma mark Connect state
- (void)socketIO:(PLVSocketIO *)socketIO didDisconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PCCUtils showChatroomMessage:@"聊天室失去连接" addedToView:self.pageController.view];
}

- (void)socketIO:(PLVSocketIO *)socketIO connectOnErrorWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PCCUtils showChatroomMessage:@"聊天室连接失败" addedToView:self.pageController.view];
    if (self.publicChatroomViewController) {
        [self.publicChatroomViewController recoverChatroomStatus];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO reconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PCCUtils showChatroomMessage:@"聊天室重连中..." addedToView:self.pageController.view];
}

#pragma mark Error
- (void)socketIO:(PLVSocketIO *)socketIO localError:(NSString *)description {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),description);
}

#pragma mark - PLVChatroomDelegate
- (void)chatroom:(PLVChatroomController *)chatroom didOpenError:(PLVChatroomErrorCode)code {
    if (code == PLVChatroomErrorCodeBeKicked) {
        [self exitCurrentControllerWithAlert:nil message:@"您未被授权观看本直播"];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom emitSocketObject:(PLVSocketChatRoomObject *)object {
    if (self.socketIO.socketIOState == PLVSocketIOStateConnected) {
        [self.socketIO emitMessageWithSocketObject:object];
    } else {
        [PCCUtils showChatroomMessage:@"聊天室未连接！" addedToView:self.pageController.view];
    }
}

- (NSString *)currentChannelSessionId:(PLVChatroomController *)chatroom {
    return [self.mediaVC currentChannelSessionId];
}

- (void)chatroom:(PLVChatroomController *)chatroom userInfo:(NSDictionary *)userInfo {
    [self.mediaVC setUserInfo:userInfo];
    if (self.linkMicVC && self.linkMicVC.token.length > 0) {
        [self.socketIO reJoinMic:self.linkMicVC.token];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom didSendSpeakContent:(NSString *)content {
    NSMutableAttributedString *attributedStr = [[PLVEmojiManager sharedManager] convertTextEmotionToAttachment:content font:[UIFont systemFontOfSize:14]];
    [self.mediaVC danmu:attributedStr];
}

- (void)chatroom:(PLVChatroomController *)chatroom emitCustomEvent:(NSString *)event emitMode:(int)emitMode data:(NSDictionary *)data tip:(NSString *)tip {
    if (self.socketIO.socketIOState == PLVSocketIOStateConnected) {
        [self.socketIO emitCustomEvent:event roomId:self.channelId emitMode:emitMode data:data tip:tip];
    } else {
        [PCCUtils showChatroomMessage:@"聊天室未连接！" addedToView:self.pageController.view];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom showMessage:(NSString *)message {
    [PCCUtils showChatroomMessage:message addedToView:self.pageController.view];
}

- (void)readBulletin:(PLVChatroomController *)chatroom{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.33 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.triviaCardVC openLastBulletin];
    });
}

- (void)reLogin:(PLVChatroomController *)chatroom {
    [self exitCurrentController];
}

- (void)refreshLinkMicOnlineCount:(PLVChatroomController *)chatroom number:(NSUInteger)number {
    [self.linkMicVC refreshOnlineCount:number];
}

#pragma mark - PLVBaseMediaViewControllerDelegate
- (void)quit:(PLVBaseMediaViewController *)mediaVC error:(NSError *)error {
    if (error) {
        if (error.code == PLVBaseMediaErrorCodeMarqueeFailed) {
            [self exitCurrentControllerWithAlert:@"自定义跑马灯校验失败" message:error.localizedDescription];
        }
    } else {
        [self exitCurrentController];
    }
}

- (void)statusBarAppearanceNeedsUpdate:(PLVBaseMediaViewController *)mediaVC {
    [self setNeedsStatusBarAppearanceUpdate];//横竖屏切换前，更新Status Bar的状态
    
    [self.triviaCardVC layout:self.mediaVC.skinView.fullscreen];
    
    self.linkMicVC.fullscreen = self.mediaVC.skinView.fullscreen;
    self.linkMicVC.orientation = [UIDevice currentDevice].orientation;
    if (self.mediaVC.skinView.fullscreen) {
        [self.publicChatroomViewController tapChatInputView];
        [self.privateChatroomViewController tapChatInputView];
        
        CGFloat x = 0.0;
        if (@available(iOS 11.0, *)) {
            x = self.view.safeAreaLayoutGuide.layoutFrame.origin.x;
        }
        [self.mediaVC.view insertSubview:self.linkMicVC.view belowSubview:self.mediaVC.skinView];
        [self.linkMicVC resetLinkMicFrame:CGRectMake(x, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)];
    } else {
        [self.view insertSubview:self.linkMicVC.view atIndex:0];
        CGRect linkMicRect = CGRectMake(0.0, self.mediaViewControllerHeight, self.view.bounds.size.width, 0.0);
        [self.linkMicVC resetLinkMicFrame:linkMicRect];
    }
}

- (void)sendText:(PLVBaseMediaViewController *)mediaVC text:(NSString *)text{
    [self.publicChatroomViewController sendTextMessage:text];
}

- (void)sendPaintInfo:(PLVBaseMediaViewController *)mediaVC jsonData:(NSString *)jsonData {
    [self.socketIO emitEvent:@"message" withJsonString:jsonData];
}
    
- (void)streamStateDidChange:(PLVBaseMediaViewController *)mediaVC streamState:(PLVLiveStreamState)streamState{
    [self getChannelMenuInfosForRefresh:YES];
}

#pragma mark - PLVTriviaCardViewControllerDelegate
- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC chooseAnswer:(NSDictionary *)dict {
    [self.socketIO emitMessageWithSocketObject:[self createCardSocketObjectWithEvent:@"ANSWER_TEST_QUESTION" dict:dict]];
}

- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC questionnaireAnswer:(NSDictionary *)dict {
    [self.socketIO emitMessageWithSocketObject:[self createCardSocketObjectWithEvent:@"ANSWER_QUESTIONNAIRE" dict:dict]];
}

- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC checkIn:(NSDictionary *)dict {
    NSString *nickName = self.socketIO.user.nickName;
    NSDictionary *user = @{@"nick" : nickName, @"userId" : self.socketIO.userId};
    NSDictionary *baseJSON = @{@"EVENT" : @"TO_SIGN_IN", @"roomId" : [NSString stringWithFormat:@"%lu", (unsigned long)self.socketIO.roomId], @"user" : user};
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json addEntriesFromDictionary:baseJSON];
    [json addEntriesFromDictionary:dict];
    PLVSocketTriviaCardObject *checkin = [PLVSocketTriviaCardObject socketObjectWithJsonDict:json];
    [self.socketIO emitMessageWithSocketObject:checkin];
}

- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC lottery:(NSDictionary *)dict {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data addEntriesFromDictionary:@{@"channelId" : [NSString stringWithFormat:@"%lu", (unsigned long)self.socketIO.roomId]}];
    [data addEntriesFromDictionary:dict];
    [PLVLiveVideoAPI postLotteryWithData:data completion:^{} failure:^(NSError *error) {
        NSLog(@"抽奖信息提交失败: %@", error.description);
    }];
}

- (PLVSocketTriviaCardObject *)createCardSocketObjectWithEvent:(NSString *)event dict:(NSDictionary *)dict{
    NSString *nickName = self.socketIO.user.nickName;
    NSDictionary *baseJSON = @{@"EVENT" : event, @"roomId" : [NSString stringWithFormat:@"%lu", (unsigned long)self.socketIO.roomId], @"nick" : nickName, @"userId" : self.socketIO.userId};
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json addEntriesFromDictionary:baseJSON];
    [json addEntriesFromDictionary:dict];
    PLVSocketTriviaCardObject *triviaCard = [PLVSocketTriviaCardObject socketObjectWithJsonDict:json];
    return triviaCard;
}

#pragma mark - PLVLinkMicControllerDelegate
- (void)linkMicController:(PLVLinkMicController *)lickMic toastTitle:(NSString *)title detail:(NSString *)detail {
    if (detail.length == 0) {
        [PCCUtils showChatroomMessage:title addedToView:self.view];
    } else {
        [PCCUtils showHUDWithTitle:title detail:detail view:self.view];
    }
}

- (void)linkMicController:(PLVLinkMicController *)lickMic emitLinkMicObject:(PLVSocketLinkMicEventType)eventType {
    PLVSocketObject *loginUser = [PLVChatroomManager sharedManager].loginUser;
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channelId userNick:loginUser.nickName userPic:loginUser.avatar userId:(NSUInteger)loginUser.userId.longLongValue userType:loginUser.userType token:nil];
    [self.socketIO emitMessageWithSocketObject:linkMicObject];
}

- (void)linkMicController:(PLVLinkMicController *)lickMic emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback {
    PLVSocketObject *loginUser = [PLVChatroomManager sharedManager].loginUser;
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channelId userNick:loginUser.nickName userPic:loginUser.avatar userId:(NSUInteger)loginUser.userId.longLongValue userType:loginUser.userType token:eventType == PLVSocketLinkMicEventType_JOIN_LEAVE ? lickMic.token : nil];
    [self.socketIO emitACKWithSocketObject:linkMicObject after:after callback:callback];
}

- (void)emitMuteSocketMessage:(NSString *)uid type:(NSString *)type mute:(BOOL)mute {
    PLVSocketLinkMicObject *muteLinkMic = [PLVSocketLinkMicObject muteLinkMicWithUid:uid type:type mute:mute];
    [self.socketIO emitMessageWithSocketObject:muteLinkMic];
}

- (void)resetChatroomFrame:(CGFloat)top {
    if (self.fullSize.height - top >= self.pageController.barHeight) {
        CGRect pageCtrlFrame = CGRectMake(0, top, self.fullSize.width, self.fullSize.height - top);
        self.pageController.view.frame = pageCtrlFrame;
        [self.pageController changeFrame];
        [self.pageController cornerRadius:fabs(top - self.mediaViewControllerHeight) > 1.0];
        
        CGRect chatroomFrame = CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame) - self.pageController.barHeight);
        self.liveInfoViewController.view.frame = chatroomFrame;
        self.liveInfoViewController.view.autoresizingMask = UIViewAutoresizingNone;
        
        [self.publicChatroomViewController resetChatroomFrame:chatroomFrame];
        [self.privateChatroomViewController resetChatroomFrame:chatroomFrame];
    }
}

- (void)changeLinkMicFrame:(PLVLinkMicController *)lickMic whitChatroom:(BOOL)chatroom {
    if (self.mediaVC.skinView.fullscreen) {
        CGFloat x = 0.0;
        if (@available(iOS 11.0, *)) {
            x = self.view.safeAreaLayoutGuide.layoutFrame.origin.x;
        }
        [self.linkMicVC resetLinkMicFrame:CGRectMake(x, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)];
        [self.mediaVC.view insertSubview:self.linkMicVC.view belowSubview:self.mediaVC.skinView];
        [self.mediaVC.view insertSubview:self.linkMicVC.controlView belowSubview:self.mediaVC.skinView];
        [self.mediaVC changeFrame:YES block:nil];
    } else {
        [self.view insertSubview:self.linkMicVC.view atIndex:0];
        
        self.pageController.touchLineView.hidden = self.linkMicVC.view.alpha == 0.0;
        if (chatroom || fabs(self.pageController.view.frame.origin.y - self.mediaViewControllerHeight) > 1.0) {
            [self resetChatroomFrame:self.mediaViewControllerHeight + (self.linkMicVC.view.alpha == 0.0 ? 0.0 : self.linkMicVC.view.bounds.size.height)];
        }
    }
}

- (void)linkMicSuccess:(PLVLinkMicController *)lickMic {
    [self.publicChatroomViewController tapChatInputView];
    [self.privateChatroomViewController tapChatInputView];
    
    self.mediaVC.skinView.controllView.hidden = YES;

    [self.mediaVC linkMicSuccess];
}

- (void)cancelLinkMic:(PLVLinkMicController *)lickMic {
    [self.mediaVC addTapGestureRecognizer];
    [self.mediaVC.skinView addPanGestureRecognizer];
    self.mediaVC.skinView.controllView.hidden = NO;
    [self.mediaVC skinHiddenAnimaion];

    [self.mediaVC cancelLinkMic];
}

- (void)linkMicSwitchViewAction:(PLVLinkMicController *)lickMic manualControl:(BOOL)manualControl {
    [self.mediaVC linkMicSwitchViewAction:manualControl];
}

- (void)linkMicSwitchViewAction:(PLVLinkMicController *)lickMic status:(BOOL)status {
    if ([self.mediaVC isKindOfClass:[PLVPPTLiveMediaViewController class]]) {
        [(PLVPPTLiveMediaViewController *)self.mediaVC changeVideoAndPPTPosition:status];
    }
}

- (void)linkMicController:(PLVLinkMicController *)lickMic paint:(BOOL)paint {
    if (paint) {
        [self.mediaVC removeTapGestureRecognizer];
        [self.mediaVC.skinView removePanGestureRecognizer];
        [self.mediaVC backBtnShowNow];
    } else {
        [self.mediaVC addTapGestureRecognizer];
        [self.mediaVC.skinView addPanGestureRecognizer];
    }
}

#pragma mark - FTPageControllerDelegate
- (BOOL)canMoveChatroom:(FTPageController *)pageController move:(BOOL)move {
    if (self.linkMicVC.view.alpha != 0.0) {
        if (fabs(self.pageController.view.frame.origin.y - self.mediaViewControllerHeight) <= 1.0 || (self.movingChatroom && !self.moveChatroomUp)) {
            self.moveChatroomUp = NO;
            if (move) {
                [self resetChatroomFrame:self.mediaViewControllerHeight + self.linkMicVC.view.bounds.size.height];
            }
            return YES;
        } else if (fabs(self.pageController.view.frame.origin.y - self.mediaViewControllerHeight - self.linkMicVC.view.bounds.size.height) <= 1.0 || (self.movingChatroom && self.moveChatroomUp)) {
            self.moveChatroomUp = YES;
            if (move) {
                [self resetChatroomFrame:self.mediaViewControllerHeight];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL)canMoveChatroom:(FTPageController *)pageController {
    return [self canMoveChatroom:pageController move:NO];
}

- (void)moveChatroom:(FTPageController *)pageController toPointY:(CGFloat)pointY {
    CGFloat top = self.pageController.view.frame.origin.y + pointY;
    if (top >= self.mediaViewControllerHeight && top <= self.mediaViewControllerHeight + self.linkMicVC.view.bounds.size.height) {
        self.movingChatroom = YES;
        [self resetChatroomFrame:top];
    }
}

- (void)moveChatroom:(FTPageController *)pageController {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        [weakSelf canMoveChatroom:pageController move:YES];
    } completion:^(BOOL finished) {
        weakSelf.movingChatroom = NO;
    }];
}

@end
