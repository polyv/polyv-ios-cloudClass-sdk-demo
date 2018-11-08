/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import <UIKit/UIKit.h>
#import "PLVEmojiModel.h"

@protocol FacialViewDelegate

@optional

- (void)selectedFacialView:(PLVEmojiModel*)emojiModel;

- (void)deleteEmoji;

- (void)send;

@end


@interface FacialView : UIView {
	NSArray *_faces;
}

@property(nonatomic) id<FacialViewDelegate> delegate;

@property(strong, nonatomic, readonly) NSArray *faces;

-(void)loadFacialView:(int)page size:(CGSize)size;

- (void)sendBtnEnable:(BOOL)enable;

@end
