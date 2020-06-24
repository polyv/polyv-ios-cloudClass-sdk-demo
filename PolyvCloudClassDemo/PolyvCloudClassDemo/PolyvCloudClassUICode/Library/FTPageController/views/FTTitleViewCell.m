//
//  FTTitleViewCell.m
//  FTPageController
//
//  Created by ftao on 04/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "FTTitleViewCell.h"

@implementation FTTitleViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.clicked = NO;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat width = frame.size.width;
        CGFloat height = frame.size.height;

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -5, width, height)];
        _titleLabel.textColor = [UIColor darkGrayColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 1;
        [self addSubview:_titleLabel];

        float indicatorViewW = 32.0;
        float indicatorViewH = 3.0;
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake((width - indicatorViewW) / 2.0, height - indicatorViewH, indicatorViewW, indicatorViewH)];
        _indicatorView.backgroundColor = [UIColor colorWithRed:33/255.0 green:150/255.0 blue:243/255.0 alpha:1.0];
        [self addSubview:_indicatorView];
        _indicatorView.hidden = YES;
        _indicatorView.layer.cornerRadius = 1.5;
        _indicatorView.layer.masksToBounds = YES;
    }
    return self;
}

- (void)setClicked:(BOOL)clicked {
    _clicked = clicked;
    
    _indicatorView.hidden = !clicked;
    _titleLabel.textColor = clicked ? [UIColor colorWithRed:33/255.0 green:150/255.0 blue:243/255.0 alpha:1.0] : [UIColor darkGrayColor];
}

+ (CGFloat)cellWidth {
    return 90.0;
}

@end
