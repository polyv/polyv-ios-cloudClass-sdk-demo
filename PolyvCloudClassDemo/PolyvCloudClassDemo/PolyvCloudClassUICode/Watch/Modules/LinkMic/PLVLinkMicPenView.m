//
//  PLVLinkMicPenView.m
//  PolyvCloudClassSDK
//
//  Created by zykhbl on 2019/7/23.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVLinkMicPenView.h"
#import "PCCUtils.h"

@interface PLVLinkMicPenView ()

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSArray *colorStrArray;
@property (nonatomic, strong) NSMutableArray *btns;
@property (nonatomic, assign) NSInteger penSelectedIndex;
@property (nonatomic, strong) UIButton *eraserBtn;
@property (nonatomic, assign) CGFloat wh;

@end

@implementation PLVLinkMicPenView

- (void)addSubViews {
    self.backgroundColor = [UIColor colorWithWhite:53.0 / 255.0 alpha:1.0];
    self.colors = @[[UIColor colorWithRed:1.0 green:91.0 / 255.0 blue:91.0 / 255.0 alpha:1.0], [UIColor colorWithRed:59.0 / 255.0 green:164.0 / 255.0 blue:1.0 alpha:1.0], [UIColor colorWithRed:1.0 green:227.0 / 255.0 blue:91.0 / 255.0 alpha:1.0]];
    self.colorStrArray = @[@"#FF5B5B", @"#3BA4FF", @"#FFE35B"];
    self.btns = [[NSMutableArray alloc] init];
    self.wh = 24.0;
    self.penSelectedIndex = -1;
    
    for (NSInteger index = 0; index < 4; index++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 100 + index;
        if (index == 3) {
            [btn setImage:[PCCUtils getLinkMicImage:@"plv_eraser"] forState:UIControlStateNormal];
            [btn setImage:[PCCUtils getLinkMicImage:@"plv_erasered"] forState:UIControlStateSelected];
        } else {
            btn.backgroundColor = self.colors[index];
            btn.layer.cornerRadius = self.wh * 0.5;
            btn.layer.borderWidth = 3.0;
            btn.layer.borderColor = [UIColor clearColor].CGColor;
        }
        [btn addTarget:self action:@selector(penBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        [self.btns addObject:btn];
    }
}

- (void)layout:(BOOL)fullscreen {
    NSInteger count = 4;
    
    CGFloat space = 40.0;
    if([@"iPad" isEqualToString:[UIDevice currentDevice].model]) {
        space = 50.0;
    }
    if (fullscreen) {
        CGFloat dx = (self.bounds.size.width - self.wh) * 0.5;
        CGFloat baseSpace = (self.bounds.size.height - count * self.wh) / (count + 1);
        if (baseSpace < space) {
            space = baseSpace;
        }
        CGFloat dy = (self.bounds.size.height - count * self.wh - (count - 1) * space) * 0.5;
        NSUInteger index = 0;
        for (UIButton *btn in self.btns) {
            CGRect rect = CGRectMake(dx, dy + index * (self.wh + space), self.wh, self.wh);
            btn.frame = rect;
            index++;
        }
    } else {
        CGFloat baseSpace = (self.bounds.size.width - count * self.wh) / (count + 1);
        if (baseSpace < space) {
            space = baseSpace;
        }
        CGFloat dx = (self.bounds.size.width - count * self.wh - (count - 1) * space) * 0.5;
        CGFloat dy = (self.bounds.size.height - self.wh) * 0.5;
        NSUInteger index = 0;
        for (UIButton *btn in self.btns) {
            CGRect rect = CGRectMake(dx + index * (self.wh + space), dy, self.wh, self.wh);
            btn.frame = rect;
            index++;
        }
    }
}

- (IBAction)penBtnAction:(UIButton *)btn {
    if (btn.selected) {
        return;
    }
    for (UIButton *button in self.btns) {
        if (button != btn) {
            button.selected = NO;
            if (button.tag - 100 < 3) {
                button.layer.borderColor = [UIColor clearColor].CGColor;
            }
        }
    }
    
    btn.selected = !btn.selected;
    if (btn.selected) {
        btn.layer.borderColor = [UIColor whiteColor].CGColor;
        self.penSelectedIndex = btn.tag - 100;
    } else {
        btn.layer.borderColor = [UIColor clearColor].CGColor;
        self.penSelectedIndex = -1;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(penViewAction:)]) {
        [self.delegate penViewAction:self];
    }
}

- (void)chooseRedPen {
    [self penBtnAction:self.btns[0]];
}

@end
