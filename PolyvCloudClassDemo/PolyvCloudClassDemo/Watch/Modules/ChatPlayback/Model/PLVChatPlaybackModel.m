//
//  PLVChatPlaybackModel.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/8/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatPlaybackModel.h"
#import <PolyvFoundationSDK/PLVDateUtil.h>

@implementation PLVChatPlaybackModel

- (void)setTime:(NSString *)time {
    _time = time;
    _showTime = [PLVDateUtil secondsToTimeInterval:time];
}

- (void)setShowTime:(NSTimeInterval)showTime {
    _showTime = showTime;
    _time = [PLVDateUtil secondsToString2:showTime];
}

@end
