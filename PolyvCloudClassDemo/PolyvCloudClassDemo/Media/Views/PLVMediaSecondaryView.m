//
//  PLVMediaSecondaryView.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/9.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVMediaSecondaryView.h"

@interface PLVMediaSecondaryView ()

@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGRect rangeRect;

@end

@implementation PLVMediaSecondaryView

- (void)loadSubviews {
    self.clipsToBounds = YES;
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeBtn.frame = CGRectMake(0.0, 0.0, 30.0, 30.0);
    [self.closeBtn setImage:[UIImage imageNamed:@"skin_close.png"] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeBtn];
    [self showCloseBtn];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showCloseBtn)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    self.lastPoint = self.bounds.origin;
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    [self addGestureRecognizer:panGestureRecognizer];
}

- (IBAction)close:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeSecondaryView:)]) {
        [self.delegate closeSecondaryView:self];
    }
}

- (void)hiddenCloseBtn {
   self.closeBtn.hidden = YES;
}

- (void)hiddenCloseBtnAfterDelay {
    [self performSelector:@selector(hiddenCloseBtn) withObject:nil afterDelay:5.0];
}

- (void)showCloseBtn {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.closeBtn.hidden = NO;
    [self hiddenCloseBtnAfterDelay];
}

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self.superview];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.closeBtn.hidden = NO;
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
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self hiddenCloseBtnAfterDelay];
    }
    self.lastPoint = p;
}

@end
