//
//  AppDelegate.m
//  PolyvCloudSchoolDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "AppDelegate.h"
#import <PolyvCloudClassSDK/PLVLiveConfig.h>
#import <PolyvBusinessSDK/PLVVodConfig.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    PLVLiveConfig *liveConfig = [PLVLiveConfig sharedInstance];
    liveConfig.appId =
    liveConfig.userId =
    liveConfig.appSecret =
    liveConfig.vodId =
    
    NSError *error = nil;
    NSString *vodKey = @"yQRmgnzPyCUYDx6weXRATIN8gkp7BYGAl3ATjE/jHZunrULx8CoKa1WGMjfHftVChhIQlCA9bFeDDX+ThiuBHLjsNRjotqxhiz97ZjYaCQH/MhUrbEURv58317PwPuGEf3rbLVPOa4c9jliBcO+22A==";
    [PLVVodConfig settingsWithConfigString:vodKey error:&error];
    
    return YES;
}

@end
