//
//  FTPageController.h
//  FTPageController
//
//  Created by ftao on 04/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FTPageControllerDelegate;

/**
 自定义分页控制器
 */
@interface FTPageController : UIViewController

@property (nonatomic, weak) id<FTPageControllerDelegate> delegate;

@property (nonatomic, assign, readonly) CGFloat barHeight;

@property (nonatomic, strong, readonly) NSMutableArray *titles;

@property (nonatomic, strong, readonly) NSMutableArray *controllers;

@property (nonatomic, strong, readonly) UIView *touchLineView;

@property (nonatomic, assign) BOOL circulation;

/**
 设置分页控制器

 @param titles 子控制器标题
 @param controllers 子控制器
 */
- (void)setTitles:(NSArray<NSString *> *)titles
      controllers:(NSArray<UIViewController *> *)controllers
        barHeight:(CGFloat)barHeight
      touchHeight:(CGFloat)touchHeight;

/**
 新增页

 @param title 页标题
 @param controller 页控制器
 */
- (void)addPageWithTitle:(NSString *)title controller:(UIViewController *)controller;

/**
 插入页在指定位置

 @param title 页标题
 @param controller 页控制器
 @param index 位置（大于最大数量时，则插入至最后）
 */
- (void)insertPageWithTitle:(NSString *)title controller:(UIViewController *)controller atIndex:(NSUInteger)index;

/**
 移除页控制器

 @param index 位置
 */
- (void)removePageAtIndex:(NSUInteger)index;

/// 改变大小
- (void)changeFrame;

/// 是否圆角
- (void)cornerRadius:(BOOL)flag;

- (void)scrollEnable:(BOOL)enable;

@end

@protocol FTPageControllerDelegate <NSObject>

- (BOOL)canMoveChatroom:(FTPageController *)pageController;

- (void)moveChatroom:(FTPageController *)pageController toPointY:(CGFloat)pointY;

- (void)moveChatroom:(FTPageController *)pageController;

@end
