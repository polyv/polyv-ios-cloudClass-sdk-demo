//
//  PLVPPTLiveMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController.h"
#import "PLVPPTMediaProtocol.h"
#import "PLVLiveMediaProtocol.h"

/// 云课堂直播类 - 继承于 PLVBaseMediaViewController，实现了 PLVLiveMediaProtocol，PLVPPTMediaProtocol 协议（功能：1.刷新；2.码率切换；3.重连；4.刷新 PPT 内容）
@interface PLVPPTLiveMediaViewController : PLVBaseMediaViewController <PLVLiveMediaProtocol, PLVPPTMediaProtocol>

/// 是否特邀观众/参与者，默认 NO
@property (nonatomic, assign) BOOL viewer;

#pragma mark - public
/// 刷新 PPT 内容，该 json 由外层的 Socket 接收传递进来
- (void)refreshPPT:(NSString *)json;

/// 讲师主动切换PPT和视频窗口（status为YES代表视频在主窗口，为NO代表PPT在主窗口）
- (void)changeVideoAndPPTPosition:(BOOL)status;

@end
