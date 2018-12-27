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

#pragma mark - public
/// 刷新 PPT 内容，该 json 由外层的 Socket 接收传递进来
- (void)refreshPPT:(NSString *)json;

/// 副窗口跟随聊天室的键盘移动，防止挡住聊天室内容
- (void)secondaryViewFollowKeyboardAnimation:(BOOL)flag;

/// 切换连麦窗口时，如有需要，要跟着切换 PPT 窗口
- (void)linkMicSwitchViewAction;

@end
