//
//  PLVKeyboardMoreView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/11/29.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVKeyboardMoreViewDelegate;

@interface PLVKeyboardMoreView : UIView

@property (nonatomic, weak) id<PLVKeyboardMoreViewDelegate> delegate;

/// 是否允许发送图片 默认NO；YES-显示发图按钮，NO-隐藏发图按钮
@property (nonatomic, assign) BOOL viewerSendImgEnabled;

@end

@protocol PLVKeyboardMoreViewDelegate <NSObject>

- (void)openAlbum:(PLVKeyboardMoreView *)moreView;
- (void)shoot:(PLVKeyboardMoreView *)moreView;
- (void)readBulletin:(PLVKeyboardMoreView *)moreView;

@end
