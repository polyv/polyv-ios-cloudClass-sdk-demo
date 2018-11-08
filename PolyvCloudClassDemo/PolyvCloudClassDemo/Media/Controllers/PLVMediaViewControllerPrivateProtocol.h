//
//  PLVMediaViewControllerPrivateProtocol.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/9/28.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVMediaSecondaryView.h"

@protocol PLVMediaViewControllerPrivateProtocol <NSObject>

//以下方法，由父类PLVMediaViewController实现，在子类PLVLiveMediaViewController或PLVVodMediaViewController根据业务逻辑需要调用
@optional

//关闭副屏
- (void)closeSecondaryView:(PLVMediaSecondaryView *)secondaryView;

//打开副屏
- (void)openSecondaryView;

//切换主副屏
- (void)switchScreen:(BOOL)manualControl;

//skin皮肤的透明度动画（显示或隐藏）
- (void)skinAlphaAnimaion:(CGFloat)alpha;

//skin皮肤的隐藏动画
- (void)skinHiddenAnimaion;

//播放器皮肤开启码率选择功能
- (void)loadSkinView:(PLVPlayerSkinViewType)skinType codeRateItems:(NSMutableArray *)codeRateItems codeRate:(NSString *)codeRate;

//横竖屏动画时，子类某些窗口需要做动画的逻辑在这里实现
- (void)deviceOrientationDidChangeSubAnimation:(CGAffineTransform)transform;

@end
