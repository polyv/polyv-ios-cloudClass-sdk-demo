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

#import "PLVFaceView.h"

@interface PLVFaceView ()
{
    PLVFacialView *_facialView;
}

@end

@implementation PLVFaceView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _facialView = [[PLVFacialView alloc] initWithFrame: CGRectMake(5, 5, frame.size.width - 10, 190.0)];
        [_facialView loadFacialView:1 size:CGSizeMake(30, 30)];
        _facialView.delegate = self;
        [self addSubview:_facialView];
    }
    return self;
}

- (void)sendBtnEnable:(BOOL)enable {
    [_facialView sendBtnEnable:enable];
}

#pragma mark - FacialViewDelegate

- (void)selectedFacialView:(PLVEmojiModel *)emojiModel{
    if (_delegate) {
        [_delegate selectedEmoji:emojiModel];
    }
}

- (void)deleteEmoji {
    if (_delegate) {
        [_delegate deleteEvent];
    }
}

- (void)send {
    if (self.delegate) {
        [self.delegate sendEvent];
    }
}

#pragma mark - public

- (BOOL)stringIsFace:(NSString *)string
{
    if ([_facialView.faces containsObject:string]) {
        return YES;
    }
    
    return NO;
}

@end
