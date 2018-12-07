//
//  ZPhotoPreViewController.h
//  zPic
//
//  Created by zykhbl on 2017/7/19.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZViewController.h"
#import "ZPreCollectionViewCell.h"

@protocol ZPhotoPreViewControllerDelegate;

@interface ZPhotoPreViewController : ZViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, ZPreCollectionViewCellDelegate>

@property (nonatomic, assign) id<ZPhotoPreViewControllerDelegate> delegate;
@property (nonatomic, strong) UILabel *selectedLabel;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger curIndex;
@property (nonatomic, assign) NSUInteger scrollIndex;
@property (nonatomic, assign) BOOL hiddenToolbar;
@property (nonatomic, assign) NSInteger photoCount;
@property (nonatomic, assign) BOOL showedExif;
@property (nonatomic, assign) CGRect showRect;
@property (nonatomic, assign) CGRect hiddenRect;
@property (nonatomic, strong) UILabel *exifLabel;

@end

@protocol ZPhotoPreViewControllerDelegate <NSObject>

- (void)ZPhotoPreViewController:(ZPhotoPreViewController*)preVC select:(NSUInteger)index;

@end
