//
//  PLVChatCellModel.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/30.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVBaseCell.h"

/// 抽象基类，使用子类初始化
@interface PLVCellModel : NSObject

@property (nonatomic, weak) PLVBaseCell *cell;

@property (nonatomic, assign) CGFloat cellHeight;

@property (nonatomic, assign) BOOL localMessage;

/// 使用CELL模型数据生成一个CELL
- (PLVBaseCell *)makeCellWithTableView:(UITableView *)tableView;

@end
