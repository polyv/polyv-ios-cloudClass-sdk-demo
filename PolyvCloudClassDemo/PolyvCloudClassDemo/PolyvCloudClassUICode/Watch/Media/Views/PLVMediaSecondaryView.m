//
//  PLVMediaSecondaryView.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/9.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVMediaSecondaryView.h"

@interface PLVMediaSecondaryView ()

@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGRect rangeRect;

@end

@implementation PLVMediaSecondaryView

#pragma mark - public
- (void)loadSubviews {
    self.clipsToBounds = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self addGestureRecognizer:tap];
    
    self.lastPoint = self.bounds.origin;
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    [self addGestureRecognizer:panGestureRecognizer];
}

- (void)tapAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchScreenOnManualControl:)]) {
        [self.delegate switchScreenOnManualControl:self];
    }
}

#pragma mark - gesture
- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer*)gestureRecognizer {
    if (!self.fullscreen && !self.canMove) {
        return;
    }
    CGPoint p = [gestureRecognizer locationInView:self.superview];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (@available(iOS 11.0, *)) {
            CGRect safeRect = self.superview.safeAreaLayoutGuide.layoutFrame;
            if (self.fullscreen && safeRect.origin.y == 20.0) {
                safeRect.size.height += safeRect.origin.y;
                safeRect.origin.y = 0.0;
            }
            self.rangeRect = safeRect;
        } else {
            self.rangeRect = self.superview.bounds;
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGRect rect = self.frame;
        rect.origin.x += (p.x - self.lastPoint.x);
        rect.origin.y += (p.y - self.lastPoint.y);
        if (rect.origin.x < self.rangeRect.origin.x) {
            rect.origin.x = self.rangeRect.origin.x;
        } else if (rect.origin.x > self.rangeRect.origin.x + self.rangeRect.size.width - rect.size.width) {
            rect.origin.x = self.rangeRect.origin.x + self.rangeRect.size.width - rect.size.width;
        }
        if (rect.origin.y < self.rangeRect.origin.y) {
            rect.origin.y = self.rangeRect.origin.y;
        } else if (rect.origin.y > self.rangeRect.origin.y + self.rangeRect.size.height - rect.size.height) {
            rect.origin.y = self.rangeRect.origin.y + self.rangeRect.size.height - rect.size.height;
        }
        self.frame = rect;
    }
    self.lastPoint = p;
}

@end
