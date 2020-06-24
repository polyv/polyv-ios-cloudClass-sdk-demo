//
//  PLVTableViewController.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/31.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVTableViewController : UIViewController <PLVBaseCellProtocol>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<PLVCellModel *> *dataArray;

@property (nonatomic, assign) BOOL scrollsToBottom;

- (void)addLatestMessageButton;
- (void)showLatestMessageButton;

- (void)refreshTableView;

- (void)scrollsToBottom:(BOOL)animated;

- (void)scrollToRowAtIndex:(NSUInteger)index atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
