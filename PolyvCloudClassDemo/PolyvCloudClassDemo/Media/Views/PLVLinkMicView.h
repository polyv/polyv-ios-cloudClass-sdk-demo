//
//  PLVLinkMicView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/10/18.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLVLinkMicView : UIView

@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UIButton *switchCameraBtn;

- (void)loadSubViews:(BOOL)audio me:(BOOL)me;

@end
