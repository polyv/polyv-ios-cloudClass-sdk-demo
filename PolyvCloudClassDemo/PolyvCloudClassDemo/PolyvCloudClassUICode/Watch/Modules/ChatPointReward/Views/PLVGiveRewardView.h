//
//  PLVGiveRewardView.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVRewardGoodsModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVGiveRewardView;

@protocol PLVGiveRewardViewDelegate <NSObject>

/// 点击‘发送’
- (void)plvGiveRewardView:(PLVGiveRewardView *)giveRewardView goodsModel:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num;

@end

/// 打赏视图
@interface PLVGiveRewardView : UIView

/// Delegate
@property (nonatomic, weak) id <PLVGiveRewardViewDelegate> delegate;
/// 用户积分单位
@property (nonatomic, copy) NSString * pointUnit;

/// 当前礼物数据数组（通过 -(void)refreshGoods: 方法进行更新）
@property (nonatomic, strong, readonly) NSArray <PLVRewardGoodsModel *> * modelArray;

/// 更新礼物列表
- (void)refreshGoods:(NSArray <PLVRewardGoodsModel *> *)goodsModelArray;

/// 更新用户积分
- (void)refreshUserPoint:(NSString *)userPoint;

/// 展示打赏视图
- (void)showOnView:(UIView *)superView;

@end

NS_ASSUME_NONNULL_END
