//
//  PLVCircleProgressView.m
//  PolyvCloudClassSDK
//
//  Created by zykhbl on 2018/12/3.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVCircleProgressView.h"

@interface PLVCircleProgressView ()

@property (nonatomic, strong) CAShapeLayer *frontFillLayer;
@property (nonatomic, strong) UIBezierPath *frontFillBezierPath;

@end

@implementation PLVCircleProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor lightGrayColor];
        [self setUp];
    }
    return self;
}

- (void)setUp {
    self.frontFillLayer = [CAShapeLayer layer];
    self.frontFillLayer.frame = self.bounds;
    self.frontFillLayer.lineWidth = 2.0;
    self.frontFillLayer.fillColor = nil;
    [self.layer addSublayer:self.frontFillLayer];
    self.frontFillLayer.strokeColor = [UIColor colorWithRed:43.0 / 255.0 green:150.0 / 255.0 blue:237.0 / 255.0 alpha:1.0].CGColor;
}

- (void)setProgressValue:(CGFloat)progressValue {
    progressValue = MAX(MIN(progressValue, 1.0), 0.0);
    CGFloat width = self.bounds.size.width;
    
    self.frontFillBezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(width * 0.5, width * 0.5) radius:(CGRectGetWidth(self.bounds) - 2.0) * 0.5 startAngle:-0.25 * 2.0 * M_PI endAngle:(2.0 * M_PI) * progressValue - 0.25 * 2.0 * M_PI clockwise:YES];
    self.frontFillLayer.path = self.frontFillBezierPath.CGPath;
}

@end
