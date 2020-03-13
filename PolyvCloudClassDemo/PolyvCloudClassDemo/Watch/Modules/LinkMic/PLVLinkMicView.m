//
//  PLVLinkMicView.m
//  PolyvCloudClassSDK
//
//  Created by zykhbl on 2018/10/18.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVLinkMicView.h"
#import "PLVCircleProgressView.h"

@interface PLVLinkMicView ()

@property (nonatomic, assign) BOOL teacher;

@property (nonatomic, strong) UIView *trophyView;
@property (nonatomic, strong) UILabel *trophyNumberLabel;

@end

@implementation PLVLinkMicView

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutSubviews) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews{
    self.imgView.frame = CGRectMake(0, 0, 32.0, 32.0);
    self.imgView.center = self.mainView.center;
    
    self.micPhoneImgView.frame = CGRectMake(CGRectGetWidth(self.mainView.frame) - 5.0 - 16.0, 5.0, 16.0, 16.0);
    self.trophyView.frame = CGRectMake(CGRectGetWidth(self.mainView.frame) - 38.0, CGRectGetHeight(self.mainView.frame) - 20.0, 38.0, 20.0);
}

- (void)loadSubViews:(BOOL)audio teacher:(BOOL)teacher me:(BOOL)me showTrophy:(BOOL)trophy {
    self.teacher = teacher;
    
    self.clipsToBounds = YES;
    
    self.mainView = [[UIView alloc] initWithFrame:self.bounds];
    self.mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mainView.backgroundColor = LinkMicViewBackgroundColor;
    [self addSubview:self.mainView];
    
    self.imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plv_linkMic_camera_background"]];
    self.imgView.clipsToBounds = YES;
    self.imgView.layer.cornerRadius = 16.0;
    [self.mainView addSubview:self.imgView];
    
    self.videoView = [[UIView alloc] initWithFrame:self.mainView.bounds];
    self.videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.mainView addSubview:self.videoView];
    
    self.micPhoneImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plv_linkMic_micphoneOff"]];
    self.micPhoneImgView.hidden = YES;
    [self.mainView addSubview:self.micPhoneImgView];
    
    self.permissionImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plv_linkMic_permission"]];
    self.permissionImgView.backgroundColor = [UIColor colorWithRed:33.0 / 255.0 green:150.0 / 255.0 blue:243.0 / 255.0 alpha:0.8];
    self.permissionImgView.frame = CGRectMake(0.0, self.bounds.size.height - 20.0, 20.0, 20.0);
    self.permissionImgView.contentMode = UIViewContentModeCenter;
    self.permissionImgView.hidden = YES;
    [self addSubview:self.permissionImgView];
    
    CGRect labelRect = CGRectMake(0.0, self.bounds.size.height - 20.0, self.bounds.size.width - 38, 20.0);
    self.nickNameLabel = [[UILabel alloc] initWithFrame:labelRect];
    self.nickNameLabel.backgroundColor = [UIColor colorWithWhite:31.0 / 255.0 alpha:0.8];
    self.nickNameLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12.0];
    self.nickNameLabel.textColor = [UIColor whiteColor];
    self.nickNameLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.nickNameLabel];
    
    CGRect trophyViewRect = CGRectMake(self.bounds.size.width - 38, self.bounds.size.height - 20.0, 38, 20.0);
    self.trophyView = [[UIView alloc] initWithFrame:trophyViewRect];
    self.trophyView.backgroundColor = [UIColor colorWithWhite:31.0 / 255.0 alpha:0.8];
    self.trophyView.hidden = self.teacher ? YES : !trophy;
    [self.mainView addSubview:self.trophyView];
    
    CGRect trophyLabelRect = CGRectMake(15.0, 0, trophyViewRect.size.width - 15, trophyViewRect.size.height);
    self.trophyNumberLabel = [[UILabel alloc] initWithFrame:trophyLabelRect];
    self.trophyNumberLabel.textAlignment = NSTextAlignmentCenter;
    self.trophyNumberLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:11.0];
    self.trophyNumberLabel.textColor = [UIColor colorWithRed:0xFB/255.0 green:0x9B/255.0 blue:0x11/255.0 alpha:1];
    self.trophyNumberLabel.text = @"0";
    [self.trophyView addSubview:self.trophyNumberLabel];
    
    UIImageView *trophyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plv_icon_trophy"]];
    trophyImageView.frame = CGRectMake(3, 3, 12, 14);
    [self.trophyView addSubview:trophyImageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self addGestureRecognizer:tap];
}

- (void)showTrophy:(BOOL)show {
    self.trophyView.hidden = self.teacher ? YES : !show;
}

- (void)updateTrophyNumber:(NSInteger)number {
    if (number < 0) {
        self.trophyNumberLabel.text = @"0";
    } else if (number < 100) {
        self.trophyNumberLabel.text = @(number).stringValue;
    } else {
        self.trophyNumberLabel.text = @"99+";
    }
}

- (void)tapAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchLinkMicViewAction:)]) {
        [self.delegate switchLinkMicViewAction:self];
    }
}

- (void)nickNameLabelSizeThatFitsPermission:(NSString *)permission {
    CGFloat dx = 0.0;
    if (permission.length > 0) {
        dx = 20.0;
    }
    CGRect rect = self.nickNameLabel.frame;
    rect.origin.x = dx;
    CGFloat width = [self.nickNameLabel sizeThatFits:CGSizeMake(self.bounds.size.width - dx, rect.size.height)].width;
    rect.size.width = width + 10.0 <= self.bounds.size.width - dx ? width + 10.0 : width;
    self.nickNameLabel.frame = rect;
}

@end
