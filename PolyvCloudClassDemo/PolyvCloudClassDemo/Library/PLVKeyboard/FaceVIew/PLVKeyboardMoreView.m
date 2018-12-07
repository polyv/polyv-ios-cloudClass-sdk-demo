//
//  PLVKeyboardMoreView.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/29.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVKeyboardMoreView.h"

#define PLVMoreCollectionViewCellIdentifier @"PLVMoreCollectionViewCellIdentifier"
#define CellWidth    54.0
#define CellHeight   74.0
#define NumberOfItemsInSection  1

@interface PLVMoreCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *moreBtn;

- (void)changeTitleStyle;

@end

@implementation PLVMoreCollectionViewCell

#pragma mark - life cycle
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.moreBtn.frame = CGRectMake(0.0, 0.0, CellWidth, CellHeight);
        self.moreBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [self.moreBtn setTitleColor:[UIColor colorWithRed:130.0 /255.0 green:130.0 /255.0 blue:130.0 /255.0 alpha:1.0] forState:UIControlStateNormal];
        [self addSubview:self.moreBtn];
    }
    return self;
}

#pragma mark - public
- (void)changeTitleStyle {
    self.moreBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.moreBtn setImageEdgeInsets:UIEdgeInsetsMake(-20.0, 0.0, 0.0, 0.0)];
    [self.moreBtn setTitleEdgeInsets:UIEdgeInsetsMake(55.0, -CellWidth, 0.0, 0.0)];
}

@end

@interface PLVKeyboardMoreView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@end

@implementation PLVKeyboardMoreView

#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.flowLayout.itemSize = CGSizeMake(CellWidth, CellHeight);
        self.flowLayout.sectionInset = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0);
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
        [self.collectionView registerClass:[PLVMoreCollectionViewCell class] forCellWithReuseIdentifier:PLVMoreCollectionViewCellIdentifier];
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.collectionView];
    }
    return self;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (__kindof UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    PLVMoreCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:PLVMoreCollectionViewCellIdentifier forIndexPath:indexPath];
    
    NSInteger index = indexPath.row + indexPath.section * NumberOfItemsInSection;
    if (index == 0) {
        [cell.moreBtn setImage:[UIImage imageNamed:@"plv_album.png"] forState:UIControlStateNormal];
        [cell.moreBtn setTitle:@"照片" forState:UIControlStateNormal];
        [cell.moreBtn addTarget:self action:@selector(openAlbum:) forControlEvents:UIControlEventTouchUpInside];
    } else if (index == 1) {
        [cell.moreBtn setImage:[UIImage imageNamed:@"plv_shoot.png"] forState:UIControlStateNormal];
        [cell.moreBtn setTitle:@"拍摄" forState:UIControlStateNormal];
        [cell.moreBtn addTarget:self action:@selector(shoot:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [cell changeTitleStyle];
    return cell;
}

#pragma mark - Action
- (IBAction)openAlbum:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(openAlbum:)]) {
        [self.delegate openAlbum:self];
    }
}

- (IBAction)shoot:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(shoot:)]) {
        [self.delegate shoot:self];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize size = CGSizeMake(0.0, self.collectionView.bounds.size.height);
    if (section == 0) {
        size = CGSizeMake(self.flowLayout.sectionInset.left, self.collectionView.bounds.size.height);
    }
    return size;
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    CGSize size = CGSizeMake(0.0, self.collectionView.bounds.size.height);
    if (section == 1) {
        size = CGSizeMake(self.flowLayout.sectionInset.right, self.collectionView.bounds.size.height);
    }
    return size;
}

@end
