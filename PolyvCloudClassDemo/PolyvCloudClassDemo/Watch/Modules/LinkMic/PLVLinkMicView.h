//
//  PLVLinkMicView.h
//  PolyvCloudClassSDK
//
//  Created by zykhbl on 2018/10/18.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LinkMicViewBackgroundColor [UIColor colorWithWhite:66.0 / 255.0 alpha:1.0]

typedef NS_ENUM(NSInteger, PLVLinkMicType) {
    PLVLinkMicTypeLive       = 1,/// 旧普通直播连麦
    PLVLinkMicTypeNormalLive = 2,/// 新普通直播连麦
    PLVLinkMicTypeCloudClass = 3 /// 云课堂连麦
};

@protocol PLVLinkMicViewDelegate;

/// 连麦窗口
@interface PLVLinkMicView : UIView

@property (nonatomic, weak) id<PLVLinkMicViewDelegate> delegate;
/// 连麦类型（普通直播连麦，或云课堂连麦）
@property (nonatomic, assign) PLVLinkMicType linkMicType;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, assign) BOOL viewer;
@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIImageView *micPhoneImgView;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, assign) BOOL avatarUploaded;
@property (nonatomic, strong) UIImageView *permissionImgView;
@property (nonatomic, strong) UILabel *nickNameLabel;
/// 连麦状态下，如果把 PPT 从主屏位置切换到副屏位置，这里要记住该连麦窗口是否在主屏（有多个窗口，有且最多只有一个窗口的 onBigView 值为YES）
@property (nonatomic, assign) BOOL onBigView;

/// 加载子窗口
- (void)loadSubViews:(BOOL)audio teacher:(BOOL)teacher me:(BOOL)me showTrophy:(BOOL)trophy;
/// 显示奖杯数目
- (void)showTrophy:(BOOL)show;
/// 更新奖杯数目
- (void)updateTrophyNumber:(NSInteger)number;
/// 刷新昵称文本框布局
- (void)nickNameLabelSizeThatFitsPermission:(NSString *)permission;

@end

@protocol PLVLinkMicViewDelegate <NSObject>

- (void)switchLinkMicViewAction:(PLVLinkMicView *)linkMicView;

@end
