//
//  PLVVodViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVVodViewController.h"
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import "PLVNormalVodMediaViewController.h"
#import "PLVPPTVodMediaViewController.h"
#import "FTPageController.h"
#import "PLVLiveInfoViewController.h"
#import "PLVChatPlaybackController.h"
#import "PCCUtils.h"
#import "PLVReachabilityManager.h"
#import <Masonry/Masonry.h>

#define PPTPlayerViewScale (9.0 / 16.0)
#define NormalPlayerViewScale (9.0 / 16.0)

@interface PLVVodViewController () <PLVBaseMediaViewControllerDelegate, PLVChatPlaybackControllerDelegate>

@property (nonatomic, strong) PLVBaseMediaViewController<PLVVodMediaProtocol> *mediaVC;
@property (nonatomic, assign) CGFloat mediaViewControllerHeight;
@property (nonatomic, assign) CGRect chatroomFrame;
@property (nonatomic, strong) FTPageController *pageController;
@property (nonatomic, strong) PLVLiveInfoViewController *liveInfoViewController;
@property (nonatomic, strong) PLVChatPlaybackController *chatPlaybackCtl;

@property (nonatomic, strong) NSTimer *pollingTimer;

@property (nonatomic, strong) UILabel *mobileInternetDataTipsLable;

@end

@implementation PLVVodViewController

#pragma mark - life cycle
- (void)dealloc {
    [PLVReachabilityManager destoryWithTarget:self];
    NSLog(@"%s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.vodType == PLVVodViewControllerTypeCloudClass) {
        if (self.vodList) {
            NSLog(@"三分屏场景暂不支持使用点播列表播放!!!");
            return;
        }
        self.mediaVC = [[PLVPPTVodMediaViewController alloc] init];
    } else {
        self.mediaVC = [[PLVNormalVodMediaViewController alloc] init];
        self.mediaVC.vodList = self.vodList; // 是否点播列表视频
    }
    self.mediaVC.delegate = self;
    
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    self.mediaVC.vodId = liveConfig.vodId; //必须，不能为空
    self.mediaVC.channelId = liveConfig.channelId;
    self.mediaVC.userId = liveConfig.userId;
    
    self.mediaViewControllerHeight = self.view.bounds.size.width * (self.vodType == PLVVodViewControllerTypeCloudClass ? PPTPlayerViewScale : NormalPlayerViewScale) + [PCCUtils getStatusBarHeight];
    self.mediaVC.originFrame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.mediaViewControllerHeight);
    self.mediaVC.view.frame = self.mediaVC.originFrame;
    [self.view addSubview:self.mediaVC.view];
    
    /// 如果不需要显示直播介绍的tab的话，可以注释这句代码
    [self loadChannelMenuInfos];
    
    if (self.vodType == PLVVodViewControllerTypeCloudClass) {
        CGFloat w = (int)([UIScreen mainScreen].bounds.size.width / 3.0);
        [(PLVPPTVodMediaViewController *)self.mediaVC loadSecondaryView:CGRectMake(self.view.frame.size.width - w, self.mediaViewControllerHeight + self.pageController.barHeight, w, (int)(w * PPTPlayerViewScale))];
    }
    self.mediaVC.player.pauseInBackground = YES; // 默认回后台暂停
    
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(playerPolling) userInfo:nil repeats:YES];
    
    /// 检查当前网络
    [self checkCurrentNetworkStatus];
    /// 监听当前网络类型
    [PLVReachabilityManager listenNetWorkingStatusWithTarget:self selector:@selector(networkChanged:)];
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
    //NSLog(@"观看时长：%ld，停留时长：%ld", self.mediaVC.player.watchDuration, self.mediaVC.player.stayDuration);
    if (self.chatPlaybackCtl) {
        [self.chatPlaybackCtl scrollToTime:self.mediaVC.player.currentPlaybackTime];
    }
}

- (void)networkChanged:(NSNotification *)notification {
    PLVReachability *reachability = (PLVReachability*)notification.object;
    if ([reachability currentReachabilityStatus] == PLVReachableViaWWAN) {
        [self showUseMobileInternetDataTips];
    }
}

- (void)loadChannelMenuInfos {
    if (self.channelMenuInfo) {
        [self setupChatroomItem];
    } else {
        __weak typeof(self) weakSelf = self;
        [PLVLiveVideoAPI getChannelMenuInfos:self.mediaVC.channelId.integerValue completion:^(PLVLiveVideoChannelMenuInfo *channelMenuInfo) {
            weakSelf.channelMenuInfo = channelMenuInfo;
            [weakSelf setupChatroomItem];
        } failure:^(NSError *error) {
            NSLog(@"频道菜单获取失败！%@",error);
        }];
    }
}

- (void)setupChatroomItem {
    CGFloat barHeight = 44.0;
    CGRect pageCtrlFrame = CGRectMake(0, self.mediaViewControllerHeight, self.view.frame.size.width, self.view.frame.size.height - self.mediaViewControllerHeight);
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
        }
    }
    
    self.chatPlaybackCtl = [[PLVChatPlaybackController alloc] initChatPlaybackControllerWithVid:[PLVLiveVideoConfig sharedInstance].vodId  frame:self.chatroomFrame];
    self.chatPlaybackCtl.delegate = self;
    [self.chatPlaybackCtl loadSubViews:self.view];
    [self.chatPlaybackCtl configUserInfoWithNick:nil pic:nil userId:nil];
    [titles addObject:@"聊天信息"];
    [controllers addObject:self.chatPlaybackCtl];
    
    if (titles.count>0 && controllers.count>0 && titles.count==controllers.count) {
        self.pageController = [[FTPageController alloc] init];
        self.pageController.view.frame = pageCtrlFrame;
        [self.pageController setTitles:titles controllers:controllers barHeight:barHeight touchHeight:0.0];
        [self.view insertSubview:self.pageController.view belowSubview:self.mediaVC.view];  // 需要添加在播放器下面，使得播放器全屏的时候能盖住聊天室
        [self addChildViewController:self.pageController];
        [self.pageController cornerRadius:NO];
    }
}

- (void)setupLiveInfoViewController:(PLVLiveVideoChannelMenuInfo *)channelMenuInfo :(PLVLiveVideoChannelMenu *)descMenu {
    self.liveInfoViewController = [[PLVLiveInfoViewController alloc] init];
    self.liveInfoViewController.channelMenuInfo = channelMenuInfo;
    self.liveInfoViewController.menu = descMenu;
    self.liveInfoViewController.vod = YES;
    self.liveInfoViewController.view.frame = self.chatroomFrame;
}

#pragma mark - Network
- (void)checkCurrentNetworkStatus {
    PLVNetworkStatus status = [PLVReachabilityManager currentReachabilityStatus];
    if (status == PLVReachableViaWWAN) {
        [self showUseMobileInternetDataTips];
    }
}

- (void)showUseMobileInternetDataTips {
    [self.mediaVC.view addSubview:self.mobileInternetDataTipsLable];
    [self.mobileInternetDataTipsLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_offset(0);
        make.height.mas_equalTo(33);
        make.width.mas_equalTo(220);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mobileInternetDataTipsLable removeFromSuperview];
    });
}

#pragma mark - <PLVChatPlaybackControllerDelegate>

- (NSTimeInterval)currentPlaybackTime {
    return self.mediaVC.player.currentPlaybackTime;
}

- (NSTimeInterval)videoDurationTime {
    return self.mediaVC.player.duration;
}

- (void)playbackController:(PLVChatPlaybackController *)playbackController followKeyboardAnimation:(BOOL)flag {
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {
    return self.mediaVC != nil && self.mediaVC.canAutorotate;
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

#pragma mark - PLVBaseMediaViewControllerDelegate
- (void)quit:(PLVBaseMediaViewController *)mediaVC error:(NSError *)error {
    [self.mediaVC clearResource];
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

- (void)statusBarAppearanceNeedsUpdate:(PLVBaseMediaViewController *)mediaVC {
    [self setNeedsStatusBarAppearanceUpdate];//横竖屏切换前，更新Status Bar的状态
}

- (void)playerDidSeekComplete:(PLVPlayerController<PLVPlayerControllerProtocol> *)player {
    if (self.chatPlaybackCtl) {
        [self.chatPlaybackCtl seekToTime:player.currentPlaybackTime];
    }
}

- (void)player:(PLVPlayerController<PLVPlayerControllerProtocol> *)player playbackDidFinish:(NSDictionary *)userInfo {
    NSLog(@"userInfo: %@",userInfo);
}

- (void)player:(PLVPlayerController<PLVPlayerControllerProtocol> *)player loadMainPlayerFailure:(NSString *)message {
    [PCCUtils showHUDWithTitle:message detail:nil view:self.view];
}

#pragma mark - getter
- (UILabel *)mobileInternetDataTipsLable {
    if (!_mobileInternetDataTipsLable) {
        _mobileInternetDataTipsLable = [[UILabel alloc]init];
        _mobileInternetDataTipsLable.text = @"当前非Wi-Fi环境，请注意流量消耗";
        [_mobileInternetDataTipsLable setTextColor:[UIColor whiteColor]];
        _mobileInternetDataTipsLable.backgroundColor = [UIColor blackColor];
        _mobileInternetDataTipsLable.font = [UIFont systemFontOfSize:12.0];
        _mobileInternetDataTipsLable.alpha = 0.5;
        _mobileInternetDataTipsLable.textAlignment = NSTextAlignmentCenter;
        
        _mobileInternetDataTipsLable.layer.cornerRadius = 18;
        _mobileInternetDataTipsLable.layer.masksToBounds = YES;
        _mobileInternetDataTipsLable.layer.borderColor = [UIColor blackColor].CGColor;
        _mobileInternetDataTipsLable.layer.borderWidth = 1.0;
    }
    return _mobileInternetDataTipsLable;
}

@end
