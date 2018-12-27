//
//  PLVPPTVodMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/30.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController.h"
#import "PLVVodMediaProtocol.h"
#import "PLVPPTMediaProtocol.h"

/// 云课堂回放点播类 - 继承于 PLVBaseMediaViewController，实现了 PLVVodMediaProtocol，PLVPPTMediaProtocol 协议（功能：1.播放；2.暂停；3.码率切换）
@interface PLVPPTVodMediaViewController : PLVBaseMediaViewController <PLVVodMediaProtocol, PLVPPTMediaProtocol>

@end
