//
//  ZJZDanMu.m
//  DanMu
//
//  Created by 郑家柱 on 16/6/17.
//  Copyright © 2016年 Jiangsu Houxue Network Information Technology Limited By Share Ltd. All rights reserved.
//

#import "ZJZDanMu.h"
#import "ZJZDanMuLabel.h"
#import "ZJZDanMuDefine.h"

@interface ZJZDanMu () <ZJZDanMuLabelDelegate>

@property (nonatomic, assign) NSUInteger            rollChannel;
@property (nonatomic, strong) NSMutableDictionary   *rollChannelDict;
@property (nonatomic, strong) NSMutableDictionary   *fadeChannelDict;
@property (nonatomic, assign) CGRect                currentFrame;
@property (nonatomic, strong) NSMutableArray *dmLabelArray;

@end

@implementation ZJZDanMu

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.currentFrame = frame;
        self.dmLabelArray = [[NSMutableArray alloc] initWithCapacity:100];
        
        [self dmInitChannel];
        
    }
    return self;
}

/* 初始化航道信息 */
- (void)dmInitChannel
{
    // 计算航道
    self.rollChannel = floorf((self.currentFrame.size.height - 10)/KZJZDMHEIGHT);
    
    // 初始化航道队列
    self.rollChannelDict = [NSMutableDictionary dictionaryWithCapacity:self.rollChannel];
    self.fadeChannelDict = [NSMutableDictionary dictionaryWithCapacity:self.rollChannel];
    
    for (int i = 0; i < self.rollChannel; i ++) {
        NSArray *array = [NSArray array];
        [self.rollChannelDict setObject:array forKey:@(i)];
        [self.fadeChannelDict setObject:array forKey:@(i)];
    }
}

- (void)insertScrollDML:(NSMutableAttributedString *)content {
    NSUInteger bestChannel = [self dmBestRollChannel];
    ZJZDanMuLabel *zjzDML = nil;
    @synchronized (self) {
        if (self.dmLabelArray.count > 0) {
            zjzDML = self.dmLabelArray[self.dmLabelArray.count - 1];
            [self.dmLabelArray removeLastObject];
        }
    }
    
    if (zjzDML != nil) {
        [zjzDML makeup:content dmlOriginY:bestChannel * KZJZDMHEIGHT + 5 superFrame:self.currentFrame style:ZJZDMLRoll];
    } else {
        zjzDML = [ZJZDanMuLabel dmInitDML:content dmlOriginY:bestChannel * KZJZDMHEIGHT + 5 superFrame:self.currentFrame style:ZJZDMLRoll];
        zjzDML.delegate = self;
    }
    
    [self addSubview:zjzDML];
    [zjzDML dmBeginAnimation];
    [self insertDMQueue:zjzDML channel:bestChannel];
}

/* 插入弹幕 */
- (void)insertDML:(NSMutableAttributedString *)content
{
    ZJZDMLStyle dmlStyle = ZJZDMLFade;
    
    // 计算最佳航道
    NSUInteger bestChannel;
    if (arc4random_uniform(10)) {
        dmlStyle = ZJZDMLRoll;
        bestChannel = [self dmBestRollChannel];
    } else {
        bestChannel = [self dmBestFadeChannel];
    }
    
    // 初始化弹幕
    ZJZDanMuLabel *zjzDML = [ZJZDanMuLabel dmInitDML:content dmlOriginY:bestChannel * KZJZDMHEIGHT + 5 superFrame:self.currentFrame style:dmlStyle];
    [self addSubview:zjzDML];
    
    [zjzDML dmBeginAnimation];
    
    // 插入弹幕队列
    [self insertDMQueue:zjzDML channel:bestChannel];
}

/* 加入弹幕队列 */
- (void)insertDMQueue:(ZJZDanMuLabel *)dml channel:(NSUInteger)channel
{
    if (dml.zjzDMLStyle == ZJZDMLRoll) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.rollChannelDict objectForKey:@(channel)]];
        
        // 清除当前弹幕航道的所有信息后再加入最新的弹幕
        [array removeAllObjects];
        [array addObject:dml];
        [self.rollChannelDict setObject:array forKey:@(channel)];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.fadeChannelDict objectForKey:@(channel)]];
        
        // 清除当前弹幕航道的所有信息后再加入最新的弹幕
        [array removeAllObjects];
        [array addObject:dml];
        [self.fadeChannelDict setObject:array forKey:@(channel)];
    }
    
}

/* 计算滚动最佳航道 */
- (NSUInteger)dmBestRollChannel
{
    for (NSUInteger i = 0; i < self.rollChannel; i ++) {
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.rollChannelDict objectForKey:@(i)]];
        ZJZDanMuLabel *dml = [array lastObject];
        
        if (dml) {
            
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:dml.startTime];
            
            if (duration * dml.dmlSpeed >= dml.frame.size.width + 5 + arc4random_uniform(40)) {
                
                return i;
            }
            
        } else {
            
            return i;
            
        }
        
    }
    
    // 如果航道铺满整屏，则随机选择航道直接显示
    return arc4random_uniform((u_int32_t)self.rollChannel);
}

/* 计算浮动最佳航道 */
- (NSUInteger)dmBestFadeChannel
{
    for (NSUInteger i = 0; i < self.rollChannel; i ++) {
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.fadeChannelDict objectForKey:@(i)]];
        ZJZDanMuLabel *dml = [array lastObject];
        
        if (dml) {
            
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:dml.startTime];
            
            if (duration >= dml.dmlFadeTime + 0.2f) {
                
                return i;
            }
            
        } else {
            
            return i;
            
        }
        
    }
    
    // 如果航道铺满整屏，则随机选择航道直接显示
    return arc4random_uniform((u_int32_t)self.rollChannel);
}

/* 重置Frame */
- (void)resetFrame:(CGRect)frame
{
    self.currentFrame = frame;
    
    [self dmInitChannel];
}

#pragma mark - ZJZDanMuLabelDelegate
- (void)endScrollAnimation:(ZJZDanMuLabel *)dmLabel {
    @synchronized (self) {
        [self.dmLabelArray addObject:dmLabel];
    }
}

@end
