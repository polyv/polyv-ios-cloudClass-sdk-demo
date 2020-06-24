//
//  PLVPlayerInputView.h
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/6/10.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVPlayerInputViewDelegate;

/// 播放器上的输入控件
@interface PLVPlayerInputView : UIView

/// delegate
@property (nonatomic, weak) id<PLVPlayerInputViewDelegate> delegate;

/// 显示
- (void)show;
/// 隐藏
- (void)hide;

@end

@protocol PLVPlayerInputViewDelegate <NSObject>

@optional

/// 点击发送
- (void)playerInputView:(PLVPlayerInputView *)inputView didSendText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
