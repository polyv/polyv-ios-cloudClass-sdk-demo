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
    liveConfig.channelId = ;
    liveConfig.appId = ;
    liveConfig.userId = ;
    liveConfig.appSecret = ;
    
    /// 直播回放Id
    liveConfig.vodId = ;
    
    // 配置统计后台参数：用户Id、用户昵称及自定义参数
    [PLVLiveVideoConfig setViewLogParam:nil param2:nil param4:nil param5:nil];
    
    return YES;
}

// 禁用第三方键盘（H5界面偏移问题）\
使用第三方键盘时，如出现中奖和h5交互，用户输出文字时界面不会正常偏移\
如不禁用，可在输出信息时切换回系统键盘
- (BOOL)application:(UIApplication *)application shouldAllowExtensionPointIdentifier:(UIApplicationExtensionPointIdentifier)extensionPointIdentifier {
    if ([extensionPointIdentifier isEqualToString:UIApplicationKeyboardExtensionPointIdentifier]) {
        return NO;
    }
    return YES;
}

@end
