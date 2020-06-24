//
//  ZPreCollectionViewCell.m
//  zPic
//
//  Created by zykhbl on 2017/7/19.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZPreCollectionViewCell.h"
#import "ZPicDefine.h"

@implementation ZPreCollectionViewCell

@synthesize delegate;
@synthesize indexPath;
@synthesize scrollView;
@synthesize photoImgView;
@synthesize doubleTapGesture;
@synthesize longPress;
@synthesize chaged;
@synthesize baseScale;
@synthesize exifStr;
@synthesize textAlignment;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = BgClearColor;
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.backgroundColor = BgClearColor;
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollView.delegate = self;
        self.scrollView.minimumZoomScale = 1.0;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.scrollView];
        
        self.photoImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.photoImgView.clipsToBounds = YES;
        self.photoImgView.backgroundColor = BgClearColor;
        [self.scrollView addSubview:self.photoImgView];
        
        self.doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        self.doubleTapGesture.numberOfTapsRequired = 2;
        [self.scrollView addGestureRecognizer:self.doubleTapGesture];
        
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showExif:)];
        self.longPress.minimumPressDuration = 0.3;
        [self.scrollView addGestureRecognizer:self.longPress];
    }
    
    return self;
}

- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGRect zoomRect = self.scrollView.bounds;
    zoomRect.size.height /= scale;
    zoomRect.size.width /= scale;
    zoomRect.origin.x = center.x - zoomRect.size.width * 0.5;
    zoomRect.origin.y = center.y - zoomRect.size.height * 0.5;
    
    return zoomRect;
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecognizer {
    CGFloat scale = 1.0;
    if (self.scrollView.zoomScale == 1.0) {
        scale = self.baseScale;
    }
    
    CGPoint p = [gestureRecognizer locationInView:self.scrollView];
    p = CGPointMake(p.x / self.scrollView.zoomScale, p.y / self.scrollView.zoomScale);
    CGRect zoomRect = [self zoomRectForScale:scale withCenter:p];
    
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)showExif:(UILongPressGestureRecognizer*)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan && self.delegate && [self.delegate respondsToSelector:@selector(ZPreCollectionViewCell:showExif:)]) {
        [self.delegate ZPreCollectionViewCell:self showExif:YES];
    }
}

//============UIScrollViewDelegate============
- (UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView {
    return self.photoImgView;
}

- (void)makePhotoImgViewCenter {
    CGRect photoRect = self.photoImgView.frame;
    if (photoRect.size.width < self.scrollView.bounds.size.width) {
        photoRect.origin.x = (self.scrollView.bounds.size.width - photoRect.size.width) * 0.5;
    } else {
        photoRect.origin.x = 0.0;
    }
    if (photoRect.size.height < self.scrollView.bounds.size.height) {
        photoRect.origin.y = (self.scrollView.bounds.size.height - photoRect.size.height) * 0.5;
    } else {
        photoRect.origin.y = 0.0;
    }
    self.photoImgView.frame = photoRect;
}

- (void)scrollViewDidZoom:(UIScrollView*)scrollView {
    __weak typeof(self) weak_self = self;
    [UIView animateWithDuration:0.2 animations:^ {
        [weak_self makePhotoImgViewCenter];
    }];
}

- (void)scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(CGFloat)scale {
    if (!self.chaged && self.delegate && [self.delegate respondsToSelector:@selector(ZPreCollectionViewCell:scrollViewDidEndZooming:)]) {
        [self.delegate ZPreCollectionViewCell:self scrollViewDidEndZooming:YES];
        self.chaged = YES;
    }
}

@end
