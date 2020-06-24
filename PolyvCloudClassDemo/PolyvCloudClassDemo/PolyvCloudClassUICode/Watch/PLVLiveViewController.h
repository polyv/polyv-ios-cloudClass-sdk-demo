//
//  PLVLiveViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>

/// 直播类型
typedef NS_ENUM(NSInteger, PLVLiveViewControllerType) {
    /// 普通直播
    PLVLiveViewControllerTypeLive = 1,
    /// 云课堂
    PLVLiveViewControllerTypeCloudClass = 2
};

/// 直播控制器
@interface PLVLiveViewController : UIViewController

/// 直播类型（1：普通直播；2：云课堂）
@property (nonatomic, assign) PLVLiveViewControllerType liveType;
/// 在登录时，根据网络请求返回当前频道是否正在直播（直播中：云课堂主屏为PPT，副屏为视频流；未直播，主屏优先播放暖场广告）
@property (nonatomic, assign) PLVLiveStreamState liveState;

/// 聊天室相关的Tab信息
@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *channelMenuInfo;

/// 是否参与者
@property (nonatomic, assign) BOOL viewer;

/// 聊天室自定义用户昵称，不设置时默认生成
@property (nonatomic, strong) NSString *nickName;
/// 聊天室自定义用户头像地址，不设置时使用默认地址（建议使用 HTTPS 协议地址）
@property (nonatomic, strong) NSString *avatarUrl;

// 追帧设置
@property (nonatomic, assign) BOOL chaseFrame;

@end
