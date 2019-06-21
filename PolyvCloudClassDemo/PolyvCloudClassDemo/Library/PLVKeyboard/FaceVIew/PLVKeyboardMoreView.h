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

@end

@protocol PLVKeyboardMoreViewDelegate <NSObject>

- (void)openAlbum:(PLVKeyboardMoreView *)moreView;
- (void)shoot:(PLVKeyboardMoreView *)moreView;
- (void)readBulletin:(PLVKeyboardMoreView *)moreView;

@end
