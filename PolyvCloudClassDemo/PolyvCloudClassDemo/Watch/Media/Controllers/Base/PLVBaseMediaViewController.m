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

@interface PLVBaseMediaViewController () <PLVPlayerSkinViewDelegate, PLVPlayerControllerDelegate>

@property (nonatomic, strong) PLVPlayerSkinView *skinView;//播放器的皮肤
@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器
@property (nonatomic, strong) UIView *mainView;//主屏
@property (nonatomic, assign) CGRect originFrame;//页面初始化，记住竖屏时view的Frame，横竖屏切换的动画需要使用
@property (nonatomic, assign) UIDeviceOrientation curOrientation;//设备的当前方向，横竖屏切换动画需要使用
@property (nonatomic, assign) BOOL skinShowed;//播放器皮肤是否已显示
@property (nonatomic, assign) BOOL skinAnimationing;//播放器皮肤显示隐藏动画的开关
@property (nonatomic, assign) BOOL zoomAnimationing;//横竖屏切换动画的开关

@property (nonatomic, strong) PLVVideoMarquee *videoMarquee; // 视频跑马灯

@end

@implementation PLVBaseMediaViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.skinShowed = YES;
    self.originFrame = CGRectZero;
    self.curOrientation = UIDeviceOrientationPortrait;
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    self.mainView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.mainView.backgroundColor = BlueBackgroundColor;
    self.mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mainView];
    
    //单击显示或隐藏皮肤
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(skinTapAction)];
    [self.view addGestureRecognizer:tap];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - public clear
- (void)clearResource {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [self.player clearPlayersAndTimers];
}

#pragma mark - protected
- (void)loadSkinView:(PLVPlayerSkinViewType)skinType {
    self.skinView = [[PLVPlayerSkinView alloc]  initWithFrame:self.view.bounds];
    self.skinView.delegate = self;
    self.skinView.type = skinType;
    self.skinView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.skinView];
    [self.skinView loadSubviews];
    self.skinView.controllView.hidden = YES;
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

#pragma mark - protected - abstract
- (void)deviceOrientationDidChangeSubAnimation:(CGAffineTransform)rotationTransform {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 、 PLVNormalLiveMediaViewController 重写
}

- (void)loadPlayer {
//    在子类 PLVPPTLiveMediaViewController 、 PLVPPTVodMediaViewController 重写
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

//横竖屏旋转动画
- (void)deviceOrientationDidChange {
    if ([PLVLiveVideoConfig sharedInstance].unableRotate) {
        return;
    }
    if (CGRectEqualToRect(self.originFrame, CGRectZero)) {
        self.originFrame = self.view.frame;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (!self.zoomAnimationing && self.curOrientation != orientation) {
        CGRect rect = self.originFrame;
        CGFloat angle = 0.0;
        BOOL fullscreen = NO;
        BOOL flip = NO;
        if (UIDeviceOrientationIsLandscape(orientation)) {
            rect = [UIScreen mainScreen].bounds;
            angle = (orientation == UIDeviceOrientationLandscapeRight ? -M_PI_2 : M_PI_2);
            fullscreen = YES;
            if (UIDeviceOrientationIsLandscape(self.curOrientation)) {//水平翻转时，只改变view.transform，不改变view.frame
                flip = YES;
            }
        }
        self.curOrientation = orientation;
        self.zoomAnimationing = YES;
        
        __weak typeof(self) weakSelf = self;
        [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation)(orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ? UIDeviceOrientationPortrait : orientation) animated:YES];
        [UIView animateWithDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration] delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.skinView.fullscreen = fullscreen;
            CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(angle);
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(statusBarAppearanceNeedsUpdate:rotationTransform:)]) {
                //delegate回调隐藏或显示statusBar，一定要放在最前前执行，因为layout时需要用到安全区域，而statusBar的隐藏或显示会影响安全区域的y坐标
                [weakSelf.delegate statusBarAppearanceNeedsUpdate:weakSelf rotationTransform:rotationTransform];
            }
            weakSelf.view.transform = rotationTransform;
            if (!flip) {
                weakSelf.view.frame = rect;
            }
            CGRect mainRect = weakSelf.view.bounds;
            if (fullscreen) {
                if (@available(iOS 11.0, *)) {
                    CGRect safeFrame = weakSelf.view.safeAreaLayoutGuide.layoutFrame;
                    mainRect.origin.x = safeFrame.origin.x;
                    mainRect.size.width = safeFrame.size.width;
                }
            }
            weakSelf.mainView.frame = mainRect;
            [weakSelf.skinView layout];
            
            [weakSelf deviceOrientationDidChangeSubAnimation:rotationTransform];
            [weakSelf.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            weakSelf.zoomAnimationing = NO;
        }];
    }
}

#pragma mark - PLVPlayerControllerDelegate
- (void)playerController:(PLVPlayerController *)playerController codeRateItems:(NSMutableArray *)codeRateItems codeRate:(NSString *)codeRate {
    self.skinView.codeRateItems = codeRateItems;
    [self.skinView layout];
    [self.skinView switchCodeRate:codeRate];
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
