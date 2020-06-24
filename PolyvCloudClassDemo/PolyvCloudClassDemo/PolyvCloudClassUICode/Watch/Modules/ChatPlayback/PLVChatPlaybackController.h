//
//  PLVChatPlaybackController.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/30.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVTableViewController.h"

@class PLVChatPlaybackController;
@protocol PLVChatPlaybackControllerDelegate <NSObject>

/// 获取播放器时间
- (NSTimeInterval)currentPlaybackTime;

/// 获取视频总时长
- (NSTimeInterval)videoDurationTime;

/// 输入键盘弹出弹入回调，由外层实现相关逻辑
- (void)playbackController:(PLVChatPlaybackController *)playbackController followKeyboardAnimation:(BOOL)flag;

@end

@interface PLVChatPlaybackController : PLVTableViewController

@property (nonatomic, weak) id<PLVChatPlaybackControllerDelegate> delegate;

@property (nonatomic, strong) NSMutableArray<PLVCellModel *> *playbackQueue;

@property (nonatomic, strong, readonly) NSString *vid;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, strong) NSString *sessionId;

@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) BOOL loadingRequest;
@property (nonatomic, assign) BOOL isSeekRequest;

- (instancetype)initChatPlaybackControllerWithVid:(NSString *)vid frame:(CGRect)frame;

+ (instancetype)chatPlaybackControllerWithVid:(NSString *)vid frame:(CGRect)frame;

- (void)loadSubViews:(UIView *)tapSuperView;

#pragma mark -

- (void)scrollToTime:(NSTimeInterval)time;

@end

@class PLVChatModel;
@interface PLVChatPlaybackController (DataProcessing)

/**
 配置提交聊天内容的用户信息

 @param nick 用户昵称，有默认值
 @param pic 用户头像，有默认值
 @param userId 用户Id，有默认值
 */
- (void)configUserInfoWithNick:(NSString *)nick pic:(NSString *)pic userId:(NSString *)userId;

- (void)seekToTime:(NSTimeInterval)newTime;

- (void)prepareToLoad:(NSTimeInterval)time;

- (void)sendMesage:(id)msg time:(NSTimeInterval)time msgType:(NSString *)msgType;

- (void)addSpeakModel:(NSString *)message time:(NSTimeInterval)time;

- (PLVChatModel *)addImageModel:(UIImage *)image imgId:(NSString *)imgId time:(NSTimeInterval)time;

@end
