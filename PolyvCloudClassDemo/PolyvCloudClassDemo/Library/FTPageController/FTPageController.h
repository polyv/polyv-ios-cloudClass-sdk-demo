//
//  FTPageController.h
//  FTPageController
//
//  Created by ftao on 04/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PageControllerTopBarHeight 44.0

/**
 自定义分页控制器
 */
@interface FTPageController : UIViewController

@property (nonatomic, strong, readonly) NSMutableArray *titles;

@property (nonatomic, strong, readonly) NSMutableArray *controllers;

@property (nonatomic, assign) BOOL circulation;

/**
 通过标题及其控制器初始化分页控制器

 @param titles 子控制器标题
 @param controllers 子控制器
 @return 分页控制
 */
- (instancetype)initWithTitles:(NSArray<NSString *> *)titles controllers:(NSArray<UIViewController *> *)controllers;

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

- (void)changeFrame;

@end
