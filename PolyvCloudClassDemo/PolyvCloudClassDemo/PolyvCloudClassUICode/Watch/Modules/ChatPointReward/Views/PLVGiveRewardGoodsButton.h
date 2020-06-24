//
//  PLVGiveRewardGoodsButton.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVRewardGoodsModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVRewardGoodsModel;

/// 礼物选项按钮（展示礼物图、礼物名、积分）
@interface PLVGiveRewardGoodsButton : UIControl

/// 所对应的礼物模型（设置该属性，以设置按钮上的信息）
@property (nonatomic, strong) PLVRewardGoodsModel * model;

@end

NS_ASSUME_NONNULL_END
