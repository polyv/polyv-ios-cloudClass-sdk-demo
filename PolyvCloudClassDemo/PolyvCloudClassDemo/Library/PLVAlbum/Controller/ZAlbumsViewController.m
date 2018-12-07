//
//  ZAlbumsViewController.m
//  zPic
//
//  Created by zykhbl on 2017/7/22.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZAlbumsViewController.h"
#import "ZAlbumTableViewCell.h"
#import "SDWebImageDecoder.h"

@implementation ZAlbumsViewController

@synthesize delegate;
@synthesize pcikerModer;
@synthesize albums;
@synthesize tableView;

- (void)requestLastImage:(PHAsset*)asset forAlbumInfo:(ZAlbumInfo*)albumInfo {
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        [UIImage requestThumbnailsImage:asset deliveryMode:PHImageRequestOptionsDeliveryModeOpportunistic resultHandler:^(UIImage *_Nullable result, NSDictionary *_Nullable info) {
            albumInfo.albumImg = [UIImage decodedOriginImage:result];
            if (weak_self.tableView != nil) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [weak_self.tableView reloadData];
                });
            }
        }];
    });
}

- (void)foreachAlbums:(PHFetchResult<PHAssetCollection*>*)albumResult {
    for (NSUInteger i = 0; i < albumResult.count; i++) {
        PHAssetCollection *assetCollection = [albumResult objectAtIndex:i];
        if (assetCollection.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden) {
            PHFetchResult<PHAsset*> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
            if (assets.count > 0) {
                NSUInteger photoCount = 0;
                NSUInteger videoCount = 0;
                ZAlbumInfo *albumInfo = nil;
                
                for (NSInteger i = assets.count - 1; i >= 0; i--) {
                    PHAsset *asset = [assets objectAtIndex:i];
                    if (asset.mediaType == PHAssetMediaTypeImage) {
                        photoCount++;
                        if (albumInfo == nil) {
                            albumInfo = [[ZAlbumInfo alloc] init];
                            [self requestLastImage:asset forAlbumInfo:albumInfo];
                        }
                    } else if (self.pcikerModer == PickerModerOfVideo && asset.mediaType == PHAssetMediaTypeVideo) {
                        videoCount++;
                        if (albumInfo == nil) {
                            albumInfo = [[ZAlbumInfo alloc] init];
                            [self requestLastImage:asset forAlbumInfo:albumInfo];
                        }
                    }
                }
                
                if (albumInfo != nil) {
                    albumInfo.assetCollection = assetCollection;
                    albumInfo.assets = assets;
                    albumInfo.photoCount = photoCount;
                    albumInfo.videoCount = videoCount;
                    [self.albums addObject:albumInfo];
                }
            }
        }
    }
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.albums = [[NSMutableArray alloc] initWithCapacity:20];
    }
    
    return self;
}

- (void)loadingAlbumInfos {
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        PHFetchResult<PHAssetCollection*> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        [weak_self foreachAlbums:smartAlbums];
        
        PHFetchResult<PHAssetCollection*> *albumResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        [weak_self foreachAlbums:albumResult];
        
        [weak_self.albums sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            ZAlbumInfo *albumInfo1 = (ZAlbumInfo*)obj1;
            ZAlbumInfo *albumInfo2 = (ZAlbumInfo*)obj2;
            if (albumInfo1.photoCount + albumInfo1.videoCount < albumInfo2.photoCount + albumInfo2.videoCount) {
                return YES;
            }
            return NO;
        }];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.tableView == nil) {
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.backgroundColor= ViewBackgroupColor;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        [self.view addSubview:self.tableView];
    }
}

//=============UITableViewDataSource=============
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albums.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *ZAlbumTableViewCellIdentifier = @"ZAlbumTableViewCell";
    ZAlbumTableViewCell *cell = (ZAlbumTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:ZAlbumTableViewCellIdentifier];
    
    if (cell == nil) {
        cell = [[ZAlbumTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZAlbumTableViewCellIdentifier];
        CGRect rect = self.view.bounds;
        rect.size.height = 70.0;
        cell.frame = rect;
        [cell setup];
    }
    
    ZAlbumInfo *albumInfo = [self.albums objectAtIndex:indexPath.row];
    cell.imgView.image = albumInfo.albumImg;
    cell.nameLabel.text = albumInfo.assetCollection.localizedTitle;
    if (albumInfo.photoCount > 0 && albumInfo.videoCount > 0) {
        cell.countLabel.text = [NSString stringWithFormat:@"照片:%d 视频:%d", (int)albumInfo.photoCount, (int)albumInfo.videoCount];
    } else if (albumInfo.photoCount > 0) {
        cell.countLabel.text = [NSString stringWithFormat:@"照片:%d", (int)albumInfo.photoCount];
    } else if (albumInfo.videoCount > 0) {
        cell.countLabel.text = [NSString stringWithFormat:@"视频:%d", (int)albumInfo.videoCount];
    } else {
        cell.countLabel.text = @"";
    }
    
    return cell;
}

//=============UITableViewDelegate=============
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 70.0;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(ZAlbumsViewController:didSelect:)]) {
        ZAlbumInfo *albumInfo = [self.albums objectAtIndex:indexPath.row];
        [self.delegate ZAlbumsViewController:self didSelect:albumInfo];
    }
    
    ZAlbumTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        cell.selected = NO;
    });
}

@end
