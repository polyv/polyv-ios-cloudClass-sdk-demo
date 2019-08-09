//
//  PLVChatroomCustomKouModel.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/1/18.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatroomCustomKouModel.h"
#import "PLVChatroomCustomKouCell.h"

@implementation PLVChatroomCustomKouModel
@synthesize cellHeight = _cellHeight;

- (PLVChatroomCell *)cellFromModelWithTableView:(UITableView *)tableView {
    NSString *indentifier = PLVChatroomCustomKouCell.cellIndetifier;
    PLVChatroomCustomKouCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
    if (!cell) {
        cell = [[PLVChatroomCustomKouCell alloc] initWithReuseIdentifier:indentifier];
    }
    [cell setMine:self.localMessageModel];
    [cell setModelDict:self.message];
    _cellHeight = cell.height;
    
    return cell;
}

- (CGFloat)cellHeight {
    if (!_cellHeight) {
        _cellHeight = [PLVChatroomCustomKouCell calculateCellHeightWithModelDict:self.message mine:self.localMessageModel];
    }
    return _cellHeight;
}

@end
