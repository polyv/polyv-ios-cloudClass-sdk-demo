//
//  ZPickerController.m
//  zPic
//
//  Created by zykhbl on 2017/7/10.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZPickerController.h"
#import "ZImageInfo.h"
#import "ZPhotoCollectionFooterView.h"
#import "SDWebImageDecoder.h"
#import "MyTool.h"
#import "ZPicDefine.h"

#define ZPhotoCollectionViewCellIdentifier      @"ZPhotoCollectionViewCell"
#define ZPhotoCollectionHeaderViewIdentifier    @"ZPhotoCollectionHeaderView"
#define ZPhotoCollectionFooterViewIdentifier    @"ZPhotoCollectionFooterView"

@implementation ZPickerController

@synthesize delegate;
@synthesize collectionFooterHeight;
@synthesize pickerModer;
@synthesize maxPhotoAndVideoCount;
@synthesize flowLayout;
@synthesize collectionView;
@synthesize assetCollection;
@synthesize assets;
@synthesize photos;
@synthesize photoCount;
@synthesize videoCount;
@synthesize selectedItems;
@synthesize panGestureRecognizer;
@synthesize panSelectedItems;
@synthesize delPanItems;
@synthesize prePanSelectIndexPath;
@synthesize firstPanSelectIndexPath;
@synthesize prePanPoint;
@synthesize originY;
@synthesize cellWidth;
@synthesize runLoopModes;
@synthesize displayLink;
@synthesize moving;
@synthesize speed;
@synthesize toolBar;
@synthesize albumsBtn;
@synthesize arrowDownImgView;
@synthesize albumsVC;
@synthesize countOfOneScreen;

+ (void)moveThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"CollectionMoveThread"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread*)moveThread {
    static NSThread *_moveThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _moveThread = [[NSThread alloc] initWithTarget:self selector:@selector(moveThreadEntryPoint:) object:nil];
        [_moveThread setThreadPriority:1.0];
        [_moveThread start];
    });
    
    return _moveThread;
}

- (void)clearDisplayLink {
    if (self.displayLink != nil) {
        [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:[[self.runLoopModes allObjects] objectAtIndex:0]];
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (NSIndexPath*)indexPathForRow:(NSInteger)index {
    return [NSIndexPath indexPathForRow:index % PickerNumberOfItemsInSection inSection:index / PickerNumberOfItemsInSection];
}

- (void)fetchAlbum {
    self.photoCount = 0;
    self.videoCount = 0;
    for (PHAsset *asset in self.assets) {
        if (asset.mediaType == PHAssetMediaTypeImage) {
            ZImageInfo *imgInfo = [[ZImageInfo alloc] init];
            imgInfo.asset = asset;
            imgInfo.pixelSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
            [self.photos insertObject:imgInfo atIndex:self.photoCount++];
        } else if (self.pickerModer == PickerModerOfVideo && asset.mediaType == PHAssetMediaTypeVideo) {
            ZImageInfo *imgInfo = [[ZImageInfo alloc] init];
            imgInfo.asset = asset;
            imgInfo.pixelSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
            imgInfo.video = YES;
            imgInfo.duration = asset.duration;
            [self.photos insertObject:imgInfo atIndex:self.photos.count];
            self.videoCount++;
        }
    }
    
    NSInteger emptyCount = self.photoCount % PickerNumberOfItemsInSection;
    if (emptyCount > 0) {
        for (int i = 0; i < (PickerNumberOfItemsInSection - emptyCount); i++) {
            ZImageInfo *imgInfo = [[ZImageInfo alloc] init];
            [self.photos insertObject:imgInfo atIndex:self.photoCount + i];
        }
    }
    
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        __strong typeof(self) strong_self = weak_self;
        for (ZImageInfo *imgInfo in strong_self.photos) {//获取正确的图片大小
            if (imgInfo.asset != nil && (imgInfo.pixelSize.width > LimitWidth || imgInfo.pixelSize.height > LimitWidth)) {
                [UIImage requestOriginImageData:imgInfo.asset synchronous:YES imageHandler:^(UIImage *img, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info) {
                    imgInfo.pixelSize = [UIImage getImageSize:img];
                } dataHandler:nil errorHandler:nil];
            }
        }
    });
}

- (void)accessAlbum {
    self.assetCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    self.assets = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:nil];
    [self fetchAlbum];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)presentAlertController:(NSString *)message {
    [MyTool presentAlertController:message inViewController:self];
}

- (id)initWithPickerModer:(PickerModer)pModer {
    self = [super init];
    
    if (self) {
        self.collectionFooterHeight = SToolbarHeight + 1.0;
        self.pickerModer = pModer;
        self.maxPhotoAndVideoCount = 0;
        self.photos = [NSMutableArray arrayWithCapacity:1000];
        self.selectedItems = [NSMutableArray arrayWithCapacity:1000];
        self.panSelectedItems = [NSMutableArray arrayWithCapacity:1000];
        self.delPanItems = [NSMutableArray arrayWithCapacity:1000];
        CGFloat h = [UIScreen mainScreen].bounds.size.width / PickerNumberOfItemsInSection;
        self.countOfOneScreen = (int)([UIScreen mainScreen].bounds.size.height / h) * 1.2 * PickerNumberOfItemsInSection;
        self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
        
        self.runLoopModes = [NSSet setWithObject:NSDefaultRunLoopMode];
        [ZPickerController moveThread];
        
        __weak typeof(self) weak_self = self;
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if(status == PHAuthorizationStatusAuthorized) {
                    [weak_self accessAlbum];
                    if (weak_self.collectionView != nil) {
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            [weak_self changeAlbumsBtnTitleFrame];
                            [weak_self.collectionView reloadData];
                            [weak_self scrollToButtom:0.0];
                        });
                    }
                } else {
                    [self performSelector:@selector(presentAlertController:) withObject:@"你没开通访问相册的权限，如要开通，请移步到:设置->隐私->照片 开启" afterDelay:0.1];
                }
            }];
        } else if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
            [self performSelector:@selector(presentAlertController:) withObject:@"你没开通访问相册的权限，如要开通，请移步到:设置->隐私->照片 开启" afterDelay:0.1];
        } else {
            [self accessAlbum];
        }
    }
    
    return self;
}

- (void)setContentOffset {
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^ {
        if (weak_self.displayLink != nil && weak_self.moving && weak_self.collectionView.contentSize.height > weak_self.collectionView.bounds.size.height) {
            CGFloat y = weak_self.collectionView.contentOffset.y + weak_self.speed;
            if (y < -weak_self.originY) {
                y = -weak_self.originY;
            } else if (y > weak_self.collectionView.contentSize.height - weak_self.collectionView.bounds.size.height) {
                y = weak_self.collectionView.contentSize.height - weak_self.collectionView.bounds.size.height;
            }
            
            if (y != weak_self.collectionView.contentOffset.y) {
                weak_self.collectionView.contentOffset = CGPointMake(0.0, y);
                CGPoint p = [weak_self.panGestureRecognizer locationInView:weak_self.collectionView];
                NSIndexPath *curIndexPath = [weak_self lookupIndexPathInPoint:p];
                [weak_self selectItems:curIndexPath];
            }
        }
    });
}

- (void)doStart {
    if (self.displayLink == nil) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(setContentOffset)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)startMovingThread {
    [self performSelector:@selector(doStart) onThread:[ZPickerController moveThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
}

- (NSIndexPath*)lookupIndexPathInPoint:(CGPoint)p {
    CGPoint pp = CGPointMake(p.x - self.flowLayout.minimumInteritemSpacing, p.y - self.flowLayout.minimumInteritemSpacing);
    for (ZPhotoCollectionViewCell *cell in self.collectionView.visibleCells) {
        if (CGRectContainsPoint(cell.frame, p) || CGRectContainsPoint(cell.frame, pp)) {
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            NSInteger index = [self indexOfIndexPath:indexPath];
            if (index < self.photoCount) {
                return indexPath;
            } else if (index < self.photos.count - self.videoCount) {
                return [self indexPathForRow:self.photoCount - 1];
            }
        }
    }
    
    return nil;
}

- (NSInteger)indexOfIndexPath:(NSIndexPath*)indexPath {
    return indexPath.row + indexPath.section * PickerNumberOfItemsInSection;
}

- (void)showOrHiddenToolBar {
    self.toolBar.hidden = self.selectedItems.count == 0;
}

- (void)showOrHiddenSelectLabelOfVisibleCells {
    for (ZPhotoCollectionViewCell *cell in self.collectionView.visibleCells) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        [self showOrHiddenSelectLabelOfCell:cell indexPaht:indexPath];
    }
    [self showOrHiddenToolBar];
}

- (void)selectItems:(NSIndexPath*)curIndexPath {
    if (curIndexPath != nil) {
        if (self.firstPanSelectIndexPath == nil) {
            self.firstPanSelectIndexPath = curIndexPath;
        } else {
            if (![curIndexPath isEqual:self.prePanSelectIndexPath]) {
                NSInteger firstIndex = [self indexOfIndexPath:self.firstPanSelectIndexPath];
                NSInteger curIndex = [self indexOfIndexPath:curIndexPath];
                
                NSInteger minIndex = MIN(firstIndex, curIndex);
                NSInteger maxIndex = MAX(firstIndex, curIndex);
                for (NSIndexPath *indexPath in self.panSelectedItems) {
                    NSInteger index = [self indexOfIndexPath:indexPath];
                    if (index < minIndex || index > maxIndex) {
                        [self.delPanItems addObject:indexPath];
                        if ([self.selectedItems containsObject:indexPath]) {
                            [self removeItemAtIndexPath:indexPath];
                        }
                    }
                }
                [self.panSelectedItems removeObjectsInArray:self.delPanItems];
                [self.delPanItems removeAllObjects];
                
                if (firstIndex > curIndex) {
                    for (NSInteger index = firstIndex; index >= curIndex; index--) {
                        NSIndexPath *indexPath = [self indexPathForRow:index];
                        if (![self.selectedItems containsObject:indexPath] && [self addItemAtIndexPath:indexPath]) {
                            [self.panSelectedItems addObject:indexPath];
                        }
                    }
                } else {
                    for (NSInteger index = firstIndex; index <= curIndex; index++) {
                        NSIndexPath *indexPath = [self indexPathForRow:index];
                        if (![self.selectedItems containsObject:indexPath] && [self addItemAtIndexPath:indexPath]) {
                            [self.panSelectedItems addObject:indexPath];
                        }
                    }
                }
                
                [self showOrHiddenSelectLabelOfVisibleCells];
            }
            
            self.prePanSelectIndexPath = curIndexPath;
        }
    }
}

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *curIndexPath = [self lookupIndexPathInPoint:p];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.panSelectedItems removeAllObjects];
        self.firstPanSelectIndexPath = curIndexPath;
        self.prePanSelectIndexPath = nil;
        self.prePanPoint = [gestureRecognizer locationInView:self.view];
    } else {
        CGPoint tp = [gestureRecognizer locationInView:self.view];
        
        if (tp.y < 120.0 || tp.y > self.view.bounds.size.height - 120.0) {
            CGFloat dy = (tp.y - self.prePanPoint.y) * 10.0;
            if (dy != 0.0) {
                if (tp.y < 120.0) {
                    if (dy > 0.0) {
                        self.moving = NO;
                    } else {
                        self.moving = YES;
                        if (dy < -10.0) {
                            dy = -10.0;
                        }
                        self.speed = dy;
                    }
                } else {
                    if (dy < 0.0) {
                        self.moving = NO;
                    } else {
                        self.moving = YES;
                        if (dy > 10.0) {
                            dy = 10.0;
                        }
                        self.speed = dy;
                    }
                }
            }
        } else {
            self.moving = NO;
            self.speed = 0.0;
        }
        
        self.prePanPoint = tp;
        [self selectItems:curIndexPath];
        
        if (gestureRecognizer.state == UIGestureRecognizerStateFailed || gestureRecognizer.state == UIGestureRecognizerStateCancelled || gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            self.moving = NO;
            [self.panSelectedItems removeAllObjects];
        }
    }
}

- (void)changeAlbumsBtnTitleFrame {
    CGRect titleRect = self.albumsBtn.frame;
    NSString *str = @"没有访问相册的权限";
    if (self.assetCollection != nil) {
        str = self.assetCollection.localizedTitle;
    }
    CGSize textSize = [str sizeWithAttributes:@{NSFontAttributeName : self.albumsBtn.titleLabel.font}];
    titleRect.size.width = textSize.width + 100.0;
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version.doubleValue < 11.0) {
        titleRect.size.width = textSize.width;
    }
    titleRect.origin.x = (self.navigationController.navigationBar.frame.size.width - titleRect.size.width) * 0.5;
    self.albumsBtn.frame = titleRect;
    [self.albumsBtn setTitle:str forState:UIControlStateNormal];
    
    CGRect arrowRect = CGRectMake(textSize.width + 50.0, 16.0, 10.0, 10.0);
    if (version.doubleValue < 11.0) {
        arrowRect = CGRectMake(titleRect.size.width < 50.0 ? 53.0 : titleRect.size.width + 2.0, -2.0, 10.0, 10.0);
    }
    if (self.arrowDownImgView == nil) {
        self.arrowDownImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrowDown.png"]];
        [self.albumsBtn addSubview:self.arrowDownImgView];
    }
    if (self.assetCollection != nil) {
        self.arrowDownImgView.hidden = NO;
    } else {
        self.arrowDownImgView.hidden = YES;
    }
    self.arrowDownImgView.frame = arrowRect;
}

- (void)scrollToButtom:(CGFloat)baseY {
    NSInteger photoSections = (self.photoCount + PickerNumberOfItemsInSection - 1) / PickerNumberOfItemsInSection;
    NSInteger videoSections = (self.videoCount + PickerNumberOfItemsInSection - 1) / PickerNumberOfItemsInSection;
    NSInteger toolbarCount = (self.photoCount > 0 && self.videoCount > 0) ? 2 : 1;
    CGFloat h = self.flowLayout.sectionInset.left + (self.cellWidth + self.flowLayout.minimumInteritemSpacing) * (photoSections + videoSections) + (self.collectionFooterHeight - self.flowLayout.minimumInteritemSpacing) * toolbarCount;
    if (h < self.collectionView.bounds.size.height) {
        h = self.collectionView.bounds.size.height;
    }
    self.collectionView.contentSize = CGSizeMake(self.view.bounds.size.width, h);
    CGFloat y = self.collectionView.contentSize.height - self.collectionView.bounds.size.height + baseY;
    [self.collectionView setContentOffset:CGPointMake(0.0, y)];
}

- (IBAction)exitAcion {
    [self dismissPickerController];
}

- (void)addGestureRecognizer {
    if ((self.pickerModer == PickerModerOfVideo || self.pickerModer == PickerModerOfNormal)) {
//        [self.view addGestureRecognizer:self.panGestureRecognizer];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ViewBackgroupColor;
    [MyTool leftBarButtonItemAction:@selector(exitAcion) target:self];
    self.navigationController.delegate = self;
    self.originY = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    
    if (self.albumsBtn == nil) {
        self.albumsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.albumsBtn.backgroundColor = BgClearColor;
        self.albumsBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        [self.albumsBtn setTitleColor:NormalColor forState:UIControlStateNormal];
        [self.albumsBtn addTarget:self action:@selector(selectAlbum:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = self.albumsBtn;
        [self changeAlbumsBtnTitleFrame];
    }
    
    if (self.collectionView == nil) {
        self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.flowLayout.minimumInteritemSpacing = 1.0;
        self.flowLayout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        self.cellWidth = (int)((self.view.bounds.size.width - (PickerNumberOfItemsInSection - 1) * self.flowLayout.minimumInteritemSpacing - self.flowLayout.sectionInset.left - self.flowLayout.sectionInset.right) / PickerNumberOfItemsInSection);
        self.flowLayout.itemSize = CGSizeMake(self.cellWidth, self.cellWidth);
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.flowLayout];
        [self.collectionView registerClass:[ZPhotoCollectionViewCell class] forCellWithReuseIdentifier:ZPhotoCollectionViewCellIdentifier];
        [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:ZPhotoCollectionHeaderViewIdentifier];
        [self.collectionView registerClass:[ZPhotoCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:ZPhotoCollectionFooterViewIdentifier];
        self.collectionView.backgroundColor = BgClearColor;
        self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        [self.view addSubview:self.collectionView];
        [self scrollToButtom:self.originY];
    }
    
    if (self.toolBar == nil && (self.pickerModer == PickerModerOfVideo || self.pickerModer == PickerModerOfNormal)) {
        self.toolBar = [MyTool createToolBarInView:self.view];
        self.toolBar.hidden = YES;
        
        CGFloat dx = (self.toolBar.bounds.size.width / (self.pickerModer == PickerModerOfNormal ? 4 : 2) - ToolbarBtnWidth) * 0.5;
        CGFloat h = SToolbarHeight;
        CGRect cancelRect = CGRectMake(dx, 0.0, ToolbarBtnWidth, h);
        [MyTool createBtn:@"cancel.png" selectedImgStr:nil disabledImgStr:nil action:@selector(cancelAction:) frame:cancelRect target:self inView:self.toolBar];
        CGRect sendRect = CGRectMake(self.toolBar.bounds.size.width - ToolbarBtnWidth - dx, 0.0, ToolbarBtnWidth, h);
        if (self.pickerModer == PickerModerOfNormal) {
           self.sendBtn = [MyTool createBtn:nil selectedImgStr:nil disabledImgStr:nil action:@selector(sendAction:) frame:sendRect target:self inView:self.toolBar];
            [self.sendBtn setTitle:@"发送" forState:UIControlStateNormal];
        }
    }
    
    [self addGestureRecognizer];
    [self startMovingThread];
    
    self.albumsVC = [[ZAlbumsViewController alloc] init];
    self.albumsVC.delegate = self;
    self.albumsVC.pcikerModer = self.pickerModer;
    CGRect albumsRect = CGRectMake(0.0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height - self.originY);
    self.albumsVC.view.frame = albumsRect;
    [self.view addSubview:self.albumsVC.view];
    [self.albumsVC loadingAlbumInfos];
}

//============UINavigationControllerDelegate============
- (void)navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[ZPickerController class]]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (void)zAlbumsViewControllerMovingAnimation:(CGFloat)y touched:(BOOL)flag {
    self.albumsBtn.enabled = NO;
    self.albumsBtn.selected = flag;
    [self changeAlbumsBtnTitleFrame];
    
    __weak typeof(self) weak_self = self;
    [UIView animateWithDuration:0.2 animations:^{
        CGRect albumsRect = weak_self.albumsVC.view.frame;
        albumsRect.origin.y = y;
        weak_self.albumsVC.view.frame = albumsRect;
        if (flag) {
            weak_self.arrowDownImgView.transform = CGAffineTransformMakeRotation(M_PI);
        } else {
            weak_self.arrowDownImgView.transform = CGAffineTransformMakeRotation(0.0000000001);
        }
    } completion:^(BOOL finished) {
        weak_self.albumsBtn.enabled = YES;
        if (!flag) {
            [weak_self addGestureRecognizer];
        }
    }];
}

- (IBAction)selectAlbum:(id)sender {
    if (!self.albumsBtn.selected) {
        [self.view removeGestureRecognizer:self.panGestureRecognizer];
        [self zAlbumsViewControllerMovingAnimation:self.originY touched:YES];
    } else {
        [self zAlbumsViewControllerMovingAnimation:self.view.bounds.size.height touched:NO];
    }
}

//============ZAlbumsViewControllerDelegate============
- (void)refresh {
    @synchronized (self) {
        [self.selectedItems removeAllObjects];
        [self.photos removeAllObjects];
    }
    
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        [weak_self fetchAlbum];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [weak_self zAlbumsViewControllerMovingAnimation:weak_self.view.bounds.size.height touched:NO];
            [weak_self.collectionView reloadData];
            [weak_self showOrHiddenToolBar];
            [weak_self scrollToButtom:0.0];
        });
    });
}

- (void)ZAlbumsViewController:(ZAlbumsViewController*)zalbumsVC didSelect:(ZAlbumInfo*)albumInfo {
    if (![self.assetCollection.localIdentifier isEqualToString:albumInfo.assetCollection.localIdentifier]) {
        self.assetCollection = albumInfo.assetCollection;
        self.assets = albumInfo.assets;
        [self refresh];
    } else {
        [self zAlbumsViewControllerMovingAnimation:self.view.bounds.size.height touched:NO];
    }
}

//============UICollectionViewDataSource============
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return (self.photos.count + PickerNumberOfItemsInSection - 1) / PickerNumberOfItemsInSection;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return PickerNumberOfItemsInSection;
}

- (void)showOrHiddenSelectLabelOfCell:(ZPhotoCollectionViewCell*)cell indexPaht:(NSIndexPath*)indexPath {
    if ([self.selectedItems containsObject:indexPath]) {
        NSInteger selectedIndex = [self.selectedItems indexOfObject:indexPath];
        cell.selectedBgView.hidden = NO;
        cell.selectedLabel.hidden = NO;
        cell.selectedLabel.text = [NSString stringWithFormat:@"%d", (int)selectedIndex + 1];
    } else {
        cell.selectedBgView.hidden = YES;
        cell.selectedLabel.hidden = YES;
        cell.selectedLabel.text = nil;
    }
}

- (void)hiddenCell:(ZPhotoCollectionViewCell*)cell {
    cell.photoImgView.image = nil;
    cell.selectedBgView.hidden = YES;
    cell.selectedLabel.hidden = YES;
    cell.selectedLabel.text = nil;
    cell.videoDurationLabel.hidden = YES;
    cell.videoDurationLabel.text = nil;
}

- (__kindof UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    ZPhotoCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:ZPhotoCollectionViewCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.indexPath = indexPath;
    
    NSInteger index = [self indexOfIndexPath:indexPath];
    if (index < self.photos.count) {
        ZImageInfo *imgInfo = [self.photos objectAtIndex:index];
        if (imgInfo.asset != nil) {
            dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_HIGH), ^{
                PHImageRequestOptionsDeliveryMode deliveryMode = (index < self.countOfOneScreen || index >= (self.photos.count - self.countOfOneScreen)) ? PHImageRequestOptionsDeliveryModeOpportunistic : PHImageRequestOptionsDeliveryModeFastFormat;
                [UIImage requestThumbnailsImage:imgInfo.asset deliveryMode:deliveryMode resultHandler:^(UIImage *_Nullable result, NSDictionary *_Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (cell.indexPath == indexPath) {
                            cell.photoImgView.image = result;
                        }
                    });
                }];
            });
            if (!(index < self.countOfOneScreen || index >= (self.photos.count - self.countOfOneScreen))) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)), dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                    if (cell.indexPath == indexPath) {
                        [UIImage requestThumbnailsImage:imgInfo.asset deliveryMode:PHImageRequestOptionsDeliveryModeOpportunistic resultHandler:^(UIImage *_Nullable result, NSDictionary *_Nullable info) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (cell.indexPath == indexPath) {
                                    cell.photoImgView.image = result;
                                }
                            });
                        }];
                    }
                });
            }
            
            [self showOrHiddenSelectLabelOfCell:cell indexPaht:indexPath];
            if (index < self.photoCount) {
                cell.videoDurationLabel.hidden = YES;
                cell.videoDurationLabel.text = nil;
            } else {
                cell.videoDurationLabel.hidden = NO;
                cell.videoDurationLabel.text = [MyTool currentTimeToString:imgInfo.duration];
            }
        } else {
            [self hiddenCell:cell];
        }
    } else {
        [self hiddenCell:cell];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView*)collectionView willDisplayCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
    [self showOrHiddenSelectLabelOfCell:(ZPhotoCollectionViewCell*)cell indexPaht:indexPath];
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    if (kind == UICollectionElementKindSectionFooter) {
        ZPhotoCollectionFooterView *footer = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:ZPhotoCollectionFooterViewIdentifier forIndexPath:indexPath];
        if (indexPath.section == (self.photoCount + PickerNumberOfItemsInSection - 1) / PickerNumberOfItemsInSection - 1) {
            footer.label.frame = footer.bounds;
            footer.label.text = [NSString stringWithFormat:@"%d张照片", (int)self.photoCount];
        } else if (indexPath.section == (self.photos.count + PickerNumberOfItemsInSection - 1) / PickerNumberOfItemsInSection - 1) {
            footer.label.frame = footer.bounds;
            footer.label.text = [NSString stringWithFormat:@"%d部视频", (int)self.videoCount];
        } else {
            footer.label.frame = CGRectZero;
            footer.label.text = nil;
        }
        return footer;
    } else {
        UICollectionReusableView *header = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:ZPhotoCollectionHeaderViewIdentifier forIndexPath:indexPath];
        header.backgroundColor = BgClearColor;
        return header;
    }
}

//============UICollectionViewDelegateFlowLayout============
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, 0.0);
    if (section == 0) {
        size = CGSizeMake(self.collectionView.bounds.size.width, self.flowLayout.sectionInset.left);
    }
    return size;
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, self.flowLayout.minimumInteritemSpacing);
    if (section == (self.photoCount + PickerNumberOfItemsInSection - 1) / PickerNumberOfItemsInSection - 1 || section == (self.photos.count + PickerNumberOfItemsInSection - 1) / PickerNumberOfItemsInSection - 1) {
        size = CGSizeMake(self.collectionView.bounds.size.width, self.collectionFooterHeight);
    }
    return size;
}

//============UICollectionViewDelegate============
- (void)cancelImageRequest:(ZImageInfo*)imgInfo {
    if (imgInfo.requestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:imgInfo.requestID];
        imgInfo.requestID = PHInvalidImageRequestID;
    }
}

- (void)resetZImageInfo:(ZImageInfo*)imgInfo {
    [self cancelImageRequest:imgInfo];
    imgInfo.imgView = nil;
    imgInfo.originImg = nil;
    imgInfo.bitmapImg = nil;
}

- (IBAction)cancelAction:(id)sender {
    @synchronized (self) {
        [self.selectedItems removeAllObjects];
    }
    for (ZImageInfo *imgInfo in self.photos) {
        [self resetZImageInfo:imgInfo];
    }
    
    [self showOrHiddenSelectLabelOfVisibleCells];
}

- (void)dismissPickerController {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissPickerController:)]) {
        [self clearDisplayLink];
        [self.delegate dismissPickerController:self];
    }
}

- (void)uploadImage:(UIImage *)img {
    self.sendBtn.enabled = YES;
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weak_self.delegate && [weak_self.delegate respondsToSelector:@selector(pickerController:uploadImage:)]) {
            [weak_self.delegate pickerController:weak_self uploadImage:img];
            [weak_self dismissPickerController];
        }
    });
}

- (IBAction)sendAction:(id)sender {
    self.sendBtn.enabled = NO;
    NSIndexPath *indexPath = self.selectedItems[0];
    NSInteger index = [self indexOfIndexPath:indexPath];
    ZImageInfo *imgInfo = [self.photos objectAtIndex:index];
    if (imgInfo.originImg == nil) {
        [self requestImage:imgInfo count:1 onQueue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT) flag:YES];
    } else {
        [self uploadImage:imgInfo.originImg];
    }
}

- (void)deleteItemAtIndexPath:(NSIndexPath*)indexPath {
    ZImageInfo *delImgInfo = [self.photos objectAtIndex:[self indexOfIndexPath:indexPath]];
    [self resetZImageInfo:delImgInfo];
    [self.selectedItems removeObject:indexPath];
}

- (void)removeItemAtIndexPath:(NSIndexPath*)indexPath {
    @synchronized (self) {
        [self deleteItemAtIndexPath:indexPath];
    }
}

- (void)requestImage:(ZImageInfo*)imgInfo count:(int)count onQueue:(dispatch_queue_t)queue flag:(BOOL)flag {
    __block int time = count;
    __weak typeof(self) weak_self = self;
    dispatch_async(queue, ^{
        @autoreleasepool {
            imgInfo.requestID = [UIImage requestOriginImageData:imgInfo.asset synchronous:count > 1 ? YES : NO imageHandler:^(UIImage *img, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info) {
                if (img != nil) {
                    imgInfo.originImg = [UIImage decodedScaleImage:img];
                    if (flag) {
                        [weak_self uploadImage:imgInfo.originImg];
                    }
                } else if (flag) {
                    weak_self.sendBtn.enabled = YES;
                    [MyTool presentAlertController:@"下载iCloud的图片失败，请保证网络正常，重新再试" inViewController:weak_self];
                }
            } dataHandler:nil errorHandler:^(NSDictionary *info) {
                [weak_self cancelImageRequest:imgInfo];
                if (++time < 3) {
                    [weak_self requestImage:imgInfo count:time onQueue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT) flag:flag];
                } else if (flag) {
                    weak_self.sendBtn.enabled = YES;
                    [MyTool presentAlertController:@"下载iCloud的图片失败，请保证网络正常，重新再试" inViewController:weak_self];
                }
            }];
        }
    });
}

- (BOOL)addItemAtIndexPath:(NSIndexPath*)indexPath {
    @synchronized (self) {
        NSInteger index = [self indexOfIndexPath:indexPath];
        if (index >= 0 && index < self.photoCount) {
            [self.selectedItems addObject:indexPath];
            ZImageInfo *imgInfo = [self.photos objectAtIndex:index];
            [self requestImage:imgInfo count:1 onQueue:dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT) flag:NO];
            return YES;
        } else {
            return NO;
        }
    }
}

- (void)didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    if ([self.selectedItems containsObject:indexPath]) {
        [self removeItemAtIndexPath:indexPath];
        [self showOrHiddenSelectLabelOfVisibleCells];
    } else {
        if (self.selectedItems.count > 0) {
            [MyTool presentAlertController:@"你只能选择一张图片" inViewController:self];
            return;
        }
        [self addItemAtIndexPath:indexPath];
        [self showOrHiddenSelectLabelOfVisibleCells];
    }
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    NSInteger index = [self indexOfIndexPath:indexPath];
    if (index < self.photoCount) {
        [self didSelectItemAtIndexPath:indexPath];
    }
}

//============ZPhotoCollectionViewCellDelegate============
- (void)ZPhotoCollectionViewCell:(ZPhotoCollectionViewCell*)cell preview:(BOOL)glag {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NSInteger index = [self indexOfIndexPath:indexPath];
    if (index >= 0 && index < self.photoCount) {
        ZPhotoPreViewController *preVC = [[ZPhotoPreViewController alloc] init];
        preVC.delegate = self;
        preVC.title = [NSString stringWithFormat:NSLocalizedString(@"preview", nil), (int)index + 1, (int)self.photoCount];
        preVC.photos = self.photos;
        preVC.curIndex = index;
        preVC.hiddenToolbar = NO;
        preVC.photoCount = self.photoCount;
        
        for (NSIndexPath *selectedIndexPath in self.selectedItems) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:[self indexOfIndexPath:selectedIndexPath]];
            [preVC.selectedItems addObject:indexPath];
        }
        [self.navigationController pushViewController:preVC animated:YES];
    }
}

//============PHPhotoLibraryChangeObserver============
- (void)photoLibraryDidChange:(PHChange*)changeInstance {
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assets];
        if (collectionChanges && [collectionChanges hasIncrementalChanges] && (collectionChanges.insertedObjects.count > 0 || collectionChanges.removedObjects.count > 0)) {
            weak_self.assets = [PHAsset fetchAssetsInAssetCollection:weak_self.assetCollection options:nil];
            [weak_self refresh];
        }
    });
}

//============ZPhotoPreViewControllerDelegate============
- (void)ZPhotoPreViewController:(ZPhotoPreViewController*)preVC select:(NSUInteger)index {
    NSIndexPath *indexPath = [self indexPathForRow:index];
    [self didSelectItemAtIndexPath:indexPath];
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end
