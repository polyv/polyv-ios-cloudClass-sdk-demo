//
//  PLVVodMediaProtocol.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

//回放播放器基类协议
@protocol PLVVodMediaProtocol <NSObject>

@property (nonatomic, strong) NSString *vodId;//必须，不能为空

@end
