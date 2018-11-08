//
//  PLVLiveViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PolyvCloudClassSDK/PLVLiveChannel.h>

@interface PLVLiveViewController : UIViewController

@property (nonatomic, strong) PLVLiveChannel *channel;

/// 聊天室用户昵称
@property (nonatomic, strong) NSString *nickName;
/// 聊天室用户头像地址，HTTPS 协议地址
@property (nonatomic, strong) NSString *avatarUrl;

@end
