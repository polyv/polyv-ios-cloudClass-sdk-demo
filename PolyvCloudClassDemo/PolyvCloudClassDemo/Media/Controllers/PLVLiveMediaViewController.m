//
//  PLVLiveMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVLiveMediaViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <PolyvCloudClassSDK/PLVLivePlayerController.h>
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>
#import "PLVMediaViewControllerPrivateProtocol.h"
#import "PLVMediaViewControllerProtocol.h"
#import "ZJZDanMu.h"

@interface PLVLiveMediaViewController () <PLVMediaViewControllerPrivateProtocol, PLVMediaViewControllerProtocol, PLVLivePlayerControllerDelegate, PLVPlayerSkinViewDelegate, PLVLinkMicControllerDelegate>

@property (nonatomic, strong) ZJZDanMu *danmuLayer;//弹幕控件
@property (nonatomic, strong) PLVLinkMicController *linkMicVC;//连麦
@property (nonatomic, assign) BOOL reOpening;//正在加载channelJSON

@end

@implementation PLVLiveMediaViewController

@synthesize player;
@synthesize pptVC;
@synthesize skinView;
@synthesize mainView;
@synthesize secondaryView;
@synthesize originSecondaryFrame;
@synthesize pptOnSecondaryView;
@synthesize pptFlag;

- (void)clearResource {
    [super clearResource];
    [self.linkMicVC clearResource];
}

- (void)loadSecondaryView:(CGRect)rect {
    [super loadSecondaryView:rect];
    
    self.linkMicVC.originSecondaryFrame = self.originSecondaryFrame;
    self.linkMicVC.view.frame = CGRectMake(0.0, rect.origin.y, self.view.bounds.size.width, rect.size.height);
    [self.view.superview addSubview:self.linkMicVC.view];
}

- (void)addDanmuLayer {
    if (self.danmuLayer == nil) {
        CGRect danmuRect = self.mainView.bounds;
        if (@available(iOS 11.0, *)) {
            danmuRect = self.mainView.safeAreaLayoutGuide.layoutFrame;
        }
        self.danmuLayer = [[ZJZDanMu alloc] initWithFrame:danmuRect];
        self.danmuLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:self.danmuLayer belowSubview:self.skinView];
    }
}

- (void)danmu:(NSMutableAttributedString *)message {
    [self addDanmuLayer];
    [self.danmuLayer insertScrollDML:message];
}

- (void)openQuestionContent:(NSString *)json {
    [(PLVLivePlayerController *)self.player openQuestionContent:json];
}

- (void)openQuestionResult:(NSString *)json {
    [(PLVLivePlayerController *)self.player openQuestionResult:json];
}

- (void)testQuestion:(NSString *)json {
    [(PLVLivePlayerController *)self.player testQuestion:json];
}

- (void)refreshPPT:(NSString *)json {
    if ([json containsString:@"\"isCamClosed\":1"]) {//推流端关闭了摄像头
        if (self.pptOnSecondaryView && !self.player.playingAD && !((PLVLivePlayerController *)self.player).linkMic) {//自动切换主屏为PPT，副屏为视频
            self.pptFlag = YES;
            [self switchAction:NO];
        }
        
        ((PLVLivePlayerController *)self.player).cameraClosed = YES;
        if (!self.pptOnSecondaryView && !self.secondaryView.hidden) {//而iOS端，副屏为视频且已经打开，则自动关闭副屏
            [self closeSecondaryView:self.secondaryView];
        }
    } else if ([json containsString:@"\"isCamClosed\":0"]) {//推流端打开了摄像头
        ((PLVLivePlayerController *)self.player).cameraClosed = NO;
        if (!self.player.playingAD && self.player.playable && !self.pptOnSecondaryView && self.secondaryView.hidden) {//而iOS端，正在播放直播（非广告），副屏为视频且已经关闭，则自动打开副屏
            [self openSecondaryView];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.pptVC refreshPPT:json];
    });
}

- (void)followKeyboardAnimation:(BOOL)flag {
    if (flag) {
        CGRect secondaryRect = self.secondaryView.frame;
        secondaryRect = CGRectMake(self.view.frame.size.width - secondaryRect.size.width, self.view.frame.origin.y + self.view.frame.size.height - secondaryRect.size.height, secondaryRect.size.width, secondaryRect.size.height);
        self.secondaryView.frame = secondaryRect;
        
        CGRect linkMicRect = self.linkMicVC.view.frame;
        linkMicRect = CGRectMake(0.0, self.view.frame.origin.y + self.view.frame.size.height - linkMicRect.size.height, linkMicRect.size.width, linkMicRect.size.height);
        self.linkMicVC.view.frame = linkMicRect;
        [self.view insertSubview:self.linkMicVC.view belowSubview:self.skinView];;
    } else {
        self.secondaryView.frame = self.originSecondaryFrame;
        self.linkMicVC.view.frame = CGRectMake(0.0, self.originSecondaryFrame.origin.y, self.view.bounds.size.width, self.originSecondaryFrame.size.height);
        [self.view.superview addSubview:self.linkMicVC.view];
    }
}

- (void)loadPlayer {
    [self closeSecondaryView:self.secondaryView];
    self.player = [[PLVLivePlayerController alloc] initWithChannel:self.channel displayView:self.secondaryView delegate:self];
}

- (void)reOpenPlayer:(NSString *)codeRate showHud:(BOOL)showHud {
    if (self.reOpening || ((PLVLivePlayerController *)self.player).linkMic) {
        return ;
    }
    self.reOpening = YES;
    MBProgressHUD *hud = nil;
    if (showHud) {
        hud = [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
        [hud.label setText:@"加载JSON..."];
    }
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveAPI loadChannelInfoRepeatedlyWithUserId:self.channel.userId channelId:self.channel.channelId.integerValue completion:^(PLVLiveChannel *channel) {
        weakSelf.reOpening = NO;
        if (hud != nil) {
            hud.label.text = @"JSON加载成功";
            [hud hideAnimated:YES];
        }
        
        weakSelf.channel = channel;
        if (codeRate != nil && codeRate.length > 0) {
            [weakSelf.channel updateDefaultDefinitionWithDefinition:codeRate];
        }
        
        [weakSelf.player clearAllPlayer];
        ((PLVLivePlayerController*)weakSelf.player).channel = weakSelf.channel;
        [weakSelf.player loadMainPlayer];
    } failure:^(NSError *error) {
        weakSelf.reOpening = NO;
        if (hud != nil) {
            hud.label.text = @"JSON加载失败";
            [hud hideAnimated:YES];
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *codeRateItems = [[NSMutableArray alloc] init];
    for (NSDictionary *definition in self.channel.definitions) {
        [codeRateItems addObject:definition[@"definition"]];
    }
    [self loadSkinView:PLVPlayerSkinViewTypeLive codeRateItems:codeRateItems codeRate:self.channel.defaultDefinition];
    
    self.linkMicVC = [[PLVLinkMicController alloc] init];
    self.linkMicVC.delegate = self;
    self.linkMicVC.skinView = self.skinView;
}

- (void)deviceOrientationDidChangeSubAnimation:(CGAffineTransform)transform {
    if (self.skinView.fullscreen) {
        [self.view insertSubview:self.linkMicVC.view belowSubview:self.skinView];
        CGRect rect = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, self.linkMicVC.view.frame.size.height);
        if (@available(iOS 11.0, *)) {
            CGRect safeFrame = [UIApplication sharedApplication].delegate.window.safeAreaLayoutGuide.layoutFrame;
            rect.origin.x = safeFrame.origin.x;
            rect.size.width -= rect.origin.x * 2.0;
        }
        self.linkMicVC.view.frame = rect;
    } else {
        self.linkMicVC.view.frame = CGRectMake(0.0, self.secondaryView.frame.origin.y, self.view.bounds.size.width, self.secondaryView.frame.size.height);
        [self.view.superview addSubview:self.linkMicVC.view];
    }
}

- (void)switchAction:(BOOL)manualControl {
    if (self.linkMicVC.linkMicViewArray.count > 0) {
        PLVLinkMicView *linkMicView = [self.linkMicVC.linkMicViewArray objectAtIndex:0];
        self.pptOnSecondaryView = !self.pptOnSecondaryView;
        if (!self.pptOnSecondaryView) {
            UIView *videoView = self.mainView.subviews[0];
            [linkMicView insertSubview:videoView belowSubview:linkMicView.nickNameLabel];
            [videoView setFrame:linkMicView.bounds];
            [self.mainView addSubview:self.pptVC.view];
            self.pptVC.view.frame = self.mainView.bounds;
        } else {
            if (manualControl) {
                self.pptFlag = manualControl;
            }
            UIView *videoView = linkMicView.mainView;
            [self.mainView addSubview:videoView];
            [videoView setFrame:self.mainView.bounds];
            [linkMicView insertSubview:self.pptVC.view belowSubview:linkMicView.nickNameLabel];
            self.pptVC.view.frame = linkMicView.bounds;
        }
    } else {
        [super switchAction:manualControl];
    }
}

//======PLVPlayerSkinViewDelegate======
- (void)refreshLive:(PLVPlayerSkinView *)skinView {
    [self reOpenPlayer:nil showHud:YES];
}

- (void)linkMic:(PLVPlayerSkinView *)skinView {
    [self.linkMicVC linkMic];
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView switchDanmu:(BOOL)switchDanmu {
    [self addDanmuLayer];
    self.danmuLayer.hidden = !switchDanmu;
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate {
    [self reOpenPlayer:codeRate showHud:NO];
}

//============PLVLivePlayerControllerDelegate============
- (void)livePlayerController:(PLVLivePlayerController *)livePlayer streamState:(PLVLiveStreamState)streamState {
    if (streamState == PLVLiveStreamStateNoStream) {//没直播流
        self.skinView.controllView.hidden = YES;
        self.pptFlag = NO;
        self.pptVC.pptPlayable = NO;
        if (!self.secondaryView.hidden) {//副屏已经打开，则自动关闭副屏
            [self closeSecondaryView:self.secondaryView];
        }
    }
}

- (void)reconnectPlayer:(PLVLivePlayerController *)livePlayer {
    [self reOpenPlayer:nil showHud:NO];
}

- (void)livePlayerController:(PLVLivePlayerController *)livePlayerVC chooseAnswer:(NSDictionary *)dict {
    if (self.liveDelegate && [self.liveDelegate respondsToSelector:@selector(liveMediaViewController:chooseAnswer:)]) {
        [self.liveDelegate liveMediaViewController:self chooseAnswer:dict];
    }
}

//============PLVLinkMicControllerDelegate============
- (void)linkMicController:(PLVLinkMicController *)lickMic emitLinkMicObject:(PLVSocketLinkMicEventType)eventType {
    if (self.liveDelegate && [self.liveDelegate respondsToSelector:@selector(liveMediaViewController:emitLinkMicObject:)]) {
        [self.liveDelegate liveMediaViewController:self emitLinkMicObject:eventType];
    }
}

- (void)linkMicController:(PLVLinkMicController *)lickMic emitAck:(PLVSocketLinkMicEventType)eventType after:(double)after callback:(void (^)(NSArray * _Nonnull))callback {
    if (self.liveDelegate && [self.liveDelegate respondsToSelector:@selector(liveMediaViewController:emitAck:after:callback:)]) {
        [self.liveDelegate liveMediaViewController:self emitAck:eventType after:after callback:callback];
    }
}

- (void)linkMicSuccess:(PLVLinkMicController *)lickMic {
    self.secondaryView.alpha = 0.0;
    if (self.secondaryView.hidden) {
        [self openSecondaryView];
    }
    if (self.pptOnSecondaryView) {
        [super switchAction:NO];
    }
    ((PLVLivePlayerController*)self.player).linkMic = YES;
    [self.player clearAllPlayer];
}

- (void)cancelLinkMic:(PLVLinkMicController *)lickMic {
    if (self.pptOnSecondaryView) {
        UIView *videoView = self.mainView.subviews[0];
        [videoView removeFromSuperview];
        [super switchAction:NO];
    }
    self.secondaryView.alpha = 1.0;
    ((PLVLivePlayerController*)self.player).linkMic = NO;
    [self reOpenPlayer:nil showHud:NO];
}

@end
