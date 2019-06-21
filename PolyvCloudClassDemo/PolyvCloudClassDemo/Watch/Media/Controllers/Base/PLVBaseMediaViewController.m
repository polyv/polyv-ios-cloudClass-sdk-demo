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
@property (nonatomic, assign) BOOL iPad;

@end

@implementation PLVBaseMediaViewController

#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.skinShowed = YES;
    self.view.autoresizingMask = UIViewAutoresizingNone;
    self.fullRect = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    // iPad 横屏的适配方式和 iPhone 有差异
    if([@"iPad" isEqualToString:[UIDevice currentDevice].model]) {
        self.iPad = YES;
    }

    self.mainView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.mainView.backgroundColor = BlueBackgroundColor;
    [self.view addSubview:self.mainView];
    
    // 单击显示或隐藏皮肤
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(skinTapAction)];
    [self.view addGestureRecognizer:tap];
    
    // 1秒后才可以旋屏，防止横屏时点击登录按钮i进来，导致布局错乱
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.canAutorotate = YES;
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CGRect mainRect = self.view.bounds;
    mainRect.origin.y = 20.0;
    if (@available(iOS 11.0, *)) {
        mainRect.origin.y = self.view.superview.safeAreaLayoutGuide.layoutFrame.origin.y;
    }
    mainRect.size.height -= mainRect.origin.y;
    self.mainView.frame = mainRect;
    self.skinView.frame = mainRect;
    self.moreView.frame = mainRect;
}

#pragma mark - public
- (void)clearResource {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [self.player clearPlayersAndTimers];
}

#pragma mark - protected
- (void)loadSkinView:(PLVPlayerSkinViewType)skinType {
    self.skinView = [[PLVPlayerSkinView alloc] initWithFrame:self.view.bounds];
    self.skinView.delegate = self;
    self.skinView.type = skinType;
    [self.view addSubview:self.skinView];
    [self.skinView loadSubviews];
    self.skinView.controllView.hidden = YES;
    
    // 更多弹窗视图
    self.moreView = [[PLVPlayerSkinMoreView alloc] initWithFrame:self.view.bounds];
    NSInteger moreViewType = skinType;
    self.moreView.type = moreViewType;
    self.moreView.delegate = self;
    [self.view addSubview:self.moreView];
}

- (void)skinAlphaAnimaion:(CGFloat)alpha {
    self.skinAnimationing = YES;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.skinView.alpha = alpha;
    } completion:^(BOOL finished) {
        weakSelf.skinAnimationing = NO;
        weakSelf.skinShowed = (alpha == 1.0 ? YES : NO);
    }];
}

- (void)skinHiddenAnimaion {
    [self skinAlphaAnimaion:0.0];
}

- (void)skinShowAnimaion {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(skinHiddenAnimaion) object:nil];
    [self skinAlphaAnimaion:1.0];
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
}

- (void)setShowDanmuOnPortrait:(BOOL)showDanmuOnPortrait{
    _showDanmuOnPortrait = showDanmuOnPortrait;
    [self refreshDanmuModuleState];
}

#pragma mark - protected - abstract
- (void)deviceOrientationDidChangeSubAnimation {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 、 PLVNormalLiveMediaViewController 重写
}

- (void)loadPlayer {
    // 在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 重写
}

- (void)switchAction:(BOOL)manualControl {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 重写
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

    if (UIDeviceOrientationIsFlat(orientation) || orientation == UIDeviceOrientationUnknown) {
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

//横竖屏旋转动画
- (void)deviceOrientationDidChange {
    BOOL iPhone = [@"iPhone" isEqualToString:[UIDevice currentDevice].model];
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsFlat(orientation) || (iPhone && orientation == UIDeviceOrientationPortraitUpsideDown) || [PLVLiveVideoConfig sharedInstance].unableRotate || [PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (UIDeviceOrientationIsLandscape(orientation)) {
            weakSelf.view.frame = weakSelf.fullRect;
            weakSelf.skinView.fullscreen = YES;
        } else {
            weakSelf.view.frame = weakSelf.originFrame;
            weakSelf.skinView.fullscreen = NO;
        }
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(statusBarAppearanceNeedsUpdate:)]) {
            //delegate回调隐藏或显示statusBar，一定要放在最前前执行，因为layout时需要用到安全区域，而statusBar的隐藏或显示会影响安全区域的y坐标
            [weakSelf.delegate statusBarAppearanceNeedsUpdate:weakSelf];
        }
        
        CGRect mainRect = weakSelf.view.bounds;
        if (weakSelf.skinView.fullscreen) {
            if (@available(iOS 11.0, *)) {
                CGRect safeFrame = weakSelf.view.superview.safeAreaLayoutGuide.layoutFrame;
                // 快速旋转时，safeAreaLayoutGuide 如果出现横竖屏错乱的情况，手动调整
                if (safeFrame.origin.y > 0.0) {
                    safeFrame.origin = CGPointMake(safeFrame.origin.y, safeFrame.origin.x);
                }
                if (safeFrame.size.width < safeFrame.size.height) {
                    safeFrame.size = CGSizeMake(safeFrame.size.height, safeFrame.size.width);
                }
                mainRect.origin.x = safeFrame.origin.x;
                mainRect.size.width = safeFrame.size.width;
            }
        } else {
            mainRect.origin.y = 20.0;
            if (@available(iOS 11.0, *)) {
                CGRect safeFrame = weakSelf.view.superview.safeAreaLayoutGuide.layoutFrame;
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
        weakSelf.mainView.frame = mainRect;
        
        CGRect skinRect = mainRect;
        if (weakSelf.skinView.fullscreen && (skinRect.origin.x == 44.0 || weakSelf.iPad)) {
            skinRect.size.height -= 20.0;
        }
        weakSelf.skinView.frame = skinRect;
        weakSelf.moreView.frame = skinRect;
        [weakSelf.skinView layout];
        
        [weakSelf refreshDanmuModuleState];
        [weakSelf deviceOrientationDidChangeSubAnimation];
    } completion:nil];
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController codeRateItems:(NSMutableArray *)codeRateItems codeRate:(NSString *)codeRate {
    self.moreView.codeRateItems = codeRateItems;
    self.moreView.curCodeRate = codeRate;
}

- (void)playerController:(PLVPlayerController *)playerController showMessage:(NSString *)message {
    if (self.skinView.type == PLVPlayerSkinViewTypeNormalLive || self.skinView.type == PLVPlayerSkinViewTypeNormalVod) {
        [self.skinView showMessage:message];
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
