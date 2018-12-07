//
//  PLVPPTVodMediaViewController.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVPPTVodMediaViewController.h"
#import <PolyvCloudClassSDK/PLVVodPlayerController.h>
#import "PLVBaseMediaViewController+Vod.h"
#import "PLVBaseMediaViewController+PPT.h"

@interface PLVPPTVodMediaViewController () <PLVPlayerSkinViewDelegate, PLVPPTViewControllerDelegate>

@property (nonatomic, strong) PLVPlayerController<PLVPlayerControllerProtocol> *player;//视频播放器

@end

@implementation PLVPPTVodMediaViewController

@synthesize player;
@synthesize vodId;
@synthesize pptVC;
@synthesize secondaryView;
@synthesize originSecondaryFrame;
@synthesize pptOnSecondaryView;
@synthesize pptFlag;

#pragma mark - life cycle

- (void)dealloc {
    NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadSkinView:PLVPlayerSkinViewTypeCloudClassVod];
    self.skinView.controllView.hidden = YES;
}

#pragma mark - PLVBaseMediaViewController
- (void)deviceOrientationDidChangeSubAnimation:(CGAffineTransform)rotationTransform {
    [self dealDeviceOrientationDidChangeSubAnimation:rotationTransform];
}

- (void)loadPlayer {
    self.player = [[PLVVodPlayerController alloc] initWithVodId:self.vodId displayView:self.secondaryView delegate:self];
    [self.pptVC videoStart:self.vodId];
}

- (void)switchAction:(BOOL)manualControl {
    [self dealSwitchAction:manualControl];
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)play:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player play];
    [self.pptVC pptPlay:[self.skinView getCurrentTime] * 1000.0];
}

- (void)pause:(PLVPlayerSkinView *)skinView {
    [(PLVVodPlayerController *)self.player pause];
    [self.pptVC pptPause:[self.skinView getCurrentTime] * 1000.0];
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate {
    [(PLVVodPlayerController *)self.player switchCodeRate:codeRate];
}

#pragma mark - PLVPPTViewControllerDelegate
- (void)pptPrepare:(PLVPPTViewController *)pptVC {
    
}

- (NSTimeInterval)getCurrentTime:(PLVPPTViewController *)pptVC {
    return [self.skinView getCurrentTime] * 1000.0;
}

@end
