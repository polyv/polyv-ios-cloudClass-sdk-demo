//
//  PLVVodViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PLVVodViewControllerType) {
    PLVVodViewControllerTypeLive       = 1,//普通直播
    PLVVodViewControllerTypeCloudClass = 2 //云课堂
};

@interface PLVVodViewController : UIViewController

@property (nonatomic, assign) PLVVodViewControllerType vodType;//回放类型（1：普通直播；2：云课堂）

@end
