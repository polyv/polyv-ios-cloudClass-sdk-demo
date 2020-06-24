//
//  PLVBaseMediaViewController+Vod.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/22.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController.h"
#import <PolyvCloudClassSDK/PLVVodPlayerController.h>

/// 回放播放器类别 - PLVBaseMediaViewController 的 Vod 类别（功能：1.seek；2.倍速）
@interface PLVBaseMediaViewController (Vod) <PLVVodPlayerControllerDelegate>

@end
