//
//  PLVBaseMediaViewController+Live.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/22.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVBaseMediaViewController.h"

//直播播放器类别 - PLVBaseMediaViewController 的 Live 类别（功能：切换码率，重连或刷新时重新打开播放器）
@interface PLVBaseMediaViewController (Live)

#pragma mark - protected
//重新打开播放器（切换码率，重连或刷新时调用）
- (void)reOpenPlayer:(NSString *)codeRate showHud:(BOOL)showHud;

@end
