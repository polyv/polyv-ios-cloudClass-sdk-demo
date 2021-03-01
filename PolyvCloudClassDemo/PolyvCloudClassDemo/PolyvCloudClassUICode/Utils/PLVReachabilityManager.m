//
//  PLVReachabilityManager.m
//  PolyvCloudClassDemo
//
//  Created by jiaweihuang on 2021/2/20.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVReachabilityManager.h"

@implementation PLVReachabilityManager


+ (void)listenNetWorkingStatusWithTarget:(id)target selector:(SEL)selector {
    PLVReachability *reachability = [PLVReachability reachabilityForInternetConnection];
    [reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:target selector:selector name:kPLVReachabilityChangedNotification object:reachability];
}

+ (void)destoryWithTarget:(id)target {
    [[NSNotificationCenter defaultCenter] removeObserver:target name:kPLVReachabilityChangedNotification object:nil];
    PLVReachability *reachability = [PLVReachability reachabilityForInternetConnection];
    [reachability stopNotifier];
}

+ (PLVNetworkStatus)currentReachabilityStatus {
    return [[PLVReachability reachabilityForInternetConnection] currentReachabilityStatus];
}

@end
