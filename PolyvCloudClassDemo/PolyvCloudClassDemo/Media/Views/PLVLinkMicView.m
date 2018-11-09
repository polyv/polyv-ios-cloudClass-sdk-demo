//
//  PLVLinkMicView.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/10/18.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVLinkMicView.h"
#import <Masonry/Masonry.h>

@implementation PLVLinkMicView

- (void)hiddenSwitchCameraBtn {
    self.switchCameraBtn.hidden = YES;
}

- (void)hiddenSwitchCameraBtnAfterDelay {
    [self performSelector:@selector(hiddenSwitchCameraBtn) withObject:nil afterDelay:5.0];
}

- (void)showSwitchCameraBtn {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.switchCameraBtn.hidden = NO;
    [self hiddenSwitchCameraBtnAfterDelay];
}

- (void)loadSubViews:(BOOL)audio me:(BOOL)me {
    self.backgroundColor = [UIColor whiteColor];
    self.clipsToBounds = YES;
    
    self.mainView = [[UIView alloc] initWithFrame:self.bounds];
    self.mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.mainView];
    
    UIImage *img = audio ? [UIImage imageNamed:@"plv_skin_player_background"] : [UIImage imageNamed:@"plv_skin_player_background"];
    self.imgView = [[UIImageView alloc] initWithImage:img];
    [self.mainView addSubview:self.imgView];
    __weak typeof(self) weakSelf = self;
    [self.imgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.mainView);
        make.size.mas_equalTo(CGSizeMake(60.0, 67.0));
    }];
    
    self.videoView = [[UIView alloc] initWithFrame:self.mainView.bounds];
    self.videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.mainView addSubview:self.videoView];
    
    if (!audio && me) {
        self.switchCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.switchCameraBtn.frame = CGRectMake(self.bounds.size.width - 44.0, 0.0, 44.0, 44.0);
        [self.switchCameraBtn setImage:[UIImage imageNamed:@"plv_skin_switchCamera"] forState:UIControlStateNormal];
        [self addSubview:self.switchCameraBtn];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSwitchCameraBtn)];
        [self addGestureRecognizer:tapGestureRecognizer];
        
        [self showSwitchCameraBtn];
    }
    
    CGRect labelRect = CGRectMake(5.0, self.bounds.size.height - 30.0, self.bounds.size.width - 10.0, 30.0);
    self.nickNameLabel = [[UILabel alloc] initWithFrame:labelRect];
    self.nickNameLabel.backgroundColor = [UIColor clearColor];
    self.nickNameLabel.font = [UIFont boldSystemFontOfSize:10.0];
    self.nickNameLabel.textColor = [UIColor whiteColor];
    self.nickNameLabel.textAlignment = NSTextAlignmentLeft;
    self.nickNameLabel.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5].CGColor;
    self.nickNameLabel.layer.shadowOffset = CGSizeMake(-0.2, -0.2);
    self.nickNameLabel.layer.shadowRadius = 0.2;
    self.nickNameLabel.layer.shadowOpacity = 1.0;
    [self addSubview:self.nickNameLabel];
}

@end
