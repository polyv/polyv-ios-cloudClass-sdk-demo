//
//  PLVNormalVodMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/12/5.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController.h"
#import "PLVVodMediaProtocol.h"

//普通回放点播类 - 继承于 PLVBaseMediaViewController，实现了 PLVVodMediaProtocol 协议（功能：1.播放；2.暂停；3.码率切换）
@interface PLVNormalVodMediaViewController : PLVBaseMediaViewController <PLVVodMediaProtocol>

@end
