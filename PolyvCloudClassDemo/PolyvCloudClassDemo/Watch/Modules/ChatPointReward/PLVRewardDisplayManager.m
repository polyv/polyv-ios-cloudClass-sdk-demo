//
//  PLVRewardDisplayManager.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVRewardDisplayManager.h"

#import "PLVRewardDisplayTask.h"

static const NSInteger PLVDisplayRailNum = 2;

@interface PLVRewardDisplayManager ()

@property (nonatomic, strong) NSOperationQueue * displayQueue;
@property (nonatomic, strong) NSMutableDictionary * displayRailDict;

@end

@implementation PLVRewardDisplayManager

#pragma mark - [ Private Methods ]
- (NSInteger)arrangeDisplayRailWithItem:(PLVRewardGoodsModel *)model{
    NSInteger index = -1;
    for (int i = 0; i < self.displayRailDict.allKeys.count; i++) {
        NSString * key = self.displayRailDict.allKeys[i];
        id obj = [self.displayRailDict objectForKey:key];
        if ([obj isKindOfClass:NSNull.class]) {
            index = i;
            [self.displayRailDict setValue:model forKey:key];
            break;
        }
    }
    return index;
}

- (void)removeDisplayItemWithRailIndex:(NSInteger)index{
    if (index < self.displayRailDict.allKeys.count) {
        [self.displayRailDict setValue:[NSNull null] forKey:[NSString stringWithFormat:@"%ld",index]];
    }
}

#pragma mark Getter
- (NSOperationQueue *)displayQueue{
    if (!_displayQueue) {
        _displayQueue = [[NSOperationQueue alloc]init];
        _displayQueue.maxConcurrentOperationCount = PLVDisplayRailNum;
        _displayQueue.name = @"com.polyv.PLVRewardDisplayManager";
    }
    return _displayQueue;
}

- (NSMutableDictionary *)displayRailDict{
    if (!_displayRailDict) {
        _displayRailDict = [[NSMutableDictionary alloc]init];
        NSInteger i = 0;
        while (i < PLVDisplayRailNum) {
            [_displayRailDict setValue:[NSNull null] forKey:[NSString stringWithFormat:@"%ld",i]];
            i ++;
        }
    }
    return _displayRailDict;
}


#pragma mark - [ Public Methods ]
- (void)addGoodsShowWithModel:(PLVRewardGoodsModel *)model goodsNum:(NSInteger)num personName:(NSString *)peopleName{
    if (!self.superView || ![self.superView isKindOfClass:UIView.class]) { return; }
    
    PLVRewardDisplayTask * task = [[PLVRewardDisplayTask alloc]init];
    task.model = model;
    task.goodsNum = num;
    task.personName = peopleName;
    task.superView = self.superView;
    
    __weak typeof(self) weakSelf = self;
    task.willShowBlock = ^NSInteger(PLVRewardGoodsModel * _Nonnull model) {
        return [weakSelf arrangeDisplayRailWithItem:model];
    };
    
    task.willDeallocBlock = ^(NSInteger index) {
        [weakSelf removeDisplayItemWithRailIndex:index];
    };
    
    [self.displayQueue addOperation:task];
}

@end
