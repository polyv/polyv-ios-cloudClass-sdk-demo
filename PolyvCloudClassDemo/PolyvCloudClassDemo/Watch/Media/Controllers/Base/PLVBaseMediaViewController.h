//
//  PLVBaseMediaViewController.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/21.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PolyvCloudClassSDK/PLVLivePlayerController.h>
#import "PLVPlayerSkinView.h"
#import "PLVPlayerSkinMoreView.h"
#import "PLVPlayerSkinAudioModeView.h"

#define GrayBackgroundColor [UIColor colorWithRed:246.0 / 255.0 green:249.0 / 255.0 blue:250.0 / 255.0 alpha:1.0]
#define BlueBackgroundColor [UIColor colorWithRed:215.0 / 255.0 green:242.0 / 255.0 blue:254.0 / 255.0 alpha:1.0]

/// 错误码
typedef NS_ENUM(NSInteger, PLVBaseMediaErrorCode) {
    /// 自定义跑马灯校验失败
    PLVBaseMediaErrorCodeMarqueeFailed = - 10000,
};

@protocol PLVBaseMediaViewControllerDelegate;
/// 播放器基类 - 继承于 UIViewController（功能：1.清空播放器资源；2.加载皮肤；3.显示或隐藏皮肤；4.退出；5.横竖屏切换）
@interface PLVBaseMediaViewController : UIViewController

/// delegate
@property (nonatomic, weak) id<PLVBaseMediaViewControllerDelegate> delegate;
/// 播放器的皮肤
@property (nonatomic, strong, readonly) PLVPlayerSkinView *skinView;
/// 更多弹窗视图
@property (nonatomic, strong, readonly) PLVPlayerSkinMoreView *moreView;
/// 视频播放器
@property (nonatomic, strong, readonly) PLVPlayerController<PLVPlayerControllerProtocol> *player;
/// 主屏
@property (nonatomic, strong, readonly) UIView *mainView;
/// 页面初始化，记住竖屏时view的Frame，横竖屏切换的动画需要使用
@property (nonatomic, assign) CGRect originFrame;
/// 是否可以旋屏
@property (nonatomic, assign) BOOL canAutorotate;
/// 单击手势
@property (nonatomic,strong) UITapGestureRecognizer *tap;

/// 登录用户名类型跑马灯显示内容
@property (nonatomic, strong) NSString *nickName;

/**
 *  是否启用弹幕模块，默认由后台参数决定，若需由App决定，则直接覆盖此值即可
 *  默认逻辑为：
 *  YES 启用弹幕模块 - 竖屏无弹幕按钮，无弹幕；横屏有弹幕按钮，有弹幕；
 *  NO 不启用弹幕模块 - 横竖屏均无弹幕相关内容；
 */
@property (nonatomic, assign) BOOL enableDanmuModule;

/**
 *  竖屏是否有“弹幕按钮 + 弹幕”；默认NO
 *  仅在 enableDanmuModule 为YES时生效
 *  YES - 竖屏有弹幕按钮，有弹幕；
 *  NO - 竖屏无弹幕按钮，无弹幕；
 */
@property (nonatomic, assign) BOOL showDanmuOnPortrait;

#pragma mark - public

/**
 清除资源
 准备退出时，必须清空播放器资源
 */
- (void)clearResource;

/// 添加单击手势
- (void)addTapGestureRecognizer;

/// 移除单击手势
- (void)removeTapGestureRecognizer;

#pragma mark - protected
/// 加载皮肤
- (void)loadSkinView:(PLVPlayerSkinViewType)skinType;

/// 隐藏皮肤
- (void)skinHiddenAnimaion;

/// 立刻显示返回按钮和全屏按钮
- (void)backBtnShowNow;

/// 显示皮肤
- (void)skinShowAnimaion;

/// 连麦时，由外层调用来改变frame
- (void)changeFrame:(BOOL)fullscreen block:(void (^)(void))block;

#pragma mark - protected - abstract
/// 横竖屏旋转动画开始时，云课堂相关的副窗口需要做动画的逻辑在这里实现（普通直播不需要）
- (void)deviceOrientationBeignAnimation;
/// 横竖屏旋转动画结束时，云课堂相关的副窗口需要做动画的逻辑在这里实现（普通直播不需要）
- (void)deviceOrientationEndAnimation;
/// 横竖屏旋转动画时，云课堂相关的副窗口需要做动画的逻辑在这里实现（普通直播不需要）
- (void)deviceOrientationDidChangeSubAnimation;

/// 获取当前主窗口的Rect（直播需要重写，回放不需要）
- (CGRect)getMainRect;

/// 加载视频播放器
- (void)loadPlayer;

/// 切换主副屏的操作，直播子类 PLVPPTLiveMediaViewController 需要要重写实现，兼容连麦的窗口切换
- (void)switchAction:(BOOL)manualControl;

/// 设置跑马灯
- (void)setupMarquee:(PLVLiveVideoChannel *)channel customNick:(NSString *)customNick;

/// PLVBaseMediaViewController+PPT.m里loadPPT会回调这个函数
- (void)loadPPTEnd;

@end

@protocol PLVBaseMediaViewControllerDelegate <NSObject>

/// 退出，退出前要手动调用clearResource，释放相关资源
- (void)quit:(PLVBaseMediaViewController *)mediaVC error:(NSError *)error;

/// 横竖屏切换前，更新Status Bar的状态
- (void)statusBarAppearanceNeedsUpdate:(PLVBaseMediaViewController *)mediaVC;

@optional
/// 发送一条评论
- (void)sendText:(PLVBaseMediaViewController *)mediaVC text:(NSString *)text;

/// 开启了画笔权限的连麦学员操作绘画后，把生成的笔触数据回调给Socket发送
- (void)sendPaintInfo:(PLVBaseMediaViewController *)mediaVC jsonData:(NSString *)jsonData;

/// 直播流状态改变
- (void)streamStateDidChange:(PLVBaseMediaViewController *)mediaVC streamState:(PLVLiveStreamState)streamState;

/// 播放器播放结束
- (void)player:(PLVPlayerController<PLVPlayerControllerProtocol> *)player playbackDidFinish:(NSDictionary *)userInfo;

/// 播放器加载失败
- (void)player:(PLVPlayerController<PLVPlayerControllerProtocol> *)player loadMainPlayerFailure:(NSString *)message;

/// 播放器Seek完成
- (void)playerDidSeekComplete:(PLVPlayerController<PLVPlayerControllerProtocol> *)player;

/// 播放器精准Seek完成
- (void)playerAccurateSeekComplete:(PLVPlayerController<PLVPlayerControllerProtocol> *)player;

@end
