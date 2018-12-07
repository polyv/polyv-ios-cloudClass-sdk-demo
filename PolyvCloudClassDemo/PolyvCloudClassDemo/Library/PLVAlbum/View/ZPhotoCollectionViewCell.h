//
//  ZPhotoCollectionViewCell.h
//  zPic
//
//  Created by zykhbl on 2017/7/10.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZPhotoCollectionViewCellDelegate;

@interface ZPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) id<ZPhotoCollectionViewCellDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIImageView *photoImgView;
@property (nonatomic, strong) UIView *selectedBgView;
@property (nonatomic, strong) UILabel *selectedLabel;
@property (nonatomic, strong) UILabel *videoDurationLabel;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;

@end

@protocol ZPhotoCollectionViewCellDelegate <NSObject>

- (void)ZPhotoCollectionViewCell:(ZPhotoCollectionViewCell*)cell preview:(BOOL)glag;

@end
