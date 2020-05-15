//
//  AppDelegate.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/1.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "AppDelegate.h"
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import <PolyvCloudClassSDK/PLVWVodVideoConfig.h>

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
    
    // 配置点播统计后台参数
    //[PLVWVodVideoConfig setViewLogViewerId:@"" viewerName:@""];
    //[PLVWVodVideoConfig setViewLogParam:nil param3:nil param4:nil param5:nil];
    
    /* 接收远程事件  ----- 关于后台音频被中断，之后暂停未自动恢复直播说明
        一般的，后台音频（不支持混音）被其他App音频中断，结束后不会自动恢复；
        添加该配置或remoteControl配置可以使后台直播在一些场景下中断后恢复直播，如打开一个临时视频观看；
        一些情况无法恢复，如进入音乐类App（qq音乐），另外App中的音频配置和其他依赖库的音频配置也可能对中断产生影响；
        处理：
        无法中断后自动恢复音频的直播可以在进入App时重新加载直播，这种情况可以由程序处理，当然也可以交给用户处理（手动刷新下）
     */
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
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
