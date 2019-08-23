//
//  PLVPlayerSkinMoreView.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/6/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 更多弹窗视图类型
typedef NS_ENUM(NSInteger, PLVPlayerSkinMoreViewType) {
    /// 普通直播
    PLVPlayerSkinMoreViewTypeNormalLive       = 1,
    /// 云课堂直播
    PLVPlayerSkinMoreViewTypeCloudClassLive   = 2,
    /// 普通直播回放
    PLVPlayerSkinMoreViewTypeNormalVod        = 3,
    /// 云课堂直播回放
    PLVPlayerSkinMoreViewTypeCloudClassVod    = 4
};

@protocol PLVPlayerSkinMoreViewDelegate;

/// 更多弹窗视图
@interface PLVPlayerSkinMoreView : UIView

/// delegate
@property (nonatomic, weak) id<PLVPlayerSkinMoreViewDelegate> delegate;
/// 弹窗类型
@property (nonatomic, assign) PLVPlayerSkinMoreViewType type;
/// 多线路
@property (nonatomic, assign) NSUInteger lines;
/// 当前线路
@property (nonatomic, assign) NSInteger curLine;
/// 码率列表
@property (nonatomic, strong) NSMutableArray<NSString *> *codeRateItems;
/// 当前码率
@property (nonatomic, copy) NSString * curCodeRate;

/// 显示
- (void)show;
/// 隐藏
- (void)hide;

/// 显示/隐藏音频模式的切换按钮
- (void)showAudioModeBtn:(BOOL)show;
/// 修改音频模式按钮的选中状态
- (void)modifyModeBtnSelected:(BOOL)selected;

@end

@protocol PLVPlayerSkinMoreViewDelegate <NSObject>

@optional

/// 切换为音频模式
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView switchAudioMode:(BOOL)switchAudioMode;

/// 切换线路
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView line:(NSUInteger)line;

/// 切换码率
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView codeRate:(NSString *)codeRate;

/// 切换速率
- (void)playerSkinMoreView:(PLVPlayerSkinMoreView *)skinMoreView speed:(CGFloat)speed;

@end

NS_ASSUME_NONNULL_END
