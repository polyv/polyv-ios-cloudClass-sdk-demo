//
//  PLVNormalLiveMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController.h"
#import "PLVLiveMediaProtocol.h"

/// 普通直播类 - 继承于 PLVBaseMediaViewController，实现了 PLVLiveMediaProtocol 协议（功能：1.刷新；2.码率切换；3.重连）
@interface PLVNormalLiveMediaViewController : PLVBaseMediaViewController <PLVLiveMediaProtocol>

@end
