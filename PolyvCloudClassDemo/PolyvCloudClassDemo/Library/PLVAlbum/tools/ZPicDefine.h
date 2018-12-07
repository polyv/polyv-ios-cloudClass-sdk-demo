//
//  ZPicDefine.h
//  zPic
//
//  Created by zykhbl on 2017/8/2.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#ifndef ZPicDefine_h
#define ZPicDefine_h

#define NormalColor             [UIColor whiteColor]
#define SelectedColor           [UIColor colorWithRed:244.0/255.0 green:197.0/255.0 blue:96.0/255.0 alpha:1.0]
#define LightGrayColor          [UIColor lightGrayColor]
#define WhiteColor              [UIColor whiteColor]
#define BlackColor              [UIColor blackColor]
#define BgClearColor            [UIColor clearColor]

#define LineAndButtonColor      [UIColor colorWithRed:244.0/255.0 green:197.0/255.0 blue:96.0/255.0 alpha:1.0]
#define LineAndButtonCGColor    [UIColor colorWithRed:244.0/255.0 green:197.0/255.0 blue:96.0/255.0 alpha:1.0].CGColor
#define WrongLineAndButtonColor [UIColor colorWithRed:232.0/255.0 green:80.0/255.0 blue:98.0/255.0 alpha:1.0]

#define ThumbnailsSize          CGSizeMake(128.0, 128.0)
#define ToolbarBtnWidth         50.0
#define SToolbarHeight          50.0
#define LimitWidth              10000

#define CutLineWidth            2.0
#define CutBtnWidth             20.0
#define CutBtnHeight            50.0

#define BackSpaceWidth          60.0
#define SelectedWidth           32.0

#define LimitCount              5

typedef NS_ENUM(NSInteger, PickerModer) {
    PickerModerOfNormal = 0,
    PickerModerOfVideo  = 1
};

extern BOOL isPhone;
extern CGFloat ToolbarHeight;
extern NSInteger PickerNumberOfItemsInSection;
extern CGFloat LimitMemeory;
extern CGFloat MemeoryLarge;

extern UIColor *NavBackgroupColor;
extern UIColor *ViewBackgroupColor;

#endif /* ZPicDefine_h */
