//
//  PLVLiveViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVLiveViewController.h"
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>
#import <PolyvBusinessSDK/PolyvBusinessSDK.h>
#import "PLVLiveMediaViewController.h"
#import "FTPageController.h"
#import "PLVChatroomManager.h"
#import "PLVChatroomController.h"
#import "PLVUtils.h"
#import "PLVEmojiModel.h"

#define PlayerViewScale (3.0 / 4.0)
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PLVLiveViewController () <PLVMediaViewControllerDelegate, PLVLiveMediaViewControllerDelegate, PLVSocketIODelegate, PLVChatroomDelegate>

@property (nonatomic, strong) PLVSocketIO *socketIO;
@property (nonatomic, strong) PLVSocketObject *login; // 登录对象

@property (nonatomic, strong) PLVLiveMediaViewController *mediaVC;
@property (nonatomic, strong) FTPageController *pageController;
@property (nonatomic, strong) PLVChatroomController *publicChatroomController;
@property (nonatomic, strong) PLVChatroomController *privateChatroomController;

@property (nonatomic, assign) NSUInteger channelId; // 当前频道号

@end

@implementation PLVLiveViewController

#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"-[%@ %@]",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    [self clearSocketIO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.channelId = [self.channel.channelId unsignedIntegerValue];
    
    __weak typeof(self) weakSelf = self;
    if ([PLVChatroomController havePermissionToWatchLive:self.channelId]) {
        [self setupUI];
        
        PLVLiveConfig *liveConfig = [PLVLiveConfig sharedInstance];
        [PLVLiveAPI requestAuthorizationForLinkingSocketWithChannelId:self.channelId Appld:liveConfig.appId appSecret:liveConfig.appSecret success:^(NSDictionary *responseDict) {
            [weakSelf initSocketIOWithTokenInfo:responseDict];
        } failure:^(NSError *error) {
            [PLVUtils showHUDWithTitle:@"聊天室Token获取失败！" detail:error.localizedDescription view:weakSelf.view];
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf showNoPermissionAlert:@"您未被授权观看本直播"];
        });
    }
}

#pragma mark -
- (void)setupUI {
    CGFloat y = 0.0;
    if (@available(iOS 11.0, *)) {
        y = [UIApplication sharedApplication].delegate.window.safeAreaLayoutGuide.layoutFrame.origin.y;
    }
    CGFloat h = self.view.bounds.size.width * PlayerViewScale + y;
    
    CGRect pageCtrlFrame = CGRectMake(0, h, SCREEN_WIDTH, SCREEN_HEIGHT - h);
    CGRect chatroomFrame = CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight);
    
    // public chatroom
    self.publicChatroomController = [PLVChatroomController chatroomWithType:PLVChatroomTypePublic roomId:self.channelId frame:chatroomFrame];
    self.publicChatroomController.delegate = self;
    [self.publicChatroomController loadSubViews];
    
    self.pageController = [[FTPageController alloc] initWithTitles:@[@"聊天"] controllers:@[self.publicChatroomController]];
    self.pageController.view.backgroundColor = [UIColor colorWithWhite:236/255.0 alpha:1];
    self.pageController.view.frame = pageCtrlFrame;
    [self.view addSubview:self.pageController.view];
    [self addChildViewController:self.pageController];
    
    [self addMediaViewController:h];
    
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI getChannelMenuInfos:self.channelId completion:^(PLVChannelMenuInfo *channelMenuInfo) {
        for (PLVChannelMenu *menu in channelMenuInfo.channelMenus) {
            if ([menu.menuType isEqualToString:@"quiz"]) {
                // private chatroom
                weakSelf.privateChatroomController = [PLVChatroomController chatroomWithType:PLVChatroomTypePrivate roomId:self.channelId frame:chatroomFrame];
                weakSelf.privateChatroomController.delegate = weakSelf;
                [weakSelf.privateChatroomController loadSubViews];
                [weakSelf.pageController addPageWithTitle:@"私聊" controller:weakSelf.privateChatroomController];
                break;
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"频道菜单获取失败！%@",error);
    }];
    [PLVLiveAPI loadChatroomFunctionSwitchWithRoomId:self.channelId completion:^(NSDictionary *switchInfo) {
        NSInteger code = [switchInfo[@"code"] integerValue];
        if (code == 200) {
            NSArray *dataArr = switchInfo[@"data"];
            for (NSDictionary *dict in dataArr) {
                if ([dict[@"type"] isEqualToString:@"chat"]) {
                    weakSelf.publicChatroomController.close = ![dict[@"enabled"] boolValue];
                    break;
                }
            }
        }else {
            NSLog(@"%@",switchInfo[@"message"]);
        }
    } failure:^(NSError *error) {
        NSLog(@"error:%@",error);
    }];
}

- (void)addMediaViewController:(CGFloat)h {
    self.mediaVC = [[PLVLiveMediaViewController alloc] init];
    self.mediaVC.delegate = self;
    self.mediaVC.liveDelegate = self;
    self.mediaVC.channel = self.channel;
    self.mediaVC.view.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, h);
    [self.view addSubview:self.mediaVC.view];
    CGFloat w = (int)([UIScreen mainScreen].bounds.size.width / 3.0);
    [self.mediaVC loadSecondaryView:CGRectMake(self.mediaVC.view.frame.size.width - w, self.mediaVC.view.frame.origin.y + self.mediaVC.view.frame.size.height + 44.0, w, (int)(w * PlayerViewScale))];
    
    __weak typeof(self)weakSelf = self;
    [self.channel updateChannelRestrictInfo:^(PLVLiveChannel *channel) {
        switch (channel.restrictState) {
            case PLVLiveRestrictNone : {
                break;
            }
            case PLVLiveRestrictPlay: {
                [weakSelf showNoPermissionAlert:@"该频道设置了限制条件"];
                break;
            }
            default: {
                [weakSelf showNoPermissionAlert:@"该频道的限制条件获取失败，请重新登录"];
                break;
            }
        }
    }];
}

#pragma mark - Private
- (void)exitCurrentController {
    // if-else 退出当前页面，模态进来就 dismissViewController
    [self.mediaVC clearResource];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showNoPermissionAlert:(NSString *)message {
    __weak typeof(self)weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf exitCurrentController];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - SocketIO
- (void)initSocketIOWithTokenInfo:(NSDictionary *)responseDict {
    // 初始化 socketIO 连接对象
    self.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:responseDict[@"chat_token"] enableLog:NO];
    self.socketIO.delegate = self;
    //self.socketIO.debugMode = YES;
    [self.socketIO connect];
    
    // 初始化登录对象，nickName、avatarUrl 为空时会使用默认昵称、头像地址
    self.login = [PLVSocketObject socketObjectForLoginEventWithRoomId:self.channelId nickName:self.nickName avatar:self.avatarUrl userType:PLVSocketObjectUserTypeSlice];
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

#pragma mark <PLVSocketIODelegate>
// 此方法可能多次调用，如锁屏后返回会重连聊天室
- (void)socketIO:(PLVSocketIO *)socketIO didConnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@", NSStringFromSelector(_cmd), info);
    [socketIO emitMessageWithSocketObject:self.login];   // 登录聊天室
}

- (void)socketIO:(PLVSocketIO *)socketIO didUserStateChange:(PLVSocketUserState)userState {
    NSLog(@"%@--userState:%ld", NSStringFromSelector(_cmd), (long)userState);
    [PLVUtils showChatroomMessage:PLVNameStringWithSocketUserState(userState) addedToView:self.pageController.view];
    if (userState == PLVSocketUserStateLogined) {
        [PLVChatroomManager sharedManager].socketUser = socketIO.user;
        self.publicChatroomController.socketUser = socketIO.user;
        if (self.privateChatroomController) {
            self.privateChatroomController.socketUser = socketIO.user;
        }
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceivePublicChatMessage:(PLVSocketChatRoomObject *)chatObject {
    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)chatObject.eventType, chatObject.event);
    [self.publicChatroomController addNewChatroomObject:chatObject];
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceivePrivateChatMessage:(PLVSocketChatRoomObject *)chatObject {
    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)chatObject.eventType, chatObject.event);
    if (self.privateChatroomController) {
        [self.privateChatroomController addNewChatroomObject:chatObject];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveLinkMicMessage:(PLVSocketLinkMicObject *)linkMicObject {
    NSLog(@"%@--type:%lu, event:%@", NSStringFromSelector(_cmd), (unsigned long)linkMicObject.eventType, linkMicObject.event);
    [self.mediaVC.linkMicVC handleLinkMicObject:linkMicObject];
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceivePPTMessage:(NSString *)json {
    [self.mediaVC refreshPPT:json];
}

- (void)socketIO:(PLVSocketIO *)socketIO didReceiveQuestionMessage:(NSString *)json result:(int)result {
    if (result == 0) {
        [self.mediaVC openQuestionContent:json];
    } else if (result == 1) {
        [self.mediaVC openQuestionResult:json];
    } else if (result == 2) {
        [self.mediaVC testQuestion:json];
    }
}

- (void)socketIO:(PLVSocketIO *)socketIO didDisconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PLVUtils showChatroomMessage:@"聊天室失去连接" addedToView:self.pageController.view];
}

- (void)socketIO:(PLVSocketIO *)socketIO connectOnErrorWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PLVUtils showChatroomMessage:@"聊天室连接失败" addedToView:self.pageController.view];
}

- (void)socketIO:(PLVSocketIO *)socketIO reconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [PLVUtils showChatroomMessage:@"聊天室重连中..." addedToView:self.pageController.view];
}

- (void)socketIO:(PLVSocketIO *)socketIO localError:(NSString *)description {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),description);
}

#pragma mark <PLVChatroomDelegate>
- (void)chatroom:(PLVChatroomController *)chatroom didOpenError:(PLVChatroomErrorCode)code {
    if (code==PLVChatroomErrorCodeBeKicked) {
        [self showNoPermissionAlert:@"您未被授权观看本直播"];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom emitSocketObject:(PLVSocketChatRoomObject *)object {
    if (self.socketIO.socketIOState == PLVSocketIOStateConnected) {
        [self.socketIO emitMessageWithSocketObject:object];
    }else {
        [PLVUtils showChatroomMessage:@"聊天室未连接！" addedToView:self.pageController.view];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom nickNameRenamed:(NSString *)newName success:(BOOL)success message:(NSString *)message {
    [PLVUtils showChatroomMessage:message addedToView:self.pageController.view];
    if (success) {
        self.nickName = newName;
        [self.login renameNickname:newName];
    }
}

- (void)chatroom:(PLVChatroomController *)chatroom followKeyboardAnimation:(BOOL)flag {
    [self.mediaVC followKeyboardAnimation:flag];
}

- (void)chatroom:(PLVChatroomController *)chatroom didSendSpeakContent:(NSString *)content {
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:content font:[UIFont systemFontOfSize:14]];
    [self.mediaVC danmu:attributedStr];
}

#pragma mark <PLVMediaViewControllerDelegate>
- (void)quit:(PLVMediaViewController *)mediaVC {
    [self exitCurrentController];
}

- (void)statusBarAppearanceNeedsUpdate:(PLVMediaViewController *)mediaVC {
    [self setNeedsStatusBarAppearanceUpdate];//横竖屏切换前，更新Status Bar的状态
    if ([self.mediaVC fullscreen]) {
        [self.publicChatroomController.inputView tapAction];
        [self.privateChatroomController.inputView tapAction];
    }
}

#pragma mark <PLVLiveMediaViewControllerDelegatet>
- (void)liveMediaViewController:(PLVLiveMediaViewController *)liveVC chooseAnswer:(NSDictionary *)dict {
    NSString *nickName = self.socketIO.user.nickName;
    NSDictionary *baseJSON = @{@"EVENT" : @"ANSWER_TEST_QUESTION", @"roomId" : [NSString stringWithFormat:@"%lu", (unsigned long)self.socketIO.roomId], @"nick" : nickName, @"userId" : self.socketIO.userId};
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json addEntriesFromDictionary:baseJSON];
    [json addEntriesFromDictionary:dict];
    PLVSocketTriviaCardObject *triviaCard = [PLVSocketTriviaCardObject socketObjectWithJsonDict:json];
    [self.socketIO emitMessageWithSocketObject:triviaCard];
}

- (void)liveMediaViewController:(PLVLiveMediaViewController *)liveVC emitLinkMicObject:(PLVSocketLinkMicEventType)eventType {
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channel.channelId.integerValue userNick:self.login.nickName userPic:self.login.avatar userId:(NSUInteger)self.login.userId.longLongValue userType:PLVSocketObjectUserTypeSlice];
    [self.socketIO emitMessageWithSocketObject:linkMicObject];
}

- (void)liveMediaViewController:(PLVLiveMediaViewController *)liveVC emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback {
    PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channel.channelId.integerValue userNick:self.login.nickName userPic:self.login.avatar userId:(NSUInteger)self.login.userId.longLongValue userType:PLVSocketObjectUserTypeSlice];
    [self.socketIO emitACKWithSocketObject:linkMicObject after:after callback:callback];
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {//设备方向旋转，横竖屏切换，但UIViewController不需要旋转，在播放器的父类里自己实现旋转的动画效果
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    if ([self.mediaVC fullscreen]) {//横屏时，隐藏Status Bar
        return YES;
    } else {
        return NO;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {//Status Bar颜色随底色高亮变化
    return UIStatusBarStyleLightContent;
}

@end
