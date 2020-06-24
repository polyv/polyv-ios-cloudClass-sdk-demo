//
//  PLVLiveInfoViewController.h
//  PolyvLiveSDKDemo
//
//  Created by zykhbl(zhangyukun@polyv.net) on 2018/7/18.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PolyvCloudClassSDK/PLVLiveVideoChannel.h>
#import <PolyvCloudClassSDK/PLVLiveVideoChannelMenuInfo.h>

@interface PLVLiveInfoViewController : UIViewController

@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *channelMenuInfo;
@property (nonatomic, strong) PLVLiveVideoChannelMenu *menu;
@property (nonatomic, assign) BOOL vod;

- (void)refreshLiveInfo;

/// 历史观看人数 label +1
- (void)increaseWatchNumber;

/// 更新历史观看人数 label
- (void)updateWatchNumber:(NSInteger)watchNumber;

@end
