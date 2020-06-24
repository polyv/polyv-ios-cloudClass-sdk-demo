//
//  PLVRewardDisplayTask.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/8.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVRewardDisplayTask.h"

#import "PLVRewardDisplayView.h"

@interface PLVRewardDisplayTask ()

/// 所分配的下标(默认-1，表示未分配)
@property (nonatomic, assign) NSInteger index;

@end

@implementation PLVRewardDisplayTask

@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)dealloc{
    if (self.willDeallocBlock) {self.willDeallocBlock(self.index);}
}

- (instancetype)init{
    if (self = [super init]) {
        self.index = -1;
    }
    return self;
}

- (void)start{
    if (!self.isExecuting) self.executing = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf showDisplayView];
    });
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)showDisplayView{
    if (self.willShowBlock) {
        NSInteger index = self.willShowBlock(self.model);
        if (index < 0) { return; }
        self.index = index;
    }else{
        return;
    }
    
    float x = - PLVDisplayViewWidth;
    float y = 37 + (PLVDisplayViewHeight + 15) * self.index;
    CGRect originRect = CGRectMake(x, y, PLVDisplayViewWidth, PLVDisplayViewHeight);
    CGRect finalRect = CGRectMake(0, y, PLVDisplayViewWidth, PLVDisplayViewHeight);
    
    __weak typeof(self) weakSelf = self;

    PLVRewardDisplayView * view = [PLVRewardDisplayView displayViewWithModel:self.model goodsNum:self.goodsNum personName:self.personName];
    view.willRemoveBlock = ^{
        if (weakSelf.isExecuting) weakSelf.executing = NO;
        if (!weakSelf.isFinished) weakSelf.finished = YES;
    };
    view.frame = originRect;
    [self.superView addSubview:view];
    [view layoutIfNeeded];

    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.frame = finalRect;
    } completion:^(BOOL finished) {
        [view showNumAnimation];
    }];
}

@end
