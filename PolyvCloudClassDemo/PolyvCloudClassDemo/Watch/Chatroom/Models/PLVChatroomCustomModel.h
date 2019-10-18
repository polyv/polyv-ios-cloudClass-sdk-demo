//
//  PLVChatroomCustomModel.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/1/18.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatroomModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 自定义 CELL 模型
 */
@interface PLVChatroomCustomModel : PLVChatroomModel

@property (nonatomic, strong, readonly) NSString *event;

@property (nonatomic, strong, readonly) NSDictionary *message;

@property (nonatomic, assign, readonly) BOOL defined;

@property (nonatomic, strong, readonly) NSString *tip;

+ (instancetype)modelWithCustomMessage:(NSDictionary *)message;

@end

NS_ASSUME_NONNULL_END
