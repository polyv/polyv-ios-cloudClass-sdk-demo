//
//  PLVRewardDisplayManager.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "PLVRewardGoodsModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 打赏展示管理器
@interface PLVRewardDisplayManager : NSObject

/// 需要承载‘打赏展示’的父视图（weak）
@property (nonatomic, weak) UIView * superView;

/// 添加一次打赏展示
/// @param model 所展示的礼物模型
/// @param goodsNum 礼物数量
/// @param personName 打赏人的名称
- (void)addGoodsShowWithModel:(PLVRewardGoodsModel *)model
                     goodsNum:(NSInteger)goodsNum
                   personName:(NSString *)personName;

@end

NS_ASSUME_NONNULL_END
