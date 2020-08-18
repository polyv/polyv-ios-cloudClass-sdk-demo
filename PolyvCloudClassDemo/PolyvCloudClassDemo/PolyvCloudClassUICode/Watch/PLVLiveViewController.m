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
#import <PolyvCloudClassSDK/PLVWebViewController.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>

#define PPTPlayerViewScale (9.0 / 16.0)
#define NormalPlayerViewScale (9.0 / 16.0)

@interface PLVLiveViewController () <PLVBaseMediaViewControllerDelegate, PLVTriviaCardViewControllerDelegate,  PLVLinkMicControllerDelegate, PLVSocketIODelegate, PLVChatroomDelegate, FTPageControllerDelegate, PLVWebViewTuwenProtocol>

@property (nonatomic, assign) NSUInteger channelId;//当前直播的频道号

@property (nonatomic, strong) PLVBaseMediaViewController<PLVLiveMediaProtocol> *mediaVC;//播放器控件
@property (nonatomic, strong) PLVTriviaCardViewController *triviaCardVC;//答题卡控件
@property (nonatomic, strong) PLVLinkMicController *linkMicVC;//连麦控件
@property (nonatomic, strong) FTPageController *pageController;
@property (nonatomic, strong) PLVLiveInfoViewController *liveInfoViewController;
@property (nonatomic, strong) PLVChatroomController *publicChatroomViewController;
@property (nonatomic, strong) PLVChatroomController *privateChatroomViewController;
@property (nonatomic, strong) PLVWebViewController *tuwenWebViewController;

@property (nonatomic, assign) CGRect chatroomFrame;
@property (nonatomic, assign) BOOL idleTimerDisabled;
@property (nonatomic, assign) CGFloat mediaViewControllerHeight;
@property (nonatomic, assign) CGSize fullSize;
@property (nonatomic, assign) BOOL movingChatroom;
@property (nonatomic, assign) BOOL moveChatroomUp;

@property (nonatomic, strong) PLVSocketIO *socketIO;
@property (nonatomic, strong) PLVSocketObject *loginUser;
@property (nonatomic, assign) BOOL loginSuccess;

@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, assign) int reconnectCount;

@property (nonatomic, strong) NSTimer *viewerTimer;// 上报观看热度的缓冲计时器
@property (nonatomic, assign) NSInteger viewerNumber;// 需要上报的新增观看人数

@property (nonatomic, assign) float triviaCardTimeoutSec;// 互动应用提交超时秒数
@property (nonatomic, assign) NSInteger triviaCardMaxRetryCount;// 互动应用最大重试提交次数

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
        __weak typeof(self) weakSelf = self;
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"观看时长：%ld，停留时长：%ld", (long)weakSelf.mediaVC.player.watchDuration, (long)weakSelf.mediaVC.player.stayDuration);
        }];
    }
}

#pragma mark - init
- (void)initData {
    self.reconnectCount = 0;
    
    self.triviaCardTimeoutSec = 5.0;
    self.triviaCardMaxRetryCount = 3;
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    self.channelId = liveConfig.channelId.integerValue;
    
    PLVSocketObjectUserType userType = self.viewer ? PLVSocketObjectUserTypeViewer : (self.liveType == PLVLiveViewControllerTypeLive ? PLVSocketObjectUserTypeStudent : PLVSocketObjectUserTypeSlice);
    
    /* 初始化登录用户
        1. nickName 为nil时，聊天室首次点击输入栏会弹窗提示输入昵称。可通过设置defaultUser属性为NO屏蔽
        2. 抽奖功能必须固定唯一的 nickName 和 userId，如果忘了填写上次的中奖信息，有固定的 userId 还会再次弹出相关填写页面
     */
    PLVSocketObject *loginUser = [PLVSocketObject socketObjectForLoginWithRoomId:self.channelId nickName:self.nickName avatar:self.avatarUrl userId:nil accountId:[PLVLiveVideoConfig sharedInstance].userId authorization:nil userType:userType];
    loginUser.defaultUser = NO; // 屏蔽聊天室点击输入栏弹窗提示输入昵称
    
    NSMutableDictionary *muJsonDict = [[NSMutableDictionary alloc] initWithDictionary:loginUser.jsonDict];
    muJsonDict[@"param4"] = liveConfig.param4 ?: @"";
    muJsonDict[@"param5"] = liveConfig.param5 ?: @"";
    loginUser.jsonDict = [muJsonDict copy];
    
    self.loginUser = loginUser;
    [PLVChatroomManager sharedManager].socketUser = loginUser;
}

- (void)addMediaViewController {
    self.mediaViewControllerHeight = (int)(self.view.bounds.size.width * (self.liveType == PLVLiveViewControllerTypeCloudClass ? PPTPlayerViewScale : NormalPlayerViewScale));
    self.mediaViewControllerHeight += [PCCUtils getStatusBarHeight];
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    PLVSocketObject *loginUser = [PLVChatroomManager sharedManager].socketUser;
    
    if (self.liveType == PLVLiveViewControllerTypeCloudClass) {
        self.mediaVC = [[PLVPPTLiveMediaViewController alloc] init];
    } else {
        self.mediaVC = [[PLVNormalLiveMediaViewController alloc] init];
    }
    
    self.linkMicVC = [[PLVLinkMicController alloc] init];
    self.linkMicVC.delegate = self;
    self.linkMicVC.login = [PLVChatroomManager sharedManager].socketUser;
    self.linkMicVC.viewerSignalEnabled = [self.channelMenuInfo.viewerSignalEnabled isEqualToString:@"Y"];
    self.linkMicVC.awardTrophyEnabled = [self.channelMenuInfo.awardTrophyEnabled isEqualToString:@"Y"];
    if (self.channelMenuInfo) { self.linkMicVC.notSupportLinkMic = (self.channelMenuInfo.rtcType.length == 0 || [self.channelMenuInfo.rtcType isEqualToString:@"urtc"]); }
    if (self.liveType == PLVLiveViewControllerTypeLive) {
        self.linkMicVC.linkMicType = PLVLinkMicTypeNormalLive;//开启视频连麦时，普通直播的连麦窗口是音频模式(旧版推流端)，或者视频模式（新版推流端，对齐云课堂的连麦方式）
    } else {
        self.linkMicVC.linkMicType = PLVLinkMicTypeCloudClass;//开启视频连麦时，云课堂的是视频模式
    }
    
    self.mediaVC.linkMicVC = self.linkMicVC;
    self.mediaVC.delegate = self;
    self.mediaVC.playAD = self.liveState==PLVLiveStreamStateNoStream;
    self.mediaVC.channelId = liveConfig.channelId; //必须，不能为空
    self.mediaVC.userId = liveConfig.userId; //必须，不能为空
    self.mediaVC.nickName = loginUser.nickName;
    self.mediaVC.originFrame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.mediaViewControllerHeight);
    //self.mediaVC.showDanmuOnPortrait = YES; // 竖屏显示弹幕按钮
    self.mediaVC.chaseFrame = self.chaseFrame;  // 是否开启追帧
    // !!!: mediaVC.chaseFrame 属性的设置需在 self.mediaVC.view.frame 设置之前
    self.mediaVC.view.frame = self.mediaVC.originFrame;
    [self.view addSubview:self.mediaVC.view];
    
    CGFloat secondaryWidth = (int)([UIScreen mainScreen].bounds.size.width / self.linkMicVC.colNum);
    CGFloat secondaryHeight = (int)(secondaryWidth * PPTPlayerViewScale);
    if (self.liveType == PLVLiveViewControllerTypeCloudClass) {
        self.linkMicVC.secondaryClosed = NO;
        [(PLVPPTLiveMediaViewController *)self.mediaVC loadSecondaryView:CGRectMake(0.0, self.mediaViewControllerHeight, secondaryWidth, secondaryHeight)];
    }
    // 可在此处自定义播放器背景图（本地图片或网络图片）
    self.mediaVC.player.backgroundImgView.image = [PCCUtils getBaseMediaImage:@"plv_skin_player_background"];
    self.mediaVC.player.backgroundImgView.highlightedImage = [PCCUtils getBaseMediaImage:@"plv_skin_player_pause_background"];
    
    self.linkMicVC.pageBarHeight = 56.0;
    self.linkMicVC.originSize = CGSizeMake(secondaryWidth, secondaryHeight);
    self.linkMicVC.view.frame = CGRectMake(0.0, self.mediaViewControllerHeight, self.view.bounds.size.width, secondaryHeight);
    [self.view insertSubview:self.linkMicVC.view atIndex:0];
    [self.linkMicVC hiddenLinkMic:self.liveState==PLVLiveStreamStateNoStream];
    
    // 若需要 [加载静态离线页面]，请解开2处注释代码
    // 1_[加载静态离线页面]
    // NSString *basePath = [[NSBundle bundleForClass:[self class]].resourcePath stringByAppendingPathComponent:@"/PLVBaseMedia.bundle/dist"];
    // NSURL *baseURL = [NSURL fileURLWithPath:basePath isDirectory:YES];
    // NSString *htmlPath = [NSString stringWithFormat:@"%@/index.html", basePath];
    // NSError * htmlError;
    // NSString *htmlString = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:&htmlError];
    // if (htmlError) { NSLog(@"[加载静态离线页面] 错误 Error - %@",htmlError); }
    
    self.triviaCardVC = [[PLVTriviaCardViewController alloc] init];
    self.triviaCardVC.delegate = self;
    
    // 2_[加载静态离线页面]
    // self.triviaCardVC.localHtml = htmlString;
    // self.triviaCardVC.baseURL = baseURL;
    
    self.triviaCardVC.view.frame = self.view.bounds;
    self.triviaCardVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.triviaCardVC.view];
    [self.triviaCardVC.closeBtn setImage:[PCCUtils getBaseMediaImage:@"plv_skin_close.png"] forState:UIControlStateNormal];

}

#pragma mark - setup chatroom
- (void)setupChatroomItem {
    CGFloat barHeight = 56.0;
    CGFloat top = self.mediaViewControllerHeight + (self.liveState==PLVLiveStreamStateNoStream ? 0.0 : self.linkMicVC.view.frame.size.height);
    CGRect pageCtrlFrame = CGRectMake(0, top, self.fullSize.width, self.fullSize.height - top);
    self.chatroomFrame = CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame) - barHeight);
    
    NSMutableArray *titles = [NSMutableArray new];
    NSMutableArray *controllers = [NSMutableArray new];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ordered" ascending:YES];
    NSArray *sortedChannelMenus = [self.channelMenuInfo.channelMenus sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    for (PLVLiveVideoChannelMenu *menu in sortedChannelMenus) {
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
        } else if (menu.name.length > 0) {
            if (![@"text" isEqualToString:menu.menuType] &&
                ![@"iframe" isEqualToString:menu.menuType] &&
                ![@"tuwen" isEqualToString:menu.menuType]) {
                continue;
            }
            
            [titles addObject:menu.name];
            
            PLVWebViewController *vctrl = [PLVWebViewController new];
            if ([@"text" isEqualToString:menu.menuType]) {
                [vctrl loadHtmlWithContent:menu.content];
            } else if ([@"iframe" isEqualToString:menu.menuType]) {
                [vctrl loadURLString:menu.content];
            } else if ([@"tuwen" isEqualToString:menu.menuType]) {
                [self initSocketIO];
                NSString *urlString = @"https://live.polyv.net/front/tuwen/index";
                [vctrl loadURLString:urlString];
                [vctrl setupTuwen:self.channelId];
                vctrl.tuwenDelegate = self;
                self.tuwenWebViewController = vctrl;
            }
            
            [controllers addObject:vctrl];
        }
    }
    
    if (titles.count>0 && controllers.count>0 && titles.count==controllers.count) {
        self.pageController = [[FTPageController alloc] init];
        self.pageController.view.frame = pageCtrlFrame;
        [self.pageController setTitles:titles controllers:controllers barHeight:barHeight touchHeight:26.0];
        self.pageController.delegate = self;
        [self.view insertSubview:self.pageController.view belowSubview:self.mediaVC.view];  // 需要添加在播放器下面，使得播放器全屏的时候能盖住聊天室
        [self addChildViewController:self.pageController];
        [self.pageController cornerRadius:fabs(top - self.mediaViewControllerHeight) > 1.0];
        self.pageController.touchLineView.hidden = self.liveState==PLVLiveStreamStateNoStream;
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
    return [self viewControllerCanRotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // 设备为iPhone时，不处理竖屏的UpsideDown方向
    BOOL iPhone = [@"iPhone" isEqualToString:[UIDevice currentDevice].model];
    UIInterfaceOrientationMask mask = iPhone ? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskAll;
    if ([self viewControllerCanRotate]) {
        mask = iPhone ? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskAll;
    }else{
        mask = UIInterfaceOrientationMaskPortrait;
    }
    return mask;
}

- (BOOL)viewControllerCanRotate{
    return self.mediaVC != nil && self.mediaVC.canAutorotate && ![PLVLiveVideoConfig sharedInstance].unableRotate && ![PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate;
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
        weakSelf.linkMicVC.viewerSignalEnabled = [channelMenuInfo.viewerSignalEnabled isEqualToString:@"Y"];
        weakSelf.linkMicVC.awardTrophyEnabled = [channelMenuInfo.awardTrophyEnabled isEqualToString:@"Y"];
        weakSelf.linkMicVC.notSupportLinkMic = (channelMenuInfo.rtcType.length == 0 || [channelMenuInfo.rtcType isEqualToString:@"urtc"]);;
        if (refresh) {
            for (PLVLiveVideoChannelMenu *menu in weakSelf.channelMenuInfo.channelMenus) {
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
        [weakSelf initSocketIO];
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
    if (self.viewerTimer) { // 注销上报热度计时器
        [self.viewerTimer invalidate];
        self.viewerTimer = nil;
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
- (void)initSocketIO {
    if (self.socketIO) {
        return;
    }
    
    static BOOL loading;
    if (loading) {
        return;
    }
    loading = YES;
    __weak typeof(self) weakSelf = self;
    NSString *chatUserId = self.loginUser.userId; // [PLVChatroomManager sharedManager].socketUser.userId;
    [PLVLiveVideoAPI getChatTokenWithChannelId:weakSelf.channelId userId:chatUserId completion:^(NSDictionary * data, NSError * error) {
        if (error) {
            [PCCUtils showHUDWithTitle:@"聊天室Token获取失败！" detail:error.localizedDescription view:weakSelf.view];
        } else {
            // 初始化 socketIO 连接对象
            NSString *socketServerUrl = nil;
            PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
            if (liveConfig.chatDomain) {
                socketServerUrl = [NSString stringWithFormat:@"https://%@", liveConfig.chatDomain];
            }
            weakSelf.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:data[@"token"] url:socketServerUrl enableLog:NO];
            weakSelf.socketIO.delegate = weakSelf;
            [weakSelf.socketIO connect];
            //weakSelf.socketIO.debugMode = YES;
            
            if ([weakSelf.mediaVC isKindOfClass:PLVPPTLiveMediaViewController.class]) {
                ((PLVPPTLiveMediaViewController *)weakSelf.mediaVC).viewer = weakSelf.viewer;
            }
            weakSelf.linkMicVC.viewer = weakSelf.viewer;
            if (weakSelf.linkMicVC.viewer) { ((PLVLivePlayerController *)weakSelf.mediaVC.player).linkMic = YES; }
        }
        loading = NO;
    }];
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
    [self clearSocketIO];
    
    NSString *event = jsonDict[@"EVENT"];
    if ([event isEqualToString:@"LOGIN_REFUSE"]) {
        [self exitCurrentControllerWithAlert:nil message:@"您未被授权观看本直播"];
    } else if ([event isEqualToString:@"TOKEN_EXPIRED"]) {
        if (self.reconnectCount < 3) {
            self.reconnectCount ++;
            [self initSocketIO];
        } else {
            [PCCUtils showChatroomMessage:@"TOKEN_EXPIRED" addedToView:self.pageController.view];
        }
    }
}

// 此方法可能多次调用，如锁屏后返回会重连聊天室
- (void)socketIO:(PLVSocketIO *)socketIO didConnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@", NSStringFromSelector(_cmd), info);
    
    // 登录 Socket 服务器
    __weak typeof(self)weakSelf = self;
    PLVSocketObject *loginObject = [PLVChatroomManager sharedManager].socketUser;

    // 奖杯功能请解开注释
    NSMutableDictionary *muJsonDict = [[NSMutableDictionary alloc] initWithDictionary:loginObject.jsonDict];
    muJsonDict[@"getCup"] = @(1);
    loginObject.jsonDict = [muJsonDict copy];
    // 奖杯功能代码到此截止
    
    [socketIO loginSocketServer:loginObject timeout:12.0 callback:^(NSArray *ackArray) {
        NSLog(@"login ackArray: %@",ackArray);
        if (ackArray) {
            NSString *ackStr = [NSString stringWithFormat:@"%@",ackArray.firstObject];
            if (ackStr && ackStr.length > 4) {
                int status = [[ackStr substringToIndex:1] intValue];
                if (status == 2) {
                    weakSelf.loginSuccess = YES;
                    [PCCUtils showChatroomMessage:@"登录成功" addedToView:weakSelf.pageController.view];
                    BOOL bannedStatus =  [[ackStr substringWithRange:NSMakeRange(4, 1)] boolValue];
                    [PLVChatroomManager sharedManager].banned = !bannedStatus;
                    weakSelf.viewerNumber++;// 需上报的观看人数+1
                    [weakSelf startViewerTimer];// 启动上报缓冲计时器
                } else {
                    [weakSelf loginToSocketFailed:ackStr];
                }
            } else {
                [weakSelf loginToSocketFailed:ackStr];
            }
        }
    }];
}

- (void)loginToSocketFailed:(NSString *)ackStr {
    [self.socketIO disconnect];
    self.loginSuccess = NO;
    [PCCUtils showChatroomMessage:[@"登录失败：" stringByAppendingString:ackStr] addedToView:self.pageController.view];
}

#pragma mark Socket message
- (void)socketIO:(PLVSocketIO *)socketIO didReceivePublicChatMessage:(PLVSocketChatRoomObject *)chatObject {
//    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)chatObject.eventType, chatObject.event);
    switch (chatObject.eventType) {
        case PLVSocketChatRoomEventType_RELOGIN: {
            __weak typeof(self) weakSelf = self;
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"当前账号已在其他地方登录，您将被退出观看" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf exitCurrentController];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        } break;
        default:
            [self.publicChatroomViewController addNewChatroomObject:chatObject];
            break;
    }
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

// 奖杯功能请解开注释
- (void)socketIO:(PLVSocketIO *)socketIO didReceiveSendCupMessage:(NSDictionary *)jsonDict {
    NSDictionary *owner = PLV_SafeDictionaryForDictKey(jsonDict, @"owner");
    if (owner) {
        NSString *userId = PLV_SafeStringForDictKey(owner, @"userId");
        NSInteger cupNumber = PLV_SafeIntegerForDictKey(owner, @"num");
        [self.linkMicVC updateUser:userId trophyNumber:cupNumber];
    }
}
// 奖杯功能代码到此截止

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveTuwenMessage:(NSString *)json eventType:(NSString *)event {
    [self.tuwenWebViewController socketEvent:event data:json];
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
    } else if (result == 2) {
        [self.triviaCardVC sendQuestionNaireResult:json];    // 收到问卷结果
    } else if (result == 3) {
        [self.triviaCardVC questionNaireAchievement:json];    // 到问卷统计相关数据事件
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
    NSString *msgId = PLV_SafeStringForDictKey(customMessage, @"id");
    [self.publicChatroomViewController addCustomMessage:customMessage mine:NO msgId:msgId];
}

#pragma mark Connect state
- (void)socketIO:(PLVSocketIO *)socketIO didDisconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    if (self.loginSuccess) {
        [PCCUtils showChatroomMessage:@"聊天室失去连接" addedToView:self.pageController.view];
    }
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
    [self.tuwenWebViewController reconnectTuwen];
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
        if (self.loginSuccess) {
            if (object.eventType == PLVSocketChatRoomEventType_SPEAK || object.eventType == PLVSocketChatRoomEventType_CHAT_IMG) {
                [self.socketIO emitACKWithSocketObject:object after:5 callback:^(NSArray *ackArray) {
                    NSString *ackString = nil;
                    if (ackArray && [ackArray count] > 0) {
                        ackString = ackArray[0];
                    }
                    if (ackString && [ackString isKindOfClass:[NSString class]] && ackString.length > 0) {
                        if (object.eventType == PLVSocketChatRoomEventType_CHAT_IMG) {
                            if (![ackString isEqualToString:@"NO ACK"]) {
                                NSArray *values = object.jsonDict[@"values"];
                                NSDictionary *valuesDict = values[0];
                                NSString *imageId = valuesDict[@"id"] ?: @"";
                                NSDictionary *dict = @{@"msgId": ackString, @"imageId": imageId};
                                [[NSNotificationCenter defaultCenter] postNotificationName:PLVChatroomSendImageMsgNotification
                                                                                    object:nil
                                                                                  userInfo:dict];
                            }
                        } else if (object.eventType == PLVSocketChatRoomEventType_SPEAK) {
                            PLVChatroomModel *model = [PLVChatroomModel modelWithObject:object];
                            model.msgId = ackString;
                            [[NSNotificationCenter defaultCenter] postNotificationName:PLVChatroomSendTextMsgNotification
                                                                                                           object:model];
                        }
                    }
                }];
            } else {
                [self.socketIO emitMessageWithSocketObject:object];
            }
        } else {
            [PCCUtils showChatroomMessage:@"聊天室未登录！" addedToView:self.pageController.view];
        }
    } else {
        [PCCUtils showChatroomMessage:@"聊天室未连接！" addedToView:self.pageController.view];
    }
}

- (NSString *)currentChannelSessionId:(PLVChatroomController *)chatroom {
    return [self.mediaVC currentChannelSessionId];
}

- (void)chatroom:(PLVChatroomController *)chatroom userInfo:(NSDictionary *)userInfo {
    NSDictionary *user = PLV_SafeDictionaryForDictKey(userInfo, @"user");
    NSString *userId = PLV_SafeStringForDictKey(user, @"userId");
    PLVSocketObject *socketUser = [PLVChatroomManager sharedManager].socketUser;
    BOOL me = [userId isEqualToString:socketUser.userId];
    if (me) {
        [self.mediaVC setUserInfo:userInfo];
        if (self.linkMicVC && self.linkMicVC.token.length > 0) {
            [self.socketIO reJoinMic:self.linkMicVC.token];
        }
    }
    
    [self.liveInfoViewController increaseWatchNumber];
}

- (void)chatroom:(PLVChatroomController *)chatroom didSendSpeakContent:(NSString *)content {
    NSMutableAttributedString *attributedStr = [[PLVEmojiManager sharedManager] convertTextEmotionToAttachment:content font:[UIFont systemFontOfSize:14]];
    [self.mediaVC danmu:attributedStr];
}

- (void)chatroom:(PLVChatroomController *)chatroom emitCustomEvent:(NSString *)event emitMode:(int)emitMode data:(NSDictionary *)data tip:(NSString *)tip {
    if (self.socketIO.socketIOState == PLVSocketIOStateConnected) {
        if (self.loginSuccess) {
            [self.socketIO emitCustomEvent:event roomId:self.channelId emitMode:emitMode data:data tip:tip after:self.triviaCardTimeoutSec callback:^(NSArray *ackArray) {
                NSString *ackString = nil;
                if (ackArray && [ackArray count] > 0) {
                    ackString = ackArray[0];
                }
                if (ackString && [ackString isKindOfClass:[NSString class]] && ackString.length > 0) {
                    NSDictionary *dict = [self dictionaryWithJsonString:ackString];
                    NSString *msgId = PLV_SafeStringForDictKey(dict, @"data");
                    NSDictionary *customMessage = @{@"EVENT":(event ?: @""), @"version":@(1), @"data":(data ?: @{})};
                    [[NSNotificationCenter defaultCenter] postNotificationName:PLVChatroomSendCustomMsgNotification
                                                                        object:msgId
                                                                      userInfo:customMessage];
                }
            }];
        } else {
            [PCCUtils showChatroomMessage:@"聊天室未登录！" addedToView:self.pageController.view];
        }
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
    __weak typeof(self) weakSelf = self;
    PLVSocketTriviaCardObject *socketObject = [self createCardSocketObjectWithEvent:@"ANSWER_TEST_QUESTION" dict:dict];
    [self.socketIO emitACKWithSocketObject:socketObject after:self.triviaCardTimeoutSec callback:^(NSArray *ackArray) {
        [weakSelf triviaCardAckHandle:ackArray event:@"ANSWER_TEST_QUESTION" socketObj:socketObject retryCount:0];
    }];
}

- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC questionnaireAnswer:(NSDictionary *)dict {
    __weak typeof(self) weakSelf = self;
    PLVSocketTriviaCardObject *socketObject = [self createCardSocketObjectWithEvent:@"ANSWER_QUESTIONNAIRE" dict:dict];
    [self.socketIO emitACKWithSocketObject:socketObject after:self.triviaCardTimeoutSec callback:^(NSArray *ackArray) {
        [weakSelf triviaCardAckHandle:ackArray event:@"ANSWER_QUESTIONNAIRE" socketObj:socketObject retryCount:0];
    }];
}

- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC checkIn:(NSDictionary *)dict {
    PLVSocketObject * loginUser = [PLVChatroomManager sharedManager].socketUser;
    NSString *nickName = loginUser.nickName;
    NSDictionary *user = @{@"nick" : [NSString stringWithFormat:@"%@",nickName], @"userId" : loginUser.userId};
    NSDictionary *baseJSON = @{@"EVENT" : @"TO_SIGN_IN", @"roomId" : [NSString stringWithFormat:@"%lu", (unsigned long)loginUser.roomId], @"user" : user};
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json addEntriesFromDictionary:baseJSON];
    [json addEntriesFromDictionary:dict];
    PLVSocketTriviaCardObject *checkin = [PLVSocketTriviaCardObject socketObjectWithJsonDict:json];
    
    __weak typeof(self) weakSelf = self;
    [self.socketIO emitACKWithSocketObject:checkin after:self.triviaCardTimeoutSec callback:^(NSArray *ackArray) {
        [weakSelf triviaCardAckHandle:ackArray event:@"TO_SIGN_IN" socketObj:checkin retryCount:0];
    }];
}

- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC lottery:(NSDictionary *)dict {
    PLVSocketObject * loginUser = [PLVChatroomManager sharedManager].socketUser;
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data addEntriesFromDictionary:@{@"channelId" : [NSString stringWithFormat:@"%lu", (unsigned long)loginUser.roomId]}];
    [data addEntriesFromDictionary:dict];
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI newPostLotteryWithData:data completion:^{
        [weakSelf triviaCardAckHandleNoRetry:@[@"{\"code\":200}"] event:@"LOTTERY"];
    } failure:^(NSError *error) {
        NSLog(@"抽奖信息提交失败: %@", error.description);
        [weakSelf triviaCardAckHandleNoRetry:@[@"{\"code\":400}"] event:@"LOTTERY"];
    }];
}

- (void)triviaCardViewController:(PLVTriviaCardViewController *)triviaCardVC clickLink:(NSURL *)linkURL {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:linkURL];
    });
}

- (PLVSocketTriviaCardObject *)createCardSocketObjectWithEvent:(NSString *)event dict:(NSDictionary *)dict{
    PLVSocketObject * loginUser = [PLVChatroomManager sharedManager].socketUser;
    NSDictionary *baseJSON = @{@"EVENT" : event, @"roomId" : [NSString stringWithFormat:@"%lu", (unsigned long)loginUser.roomId], @"nick" : [NSString stringWithFormat:@"%@",loginUser.nickName], @"userId" : [NSString stringWithFormat:@"%@",loginUser.userId]};
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json addEntriesFromDictionary:baseJSON];
    [json addEntriesFromDictionary:dict];
    PLVSocketTriviaCardObject *triviaCard = [PLVSocketTriviaCardObject socketObjectWithJsonDict:json];
    return triviaCard;
}

- (void)triviaCardAckHandleNoRetry:(NSArray *)ackResArray event:(NSString *)event{
    [self triviaCardAckHandle:ackResArray event:event socketObj:nil retryCount:0];
}

- (void)triviaCardAckHandle:(NSArray *)ackResArray event:(NSString *)event socketObj:(PLVSocketObject *)socketObj retryCount:(NSInteger)retryCount{
    if ([PLVFdUtil checkArrayUseable:ackResArray]) {
        NSString *ack = ackResArray.firstObject;
        if ([PLVFdUtil checkStringUseable:ack]) {
            if ([ack isEqualToString:@"NO ACK"]) {
                if (socketObj) {
                    /// 携带 socketObj 代表需重发
                    __weak typeof(self) weakSelf = self;
                    __block NSInteger count = (retryCount > 0 ? retryCount : 1);
                    [self.socketIO emitACKWithSocketObject:socketObj after:self.triviaCardTimeoutSec callback:^(NSArray *ackArray) {
                        if (count < weakSelf.triviaCardMaxRetryCount) {
                            count ++;
                            [weakSelf triviaCardAckHandle:ackArray event:event socketObj:socketObj retryCount:count];
                        }else{
                            [weakSelf.triviaCardVC submitResultTimeoutCallback:event];
                        }
                    }];
                }else{
                    [self.triviaCardVC submitResultTimeoutCallback:event];
                }
            }else{
                [self.triviaCardVC submitResultCallback:ack event:event];
            }
        }
    }
}

#pragma mark - PLVLinkMicControllerDelegate
- (void)linkMicController:(PLVLinkMicController *)lickMic toastTitle:(NSString *)title detail:(NSString *)detail {
    if (detail.length == 0) {
        [PCCUtils showChatroomMessage:title addedToView:self.view.superview];
    } else {
        [PCCUtils showHUDWithTitle:title detail:detail view:self.view.superview];
    }
}

- (void)linkMicController:(PLVLinkMicController *)lickMic emitLinkMicObject:(PLVSocketLinkMicEventType)eventType {
    PLVSocketObject *loginUser = [PLVChatroomManager sharedManager].socketUser;
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channelId userNick:loginUser.nickName userPic:loginUser.avatar userId:(NSUInteger)loginUser.linkMicId.longLongValue userType:loginUser.userType token:nil];
    [self.socketIO emitMessageWithSocketObject:linkMicObject];
}

- (void)linkMicController:(PLVLinkMicController *)lickMic emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback {
    PLVSocketObject *loginUser = [PLVChatroomManager sharedManager].socketUser;
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channelId userNick:loginUser.nickName userPic:loginUser.avatar userId:(NSUInteger)loginUser.linkMicId.longLongValue userType:loginUser.userType token:eventType == PLVSocketLinkMicEventType_JOIN_LEAVE ? lickMic.token : nil];
    [self.socketIO emitACKWithSocketObject:linkMicObject after:after callback:callback];
}

- (void)emitMuteSocketMessage:(NSString *)uid type:(NSString *)type mute:(BOOL)mute {
    PLVSocketLinkMicObject *muteLinkMic = [PLVSocketLinkMicObject muteLinkMicWithUid:uid type:type mute:mute];
    [self.socketIO emitMessageWithSocketObject:muteLinkMic];
}

- (void)resetChatroomFrame:(CGFloat)top {
    if (self.fullSize.height - top >= (self.pageController.barHeight - 20)) {
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
        [self.mediaVC.view insertSubview:self.linkMicVC.view belowSubview:self.mediaVC.marqueeView];
        [self.mediaVC.view insertSubview:self.linkMicVC.controlView belowSubview:self.mediaVC.marqueeView];
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

// “看我”功能请解开注释
- (void)lookAtMeWithLinkMicController:(PLVLinkMicController *)lickMic {
    NSString *event = @"LOOK_AT_ME";
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"EVENT"] = event;
    jsonDict[@"userId"] = [PLVChatroomManager sharedManager].socketUser.userId;
    
    PLVSocketObject *socketObject = [[PLVSocketObject alloc] init];
    socketObject.jsonDict = jsonDict;
    socketObject.event = event;
    [self.socketIO emitMessageWithSocketObject:socketObject];
}
// “看我”功能代码到此截止

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

#pragma mark - PLVWebViewTuwen Protocol

- (void)clickTuwenImage:(BOOL)showImage {
    [self.pageController scrollEnable:!showImage];
}

#pragma mark - 观看热度相关

- (void)startViewerTimer {
    // 若原先已在倒计时5秒中，撤销，重新倒计时
    [self.viewerTimer invalidate];
    self.viewerTimer = nil;
    // 倒计时5秒，5秒后上报观看热度
    self.viewerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(sendViewerNumberIncrease) userInfo:nil repeats:NO];
}

- (void)sendViewerNumberIncrease {
    NSInteger reportNumber = self.viewerNumber;
    self.viewerNumber = 0; // 上报则清零
    
    NSString *channelIdString = [NSString stringWithFormat:@"%zd", self.channelId];
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI increaseViewerWithChannelId:channelIdString times:reportNumber completion:^(NSInteger viewers){
        [weakSelf.liveInfoViewController updateWatchNumber:viewers];
    } failure:^(NSError * _Nonnull error) {
        weakSelf.viewerNumber += reportNumber; // 上报失败，人数不清零，倒计时5秒后再试
        [weakSelf startViewerTimer];
    }];
}

#pragma mark - Utils

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
     if (jsonString == nil) {
         return nil;
     }
     NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
     NSError *err;
     NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&err];
     if (err) {
         return nil;
     }
     return dic;
}

@end
