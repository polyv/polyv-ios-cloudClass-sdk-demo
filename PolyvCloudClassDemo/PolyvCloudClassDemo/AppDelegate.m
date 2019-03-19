//
//  AppDelegate.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "AppDelegate.h"
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import <PolyvBusinessSDK/PLVVodConfig.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /// 以下的直播字符串参数在官网（https://live.polyv.net/#/develop/appId）上已配置好
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    liveConfig.channelId = @"";
    liveConfig.appId = @"";
    liveConfig.userId = @"";
    liveConfig.appSecret = @"";
    
    /// 直播后，在（https://live.polyv.net/#/channel/你的频道号/playback）中可把某段视频转存到回放列表，然后在官网（https://my.polyv.net/secure/video/）上找到回放的 vodId 字符串值
    PLVVodConfig *vodConfig = [PLVVodConfig sharedInstance];
    vodConfig.vodId = @"";
    /// 以下字符串 configString，key，iv 的值在官网（https://my.polyv.net/secure/setting/api）上已配置好
    NSError *error = nil;
    NSString *configString = @"TD1YSmNwb9igqvbRFuaBtZbrGfnKDTXOXi3quGttQ1yQDj2jeqri2K7QdS5QOAIqXdMhYmsVl/iV0J7rH6UcQu2v4s95/sH2DGR79ksc7gP8MbibWxMWUEB7DjYthJVVBw00jFgEkIAWxCr45Kjcxw==";/// SDK加密串
    NSString *key = @"VXtlHmwfS2oYm0CZ";/// 加密密钥
    NSString *iv = @"2u9gDPKdX6GyQJKU";/// 加密向量
    [PLVVodConfig settingsWithConfigString:configString key:key iv:iv error:&error];
    
    return YES;
}

@end
