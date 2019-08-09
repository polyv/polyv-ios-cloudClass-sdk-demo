//
//  AppDelegate.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "AppDelegate.h"
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /// 以下的直播字符串参数在官网（https://live.polyv.net/#/develop/appId）上已配置好
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    liveConfig.channelId =
    liveConfig.appId =
    liveConfig.userId =
    liveConfig.appSecret =
    
    /// 直播后，在（https://live.polyv.net/#/channel/你的频道号/playback）中可把某段视频转存到回放列表，然后在官网（https://my.polyv.net/secure/video/）上找到回放的 vodId 字符串值
    liveConfig.vodId =
    
    // 配置统计后台参数：用户Id、用户昵称及自定义参数
    [PLVLiveVideoConfig setViewLogParam:nil param2:nil param4:nil param5:nil];
    
    return YES;
}

@end
