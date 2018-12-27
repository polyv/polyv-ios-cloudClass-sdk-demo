//
//  PLVBaseMediaViewController+Live.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/22.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController+Live.h"
#import "PLVLiveMediaProtocol.h"
#import "MBProgressHUD+Rotate.h"

@interface PLVBaseMediaViewController () <PLVLiveMediaProtocol, PLVPlayerSkinViewDelegate>

@end

@implementation PLVBaseMediaViewController (Live)

#pragma mark - protected
- (void)reOpenPlayer:(NSString *)codeRate showHud:(BOOL)showHud {
    if (!self.reOpening && !((PLVLivePlayerController *)self.player).linkMic) {
        self.reOpening = YES;
        MBProgressHUD *hud = nil;
        if (showHud) {
            hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
            [hud addDeviceOrientationDidChangeNotification];
            [hud.label setText:@"加载JSON..."];
        }
        
        __weak typeof(self) weakSelf = self;
        [(PLVLivePlayerController *)self.player loadChannel:codeRate completion:^{
            weakSelf.reOpening = NO;
            if (hud != nil) {
                hud.label.text = @"JSON加载成功";
                [hud hideAnimated:YES];
            }
        } failure:^(NSString *message) {
            weakSelf.reOpening = NO;
            if (hud != nil) {
                hud.label.text = [NSString stringWithFormat:@"JSON加载失败:%@", message];
                [hud hideAnimated:YES];
            }
        }];
    }
}

#pragma mark - PLVLiveMediaProtocol
- (void)danmu:(NSMutableAttributedString *)message {
    [self addDanmuLayer];
    [self.danmuLayer insertScrollDML:message];
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

- (NSString *)currentChannelSessionId; {
    return [((PLVLivePlayerController *)self.player) currentChannelSessionId];
}

#pragma mark - PLVPlayerSkinViewDelegate
- (void)refresh:(PLVPlayerSkinView *)skinView {
    [self reOpenPlayer:nil showHud:YES];
}

- (void)linkMic:(PLVPlayerSkinView *)skinView {
    [self.linkMicVC linkMic];
}

- (void)switchCamera:(PLVPlayerSkinView *)skinView {
    PLVLinkMicView *linkMicView = [self.linkMicVC.linkMicViewArray objectAtIndex:0];
    if (linkMicView.switchCameraBtn) {
        [self.linkMicVC switchCamera:nil];
    }
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView switchDanmu:(BOOL)switchDanmu {
    [self addDanmuLayer];
    self.danmuLayer.hidden = !switchDanmu;
}

- (void)playerSkinView:(PLVPlayerSkinView *)skinView codeRate:(NSString *)codeRate {
    [self reOpenPlayer:codeRate showHud:NO];
}

@end
