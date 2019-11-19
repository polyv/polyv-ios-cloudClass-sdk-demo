//
//  FTTitleViewCell.h
//  FTPageController
//
//  Created by ftao on 04/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTTitleViewCell : UICollectionViewCell

@property (nonatomic, assign) BOOL clicked;

@property (strong, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) UIView *indicatorView;

+ (CGFloat)cellWidth;

@end
