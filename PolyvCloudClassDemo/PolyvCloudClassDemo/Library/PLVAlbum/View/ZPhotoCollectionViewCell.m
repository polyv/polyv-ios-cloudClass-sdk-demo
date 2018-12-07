//
//  ZPhotoCollectionViewCell.m
//  zPic
//
//  Created by zykhbl on 2017/7/10.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZPhotoCollectionViewCell.h"
#import "MyTool.h"
#import "ZPicDefine.h"

@implementation ZPhotoCollectionViewCell

@synthesize delegate;
@synthesize indexPath;
@synthesize photoImgView;
@synthesize selectedBgView;
@synthesize selectedLabel;
@synthesize videoDurationLabel;
@synthesize longPress;

- (void)preview:(UILongPressGestureRecognizer*)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(ZPhotoCollectionViewCell:preview:)]) {
            [self.delegate ZPhotoCollectionViewCell:self preview:YES];
        }
    }
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = BgClearColor;
        
        self.photoImgView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.photoImgView.backgroundColor = BgClearColor;
        self.photoImgView.contentMode = UIViewContentModeScaleAspectFill;
        self.photoImgView.clipsToBounds = YES;
        [self addSubview:self.photoImgView];
        
        self.selectedBgView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBgView.hidden = YES;
        self.selectedBgView.backgroundColor = [LightGrayColor colorWithAlphaComponent:0.5];;
        [self addSubview:self.selectedBgView];
        
        CGRect selectedRect = CGRectMake((self.bounds.size.width - 40.0) * 0.5, (self.bounds.size.height - 40.0) * 0.5, 40.0, 40.0);
        self.selectedLabel = [MyTool createUILabel:selectedRect fontOfSize:17.0 textColor:NormalColor inView:self];
        self.selectedLabel.hidden = YES;
        
        CGRect videoDurationRect = CGRectMake(self.bounds.size.width - 102.0, self.bounds.size.height - 18.0, 100.0, 16.0);
        self.videoDurationLabel = [MyTool createUILabel:videoDurationRect fontOfSize:15.0 textColor:NormalColor backgroundColor:BgClearColor textAlignment:NSTextAlignmentRight inView:self];
        self.videoDurationLabel.hidden = YES;
        self.videoDurationLabel.clipsToBounds = YES;
        
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(preview:)];
        self.longPress.minimumPressDuration = 0.3;
        [self addGestureRecognizer:self.longPress];
    }
    
    return self;
}

@end
