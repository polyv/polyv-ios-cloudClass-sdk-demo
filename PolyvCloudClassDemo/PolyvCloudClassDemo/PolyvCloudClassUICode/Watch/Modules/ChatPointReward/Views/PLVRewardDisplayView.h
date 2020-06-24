//
//  PLVRewardDisplayView.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVGiveRewardGoodsButton.h"

/// 打赏展示视图 宽度
static const CGFloat PLVDisplayViewWidth = 290;
/// 打赏展示视图 高度
static const CGFloat PLVDisplayViewHeight = 51;

NS_ASSUME_NONNULL_BEGIN

/// 打赏展示视图 即将从父视图中移除的回调定义
typedef void (^PLVRewardDisplayViewWillRemovedBlock)(void);

/// 打赏展示视图
@interface PLVRewardDisplayView : UIView

/// 所展示的礼物模型
@property (nonatomic, strong, readonly) PLVRewardGoodsModel * model;

/// 打赏展示视图 即将从父视图中移除回调
@property (nonatomic, strong) PLVRewardDisplayViewWillRemovedBlock willRemoveBlock;

/// 创建打赏展示视图
+ (instancetype)displayViewWithModel:(PLVRewardGoodsModel *)model
                            goodsNum:(NSInteger)goodsNum
                          personName:(NSString *)personName;

/// 展示数量放大动画
- (void)showNumAnimation;

@end

/// 描边文本视图
@interface PLVStrokeBorderLabel : UILabel

@end

NS_ASSUME_NONNULL_END
