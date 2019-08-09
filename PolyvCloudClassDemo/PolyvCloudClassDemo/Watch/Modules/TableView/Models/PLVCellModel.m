//
//  PLVChatCustomModel.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/30.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVCellModel.h"
#import "PLVBaseCell.h"

@implementation PLVCellModel

- (CGFloat)cellHeight {
    if (_cellHeight == 0) {
        _cellHeight = [PLVBaseCell cellHeightWithModel:self];
    }
    return _cellHeight;
}

- (PLVBaseCell *)makeCellWithTableView:(UITableView *)tableView {
    PLVBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:PLVBaseCell.identifier];
    if (!cell) {
        cell = [[PLVBaseCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PLVBaseCell.identifier];
    }
    
    return cell;
}

@end
