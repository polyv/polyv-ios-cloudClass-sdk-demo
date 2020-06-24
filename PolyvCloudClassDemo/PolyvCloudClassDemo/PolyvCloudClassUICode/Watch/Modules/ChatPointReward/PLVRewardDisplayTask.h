//
//  PLVRewardDisplayTask.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/8.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PLVRewardGoodsModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 即将展示回调
typedef NSInteger (^PLVRewardDisplayViewWillShowBlock)(PLVRewardGoodsModel * model);

/// 即将销毁回调
typedef void (^PLVRewardDisplayViewWillDeallocBlock)(NSInteger index);

/// 打赏展示任务
@interface PLVRewardDisplayTask : NSOperation

@property (nonatomic, weak) UIView * superView;

@property (nonatomic, strong) PLVRewardGoodsModel * model;
@property (nonatomic, assign) NSInteger goodsNum;
@property (nonatomic, strong) NSString * personName;

/// 即将销毁回调
@property (nonatomic, strong) PLVRewardDisplayViewWillDeallocBlock willDeallocBlock;

/// 询问分配下标的回调
@property (nonatomic, strong) PLVRewardDisplayViewWillShowBlock willShowBlock;

@end

NS_ASSUME_NONNULL_END
