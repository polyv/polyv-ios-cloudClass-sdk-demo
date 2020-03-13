//
//  PLVRewardGoodsModel.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/9.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <PolyvBusinessSDK/PolyvBusinessSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// 打赏礼物模型
@interface PLVRewardGoodsModel : NSObject

@property (nonatomic, assign) NSInteger goodId;

@property (nonatomic, copy) NSString * goodName;
@property (nonatomic, copy) NSString * goodImgURL;
@property (nonatomic, copy) NSString * goodImgFullURL;

@property (nonatomic, assign) float goodPrice;
@property (nonatomic, assign) BOOL goodEnabled;

/// 通过数据字典创建模型
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

/// 通过socket消息创建模型
+ (instancetype)modelWithSocketObject:(PLVSocketChatRoomObject *)object;

@end

NS_ASSUME_NONNULL_END
