//
//  PLVLiveViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PLVLiveViewControllerType) {
    PLVLiveViewControllerTypeLive       = 1,//普通直播
    PLVLiveViewControllerTypeCloudClass = 2 //云课堂
};

@interface PLVLiveViewController : UIViewController

@property (nonatomic, assign) PLVLiveViewControllerType liveType;//直播类型（1：普通直播；2：云课堂）
@property (nonatomic, assign) BOOL playAD;//在登录时，根据网络请求返回当前频道是否正在直播（直播中：云课堂主屏为PPT，副屏为视频流；未直播，主屏优先播放暖场广告）

@end
