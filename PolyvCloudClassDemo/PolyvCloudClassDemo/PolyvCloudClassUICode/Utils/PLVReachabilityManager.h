//
//  PLVReachabilityManager.h
//  PolyvCloudClassDemo
//
//  Created by jiaweihuang on 2021/2/20.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PolyvFoundationSDK/PLVReachability.h>


@interface PLVReachabilityManager : NSObject

/// 初始化监听
+ (void)listenNetWorkingStatusWithTarget:(id)target selector:(SEL)selector;

/// 销毁监听
+ (void)destoryWithTarget:(id)target;

/// 当前网络状态
+ (PLVNetworkStatus)currentReachabilityStatus;


@end

