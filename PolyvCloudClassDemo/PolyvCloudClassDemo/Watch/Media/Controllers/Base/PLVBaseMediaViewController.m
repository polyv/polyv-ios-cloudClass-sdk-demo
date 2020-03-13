//
//  PLVBaseMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController.h"
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import <PolyvCloudClassSDK/PLVVideoMarquee.h>
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>

#define CloudClassBaseMediaErrorDomain @"net.polyv.cloudClassBaseMediaError"

@interface PLVBaseMediaViewController () <PLVPlayerSkinViewDelegate, PLVPlayerSkinMoreViewDelegate, PLVPlayerControllerDelegate>

@property (nonatomic, strong) PLVPlayerSkinView *skinView;//播放器的皮肤
@property (nonatomic, strong) PLVPlayerSkinMoreView *moreView;//更多弹窗视图
@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器
@property (nonatomic, strong) UIView *mainView;//主屏
@property (nonatomic, assign) BOOL skinShowed;//播放器皮肤是否已显示
@property (nonatomic, assign) BOOL skinAnimationing;//播放器皮肤显示隐藏动画的开关
@property (nonatomic, assign) CGRect fullRect;// 横屏时frame的大小
@property (nonatomic, strong) PLVVideoMarquee *videoMarquee; // 视频跑马灯
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, assign) BOOL iPad;
@property (nonatomic, assign) BOOL hadSetEnableDanmuModule;

@end

@implementation PLVBaseMediaViewController

#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    self.skinShowed = YES;
    self.view.autoresizingMask = UIViewAutoresizingNone;
    self.fullRect = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    // iPad 横屏的适配方式和 iPhone 有差异
    if([@"iPad" isEqualToString:[UIDevice currentDevice].model]) {
        self.iPad = YES;
    }

    CGRect mainRect = self.originFrame;
    
    CGFloat statusBarY = [UIApplication sharedApplication].statusBarFrame.size.height;
    if (@available(iOS 11.0, *)) {
        CGFloat topY = (([[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0) ? statusBarY : 20);
        mainRect.origin.y = topY;
    } else {
        mainRect.origin.y = 20;
    }
    mainRect.size.height -= mainRect.origin.y;
    self.mainView = [[UIView alloc] initWithFrame:mainRect];
    self.mainView.backgroundColor = BlueBackgroundColor;
    [self.view addSubview:self.mainView];
    
    // 单击显示或隐藏皮肤
    [self addTapGestureRecognizer];
    
    // 1秒后才可以旋屏，防止横屏时点击登录按钮i进来，导致布局错乱
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.canAutorotate = YES;
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    });
}

#pragma mark - addTapGestureRecognizer
- (void)addTapGestureRecognizer {
    [self removeTapGestureRecognizer];
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(skinTapAction)];
    [self.view addGestureRecognizer:self.tap];
}

#pragma mark - removeTapGestureRecognizer
- (void)removeTapGestureRecognizer {
    [self.view removeGestureRecognizer:self.tap];
    self.tap = nil;
}

#pragma mark - public
- (void)clearResource {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [self.player clearPlayersAndTimers];
}

#pragma mark - protected
- (void)loadSkinView:(PLVPlayerSkinViewType)skinType {
    self.skinView = [[PLVPlayerSkinView alloc] initWithFrame:self.mainView.frame];
    self.skinView.delegate = self;
    self.skinView.type = skinType;
    [self.view addSubview:self.skinView];
    [self.skinView loadSubviews];
    self.skinView.controllView.hidden = YES;
    
    // 更多弹窗视图
    self.moreView = [[PLVPlayerSkinMoreView alloc] initWithFrame:self.mainView.frame];
    NSInteger moreViewType = skinType;
    self.moreView.type = moreViewType;
    self.moreView.delegate = self;
    [self.view addSubview:self.moreView];
}

- (void)skinAlphaAnimaion:(CGFloat)alpha duration:(CGFloat)duration {
    self.skinAnimationing = YES;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.skinView.alpha = alpha;
        weakSelf.skinView.backBtn.alpha = alpha;
        weakSelf.skinView.zoomScreenBtn.alpha = alpha;
    } completion:^(BOOL finished) {
        weakSelf.skinAnimationing = NO;
        weakSelf.skinShowed = (alpha == 1.0 ? YES : NO);
    }];
}

- (void)skinHiddenAnimaion {
    [self skinAlphaAnimaion:0.0 duration:0.3];
}

- (void)backBtnShowNow {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(skinHiddenAnimaion) object:nil];
    [self skinAlphaAnimaion:0.0 duration:0.0];
    self.skinView.backBtn.alpha = 1.0;
    self.skinView.zoomScreenBtn.alpha = 1.0;
}

- (void)skinShowAnimaion {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(skinHiddenAnimaion) object:nil];
    [self skinAlphaAnimaion:1.0 duration:0.3];
    [self performSelector:@selector(skinHiddenAnimaion) withObject:nil afterDelay:3.0];
}

- (void)skinTapAction {
    if (!self.skinAnimationing) {
        if (self.skinShowed) {
            [self skinHiddenAnimaion];
        } else {
            [self skinShowAnimaion];
        }
    }
}

- (void)setEnableDanmuModule:(BOOL)enableDanmuModule{
    _enableDanmuModule = enableDanmuModule;
    [self refreshDanmuModuleState];
    _hadSetEnableDanmuModule = YES;
}

- (void)setShowDanmuOnPortrait:(BOOL)showDanmuOnPortrait{
    _showDanmuOnPortrait = showDanmuOnPortrait;
    [self refreshDanmuModuleState];
}

#pragma mark - protected - abstract
- (void)deviceOrientationBeignAnimation {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 重写
}

- (void)deviceOrientationEndAnimation {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 重写
}

- (void)deviceOrientationDidChangeSubAnimation {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 、 PLVNormalLiveMediaViewController 重写
}

- (CGRect)correctMainRect {
    CGRect mainRect = self.view.bounds;
    if (self.skinView.fullscreen) {
        mainRect = CGRectMake(0.0, 0.0, mainRect.size.width, mainRect.size.height);
        if (@available(iOS 11.0, *)) {
            CGRect safeFrame = self.view.superview.safeAreaLayoutGuide.layoutFrame;
            // 快速旋转时，safeAreaLayoutGuide 如果出现横竖屏错乱的情况，手动调整
            if (safeFrame.origin.y > 0.0) {
                safeFrame.origin = CGPointMake(safeFrame.origin.y, safeFrame.origin.x);
            }
            if (safeFrame.size.width < safeFrame.size.height) {
                safeFrame.size = CGSizeMake(mainRect.size.width - safeFrame.origin.x * 2.0, safeFrame.size.width);
            }
            mainRect.origin.x = safeFrame.origin.x;
            mainRect.size.width = safeFrame.size.width;
        }
    } else {
        mainRect.origin.y = 20.0;
        if (@available(iOS 11.0, *)) {
            CGRect safeFrame = self.view.superview.safeAreaLayoutGuide.layoutFrame;
            // 快速旋转时，safeAreaLayoutGuide 如果出现横竖屏错乱的情况，手动调整
            if (safeFrame.origin.x > 0.0) {
                safeFrame.origin = CGPointMake(safeFrame.origin.y, safeFrame.origin.x);
            }
            if (safeFrame.size.width > safeFrame.size.height) {
                safeFrame.size = CGSizeMake(safeFrame.size.height, safeFrame.size.width);
            }
            mainRect.origin.y = safeFrame.origin.y;
        }
        mainRect.size.height -= mainRect.origin.y;
    }
    return mainRect;
}

- (CGRect)getMainRect {
    return [self correctMainRect];
}

- (void)loadPlayer {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 重写
}

- (void)switchAction:(BOOL)manualControl {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 重写
}

- (void)loadPPTEnd {
//    在子类 PLVPPTLiveMediaViewController 重写
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)quit:(PLVPlayerSkinView *)skinView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(quit:error:)]) {
        [self.delegate quit:self error:nil];
    }
}

- (void)more:(PLVPlayerSkinView *)skinView{
    [self skinHiddenAnimaion];
    [self.moreView show];
}

//刷新弹幕模块的启用状态
- (void)refreshDanmuModuleState{
    if (self.skinView.type == PLVPlayerSkinViewTypeNormalVod ||
        self.skinView.type == PLVPlayerSkinViewTypeCloudClassVod) {
        return;
    }
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;

    if (self.hadSetEnableDanmuModule && (UIDeviceOrientationIsFlat(orientation) || orientation == UIDeviceOrientationUnknown)) {
        return;
    }
    
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
        if(self.enableDanmuModule){
            // 若希望横屏时无弹幕按钮、无弹幕，可将此处改为closeDanmuModule
            [self openDanmuModule];
        }else{
            [self closeDanmuModule];
        }
    } else {
        if(self.enableDanmuModule){
            // 竖屏是否有“弹幕按钮 + 弹幕”
            if (self.showDanmuOnPortrait) {
                [self openDanmuModule];
            }else{
                [self closeDanmuModule];
            }
        }else{
            [self closeDanmuModule];
        }
    }
}

// 启用弹幕模块
- (void)openDanmuModule{
    [self.skinView showDanmuBtn:YES];
    
    // 若希望启用弹幕模块时，弹幕默认不自动开启，可将为0判断移除
    if (self.skinView.openDanmuByUser == 0 || self.skinView.openDanmuByUser == 1) {
        self.skinView.danmuBtn.selected = YES;
        [self.skinView showDanmuInputBtn:(self.skinView.danmuBtn.selected && ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight))]; // 竖屏时无弹幕输入框
        [self playerSkinView:nil switchDanmu:YES];
    }
}

//禁用弹幕模块
- (void)closeDanmuModule{
    [self.skinView showDanmuBtn:NO];
    
    self.skinView.danmuBtn.selected = NO;
    [self.skinView showDanmuInputBtn:self.skinView.danmuBtn.selected];
    [self playerSkinView:nil switchDanmu:NO];
}

- (void)changeFrame:(BOOL)fullscreen block:(void (^)(void))block {
    if (fullscreen) {
        self.view.frame = self.fullRect;
        self.skinView.fullscreen = YES;
    } else {
        self.view.frame = self.originFrame;
        self.skinView.fullscreen = NO;
    }
    if (block) {
        block();
    }
    
    CGRect mainRect = [self getMainRect];
    self.mainView.frame = mainRect;
    
    CGRect skinRect = [self correctMainRect];
    if (self.skinView.fullscreen) {
        if ((skinRect.origin.x == 44.0 || self.iPad)) {
            skinRect.size.height -= 20.0;
        }
    }
    self.skinView.frame = skinRect;
    self.moreView.frame = skinRect;
    [self.skinView layout];
    
    [self refreshDanmuModuleState];
    [self deviceOrientationDidChangeSubAnimation];
}

//横竖屏旋转动画
- (void)deviceOrientationDidChange {
    BOOL iPhone = [@"iPhone" isEqualToString:[UIDevice currentDevice].model];
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (!UIDeviceOrientationIsValidInterfaceOrientation(orientation) || (iPhone && orientation == UIDeviceOrientationPortraitUpsideDown) || [PLVLiveVideoConfig sharedInstance].unableRotate || [PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate) {
        return;
    }
    
    [self deviceOrientationBeignAnimation];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf changeFrame:UIDeviceOrientationIsLandscape(orientation) block:^{
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(statusBarAppearanceNeedsUpdate:)]) {
                //delegate回调隐藏或显示statusBar，一定要放在最前前执行，因为layout时需要用到安全区域，而statusBar的隐藏或显示会影响安全区域的y坐标
                [weakSelf.delegate statusBarAppearanceNeedsUpdate:weakSelf];
            }
        }];
    } completion:^(BOOL finished) {
        [weakSelf deviceOrientationEndAnimation];
    }];
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController codeRateItems:(NSMutableArray *)codeRateItems codeRate:(NSString *)codeRate lines:(NSUInteger)lines line:(NSInteger)line {
    self.moreView.lines = lines;
    self.moreView.curLine = line;
    self.moreView.codeRateItems = codeRateItems;
    self.moreView.curCodeRate = codeRate;
}

- (void)playerController:(PLVPlayerController *)playerController showMessage:(NSString *)message {
    if (self.skinView.type == PLVPlayerSkinViewTypeNormalLive || self.skinView.type == PLVPlayerSkinViewTypeNormalVod) {
        [self.skinView showMessage:message];
    }else{
        if (![message isEqualToString:@"当前频道还未开播"]) {
            [self.skinView showMessage:message];
        }
    }
}
- (void)playerController:(PLVPlayerController *)playerController mainPlayerPlaybackDidFinish:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(player:playbackDidFinish:)]) {
        [self.delegate player:self.player playbackDidFinish:notification.userInfo];
    }
}

- (void)playerController:(PLVPlayerController *)playerController mainPlayerDidSeekComplete:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(playerDidSeekComplete:)]) {
        [self.delegate playerDidSeekComplete:self.player];
    }
}

- (void)playerController:(PLVPlayerController *)playerController mainPlayerAccurateSeekComplete:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(playerAccurateSeekComplete:)]) {
        [self.delegate playerAccurateSeekComplete:self.player];
    }
}

- (void)playerController:(PLVPlayerController *)playerController loadMainPlayerFailure:(NSString *)message {
    if ([self.delegate respondsToSelector:@selector(player:loadMainPlayerFailure:)]) {
        [self.delegate player:self.player loadMainPlayerFailure:message];
    }
}

#pragma mark - 跑马灯
- (void)setNickName:(NSString *)nickName {
    _nickName = nickName;
    if (self.videoMarquee && [self.player isKindOfClass:[PLVLivePlayerController class]]) {
        if (((PLVLivePlayerController *)self.player).channel.marqueeType == PLVLiveMarqueeTypeNick) {
            PLVMarqueeModel *model = self.videoMarquee.marqueeModel;
            model.content = nickName;
            self.videoMarquee.marqueeModel = model;
        }
    }
}

- (void)setupMarquee:(PLVLiveVideoChannel *)channel customNick:(NSString *)customNick  {
    if (self.videoMarquee) {
        return;
    }
    [self handleMarquee:channel customNick:customNick completion:^(PLVMarqueeModel *model, NSError *error) {
        if (model) {
            [self loadVideoMarqueeView:model];
        } else if (error) {
            if (error.code == PLVBaseMediaErrorCodeMarqueeFailed) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(quit:error:)]) {
                    [self.delegate quit:self error:error];
                }
            } else {
                NSLog(@"自定义跑马灯加载失败：%@",error);
            }
        } else {
            NSLog(@"无跑马灯或跑马灯不显示");
        }
    }];
}

- (void)loadVideoMarqueeView:(PLVMarqueeModel *)model {
    UIView *marqueeView = [[UIView alloc] initWithFrame:self.view.bounds];
    marqueeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    marqueeView.backgroundColor = [UIColor clearColor];
    marqueeView.userInteractionEnabled = NO;
    if (self.skinView) {
        [self.view insertSubview:marqueeView belowSubview:self.skinView];
    } else {
        [self.view addSubview:marqueeView];
    }
    
    self.videoMarquee = [PLVVideoMarquee videoMarqueeWithMarqueeModel:model];
    [self.videoMarquee showVideoMarqueeInView:marqueeView];
}

- (void)handleMarquee:(PLVLiveVideoChannel *)channel customNick:(NSString *)customNick completion:(void (^)(PLVMarqueeModel *model, NSError *error))completion {
    switch (channel.marqueeType) {
        case PLVLiveMarqueeTypeNick:
            if (customNick) {
                channel.marquee = customNick;
            } else {
                channel.marquee = @"自定义昵称";
            }
        case PLVLiveMarqueeTypeFixed: {
            float alpha = channel.marqueeOpacity.floatValue/100.0;
            PLVMarqueeModel *model = [PLVMarqueeModel marqueeModelWithContent:channel.marquee fontSize:channel.marqueeFontSize.unsignedIntegerValue fontColor:channel.marqueeFontColor alpha:alpha autoZoom:channel.marqueeAutoZoomEnabled];
            completion(model, nil);
        } break;
        case PLVLiveMarqueeTypeURL: {
            if (channel.marquee) {
                [PLVLiveVideoAPI loadCustomMarquee:[NSURL URLWithString:channel.marquee] withChannelId:channel.channelId.unsignedIntegerValue userId:channel.userId completion:^(BOOL valid, NSDictionary *marqueeDict) {
                    if (valid) {
                        completion([PLVMarqueeModel marqueeModelWithMarqueeDict:marqueeDict], nil);
                    } else {
                        NSError *error = [NSError errorWithDomain:CloudClassBaseMediaErrorDomain code:PLVBaseMediaErrorCodeMarqueeFailed userInfo:@{NSLocalizedDescriptionKey:marqueeDict[@"msg"]}];
                        completion(nil, error);
                    }
                } failure:^(NSError *error) {
                    completion(nil, error);
                }];
            }
        } break;
        default:
            completion(nil, nil);
            break;
    }
}

@end
