//
//  PLVTextInputView.h
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/9/7.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TEXT_MAX_COUNT 200

/// 键盘类型
typedef NS_ENUM(NSInteger, PLVTextInputViewType) {
    /// 普通公聊类型
    PLVTextInputViewTypeNormalPublic     = 1,
    /// 云课堂公聊类型
    PLVTextInputViewTypeCloudClassPublic = 2,
    /// 私聊/咨询提问类型
    PLVTextInputViewTypePrivate          = 3
};

/// 键盘状态
typedef NS_ENUM(NSInteger, PLVTextInputViewState) {
    /// 正常状态
    PLVTextInputViewStateNormal,
    /// 系统键盘
    PLVTextInputViewStateSystem,
    /// 表情键盘
    PLVTextInputViewStateEmoji,
    /// 显示更多
    PLVTextInputViewStateMore,
};

@protocol PLVTextInputViewDelegate;
@interface PLVTextInputView : UIView

@property (nonatomic, weak) id<PLVTextInputViewDelegate> delegate;

/// 键盘状态
@property (nonatomic, assign) PLVTextInputViewState inputState;

/// 只看讲师模式禁止其他按钮交互
@property (nonatomic, assign) BOOL disableOtherButtonsInTeacherMode;

/**
 加载视图

 @param type 键盘模式
 @param enableMore 显示更多按钮
 */
- (void)loadViews:(PLVTextInputViewType)type enableMore:(BOOL)enableMore;

/**
 隐藏键盘
 */
- (void)tapAction;

/**
 释放资源，退出前调用
 */
- (void)clearResource;

@end

@protocol PLVTextInputViewDelegate <NSObject>

@optional
- (BOOL)textInputViewShouldBeginEditing:(PLVTextInputView *)inputView;

- (void)textInputView:(PLVTextInputView *)inputView followKeyboardAnimation:(BOOL)flag;
- (void)textInputView:(PLVTextInputView *)inputView didSendText:(NSString *)text;
- (void)sendFlower:(PLVTextInputView *)inputView;
- (void)textInputView:(PLVTextInputView *)inputView onlyTeacher:(BOOL)on;
- (void)openAlbum:(PLVTextInputView *)inputView;
- (void)shoot:(PLVTextInputView *)inputView;

@end
