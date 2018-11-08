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

- (void)setClicked:(BOOL)clicked {
    _clicked = clicked;
    
    _indicatorView.hidden = !clicked;
    _titleLabel.textColor = clicked ? [UIColor colorWithRed:33/255.0 green:150/255.0 blue:243/255.0 alpha:1.0] : [UIColor darkGrayColor];
}

@end
