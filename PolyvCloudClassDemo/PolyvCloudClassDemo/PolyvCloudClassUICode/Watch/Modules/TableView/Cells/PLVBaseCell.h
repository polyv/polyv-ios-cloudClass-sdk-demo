//
//  PLVBaseCell.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/30.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVBaseCell;
@protocol PLVBaseCellProtocol <NSObject>

@optional
- (void)cellCallback:(PLVBaseCell *)cell;

@end

@class PLVCellModel;
/// 抽象基类，使用子类初始化
@interface PLVBaseCell : UITableViewCell

@property (nonatomic, strong) PLVCellModel *model;

@property (nonatomic, weak) id<PLVBaseCellProtocol> delegate;

@property (class, nonatomic, readonly) NSString *identifier;

#pragma mark 子类重写

- (void)layoutCell;

+ (CGFloat)cellHeightWithModel:(PLVCellModel *)model;

@end
