//
//  PLVLinkMicPenView.h
//  PolyvCloudClassSDK
//
//  Created by zykhbl on 2019/7/23.
//  Copyright © 2019 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVLinkMicPenViewDelegate;

@interface PLVLinkMicPenView : UIView

@property (nonatomic, weak) id<PLVLinkMicPenViewDelegate> delegate;
@property (nonatomic, assign, readonly) NSInteger penSelectedIndex;
@property (nonatomic, strong, readonly) NSArray *colorStrArray;

- (void)addSubViews;

- (void)layout:(BOOL)fullscreen;

- (void)chooseRedPen;

@end

@protocol PLVLinkMicPenViewDelegate <NSObject>

- (void)penViewAction:(PLVLinkMicPenView *)penView;

@end
