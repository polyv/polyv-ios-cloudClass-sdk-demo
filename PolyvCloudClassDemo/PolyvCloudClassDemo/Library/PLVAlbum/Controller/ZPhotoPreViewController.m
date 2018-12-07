//
//  ZPhotoPreViewController.m
//  zPic
//
//  Created by zykhbl on 2017/7/19.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZPhotoPreViewController.h"
#import "ZImageInfo.h"
#import "SDWebImageDecoder.h"
#import "MyTool.h"
#import "ZPicDefine.h"

#define NumberOfItemsInSection                  1
#define ZPreCollectionViewCellIdentifier        @"ZPreCollectionViewCell"

@implementation ZPhotoPreViewController

@synthesize delegate;
@synthesize selectedLabel;
@synthesize photos;
@synthesize selectedItems;
@synthesize collectionView;
@synthesize curIndex;
@synthesize scrollIndex;
@synthesize hiddenToolbar;
@synthesize photoCount;
@synthesize showedExif;
@synthesize showRect;
@synthesize hiddenRect;
@synthesize exifLabel;

- (id)init {
    self = [super init];
    
    if (self) {
        self.selectedItems = [NSMutableArray arrayWithCapacity:1000];
    }
    
    return self;
}

- (void)changeSelectStatus:(BOOL)flag index:(NSUInteger)index {
    self.selectedLabel.text = flag ? [NSString stringWithFormat:@"%d", (int)index + 1] : nil;
}

- (void)didScroll {
    NSUInteger index = self.collectionView.contentOffset.x / self.collectionView.bounds.size.width;
    CGFloat dx = fabs(self.collectionView.contentOffset.x - self.scrollIndex * self.collectionView.bounds.size.width);
    if (index != self.scrollIndex && dx >= 0.5 * self.collectionView.bounds.size.width) {
        self.scrollIndex = index;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:self.scrollIndex];
        if ([self.selectedItems containsObject:indexPath]) {
            NSUInteger index = [self.selectedItems indexOfObject:indexPath];
            [self changeSelectStatus:YES index:index];
        } else {
            [self changeSelectStatus:NO index:0];
        }
        
        self.title = [NSString stringWithFormat:@"预览(%d/%d)", (int)index + 1, (int)self.photoCount];
    }
}

- (void)didSelect:(NSIndexPath*)indexPath {
    if ([self.selectedItems containsObject:indexPath]) {
        NSUInteger delIndex = [self.selectedItems indexOfObject:indexPath];
        [self.selectedItems removeObjectAtIndex:delIndex];
        
        [self changeSelectStatus:NO index:0];
    } else {
        if (self.selectedItems.count > 0) {
            [MyTool presentAlertController:@"你只能选择一张图片" inViewController:self];
            return;
        }
        [self.selectedItems addObject:indexPath];
        [self changeSelectStatus:YES index:self.selectedItems.count - 1];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(ZPhotoPreViewController:select:)]) {
        NSUInteger index = indexPath.row + indexPath.section * NumberOfItemsInSection;
        [self.delegate ZPhotoPreViewController:self select:index];
    }
}

- (IBAction)select:(id)sender {
    NSUInteger index = self.collectionView.contentOffset.x / self.collectionView.bounds.size.width;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    [self didSelect:indexPath];
    self.navigationItem.rightBarButtonItem.enabled = self.selectedItems.count > 0;
}

- (ZImageInfo*)getZImageInfo:(NSIndexPath*)indexPath {
    NSInteger index = indexPath.row + indexPath.section * NumberOfItemsInSection;
    ZImageInfo *imgInfo = [self.photos objectAtIndex:index];
    return imgInfo;
}

- (IBAction)send:(id)sender {
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:10];
    for (NSIndexPath *indexPath in self.selectedItems) {
        [UIImage requestOriginImageData:[self getZImageInfo:indexPath].asset synchronous:YES imageHandler:^(UIImage *img, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info) {
            [items addObject:img];
        } dataHandler:nil errorHandler:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ViewBackgroupColor;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    CGFloat myToolbarHeight = 0.0;
    if (!self.hiddenToolbar) {
        [MyTool rightBarButtonItem:@"发送" action:@selector(send:) target:self];
        self.navigationItem.rightBarButtonItem.enabled = self.selectedItems.count > 0;
        
        if (self.selectedLabel == nil) {
            myToolbarHeight = ToolbarHeight;
            CGRect btnRect = CGRectMake(0.0, self.view.bounds.size.height - myToolbarHeight, self.view.bounds.size.width, myToolbarHeight);
            UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            selectBtn.frame = btnRect;
            selectBtn.backgroundColor = NavBackgroupColor;
            [selectBtn addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:selectBtn];
            
            CGRect labelRect = CGRectMake((selectBtn.bounds.size.width - SelectedWidth) * 0.5, (SToolbarHeight - SelectedWidth) * 0.5, SelectedWidth, SelectedWidth);
            self.selectedLabel = [MyTool createUILabel:labelRect fontOfSize:15.0 textColor:NormalColor inView:selectBtn];
        }
    }
    
    if (self.collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        CGFloat w = (self.view.bounds.size.width - (NumberOfItemsInSection - 1)) / NumberOfItemsInSection;
        flowLayout.itemSize = CGSizeMake(w, self.view.bounds.size.height - self.originY - myToolbarHeight);
        CGRect collectionRect = CGRectMake(0.0, self.originY, self.view.bounds.size.width, self.view.bounds.size.height - self.originY - myToolbarHeight);
        self.collectionView = [[UICollectionView alloc] initWithFrame:collectionRect collectionViewLayout:flowLayout];
        [self.collectionView registerClass:[ZPreCollectionViewCell class] forCellWithReuseIdentifier:ZPreCollectionViewCellIdentifier];
        self.collectionView.backgroundColor = BgClearColor;
        self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.pagingEnabled = YES;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        [self.view insertSubview:self.collectionView atIndex:0];

        self.scrollIndex = -1;
        [self.collectionView setContentOffset:CGPointMake(self.curIndex * self.collectionView.bounds.size.width, 0.0)];
        
        [self didScroll];
    }
    
    if (self.exifLabel == nil) {
        self.showRect = CGRectMake(0.0, self.collectionView.frame.origin.y + self.collectionView.frame.size.height - 100.0, self.view.bounds.size.width, 100.0);
        self.hiddenRect = CGRectMake(0.0, self.collectionView.frame.origin.y + self.collectionView.frame.size.height, self.view.bounds.size.width, 100.0);
        self.exifLabel = [MyTool createUILabel:self.hiddenRect fontOfSize:15.0 textColor:NormalColor backgroundColor:NavBackgroupColor textAlignment:NSTextAlignmentLeft inView:nil];
        self.exifLabel.numberOfLines = 0;
        [self.view insertSubview:self.exifLabel aboveSubview:self.collectionView];
    }
}

//============UICollectionViewDataSource============
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return (self.photoCount + NumberOfItemsInSection - 1) / NumberOfItemsInSection;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return NumberOfItemsInSection;
}

- (__kindof UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    ZPreCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:ZPreCollectionViewCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.indexPath = indexPath;
    cell.chaged = NO;
    cell.exifStr = nil;
    [cell.scrollView setZoomScale:1.0 animated:NO];
    cell.photoImgView.frame = CGRectZero;
    cell.photoImgView.image = nil;
    
    NSInteger index = indexPath.row + indexPath.section * NumberOfItemsInSection;
    if (index < self.photoCount) {
        CGFloat scale = [UIScreen mainScreen].scale;
        ZImageInfo *imgInfo = [self.photos objectAtIndex:index];
        CGFloat w = imgInfo.pixelSize.width / scale;
        CGFloat h = imgInfo.pixelSize.height / scale;
        CGFloat scaleW = cell.bounds.size.width / w;
        CGFloat scaleH = cell.bounds.size.height / h;
        
        if (scaleW > scaleH) {
            w = w * scaleH;
            h = cell.bounds.size.height;
            cell.scrollView.maximumZoomScale = (cell.bounds.size.width / w) * 2.0;
        } else {
            w = cell.bounds.size.width;
            h = h * scaleW;
            cell.scrollView.maximumZoomScale = (cell.bounds.size.height / h) * 2.0;
        }
        cell.baseScale = cell.scrollView.maximumZoomScale;
        
        CGFloat x = cell.bounds.size.width >= w ? (cell.bounds.size.width - w) * 0.5 : 0.0;
        CGFloat y = cell.bounds.size.height >= h ? (cell.bounds.size.height - h) * 0.5 : 0.0;
        cell.photoImgView.frame = CGRectMake(x, y, w, h);
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_HIGH), ^{
            if (cell.indexPath == indexPath) {
                [UIImage requestThumbnailsImage:imgInfo.asset deliveryMode:PHImageRequestOptionsDeliveryModeFastFormat resultHandler:^(UIImage *_Nullable result, NSDictionary *_Nullable info) {
                    if (cell.indexPath == indexPath) {
                        UIImage *thumbnails = [UIImage decodedOriginImage:result];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (cell.photoImgView.image == nil) {
                                cell.photoImgView.image = thumbnails;
                            }
                        });
                    }
                }];
            }
        });
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            if (cell.indexPath == indexPath) {
                [UIImage requestOriginImageData:imgInfo.asset synchronous:YES imageHandler:^(UIImage *img, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info) {
                    if (cell.indexPath == indexPath) {
                        UIImage *originImg = [UIImage decodedScaleImage:img];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            cell.photoImgView.image = originImg;
                        });
                    }
                } dataHandler:nil errorHandler:nil];
            }
        });
    }
    
    return cell;
}

//============UICollectionViewDelegate============
- (void)collectionView:(UICollectionView*)collectionView willDisplayCell:(UICollectionViewCell*)cellView forItemAtIndexPath:(NSIndexPath*)indexPath {
    ZPreCollectionViewCell *cell = (ZPreCollectionViewCell*)cellView;
    [cell.scrollView setZoomScale:1.0 animated:NO];
    if (self.showedExif) {
        [self exifAnimation:self.hiddenRect flag:NO];
    }
}

//============UIScrollViewDelegate============
- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    [self didScroll];
}

//============ZPreCollectionViewCellDelegate============
- (void)ZPreCollectionViewCell:(ZPreCollectionViewCell*)cell scrollViewDidEndZooming:(BOOL)flag {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    ZImageInfo *imgInfo = [self getZImageInfo:indexPath];
    CGFloat limit = imgInfo.pixelSize.width * imgInfo.pixelSize.height;
    if (limit < MemeoryLarge) {
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            [UIImage requestOriginImageData:imgInfo.asset synchronous:YES imageHandler:^(UIImage *img, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info) {
                UIImage *originImg = [UIImage decodedOriginImage:img];
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.photoImgView.image = originImg;
                });
            } dataHandler:nil errorHandler:nil];
        });
    }
}

- (void)exifAnimation:(CGRect)rect flag:(BOOL)flag {
    __weak typeof(self) weak_self = self;
    [UIView animateWithDuration:0.3 animations:^ {
        weak_self.exifLabel.frame = rect;
    } completion:^(BOOL finished) {
        weak_self.showedExif = flag;
    }];
}

- (void)ZPreCollectionViewCell:(ZPreCollectionViewCell*)cell showExif:(BOOL)flag {
    if (!self.showedExif) {
        if (cell.exifStr == nil) {
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            ZImageInfo *imgInfo = [self getZImageInfo:indexPath];
            __weak typeof(self) weak_self = self;
            dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                [UIImage requestOriginImageData:imgInfo.asset synchronous:YES imageHandler:nil dataHandler:^(NSData *imgData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    NSDictionary *exifInfo = [UIImage getExifFromImageData:imgData];
                    NSString *lens = [exifInfo objectForKey:@"LensMake"];
                    if (lens == nil || ![lens containsString:@"mm"]) {
                        lens = [exifInfo objectForKey:@"LensModel"];
                    }
                    
                    if (lens != nil && [lens containsString:@"mm"]) {
                        NSNumber *apertureValue = [exifInfo objectForKey:@"ApertureValue"];
                        NSNumber *exposureTime = [exifInfo objectForKey:@"ExposureTime"];
                        NSNumber *shutterSpeedValue = [exifInfo objectForKey:@"ShutterSpeedValue"];
                        cell.exifStr = [NSString stringWithFormat:NSLocalizedString(@"exifInfo", nil), lens, apertureValue.floatValue, exposureTime.floatValue, shutterSpeedValue.floatValue, imgInfo.pixelSize.width, imgInfo.pixelSize.height];
                        cell.textAlignment = NSTextAlignmentLeft;
                    } else {
                        cell.exifStr = [NSString stringWithFormat:NSLocalizedString(@"exifError", nil), imgInfo.pixelSize.width, imgInfo.pixelSize.height];
                        cell.textAlignment = NSTextAlignmentCenter;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weak_self.exifLabel.textAlignment = cell.textAlignment;
                        weak_self.exifLabel.text = cell.exifStr;
                        [weak_self exifAnimation:self.showRect flag:YES];
                    });
                } errorHandler:nil];
            });
        } else {
            self.exifLabel.textAlignment = cell.textAlignment;
            self.exifLabel.text = cell.exifStr;
            [self exifAnimation:self.showRect flag:YES];
        }
    } else {
        [self exifAnimation:self.hiddenRect flag:NO];
    }
}

@end
