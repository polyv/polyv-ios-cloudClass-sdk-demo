//
//  ZPhotoCollectionFooterView.m
//  zPic
//
//  Created by zykhbl on 2017/7/11.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZPhotoCollectionFooterView.h"
#import "MyTool.h"
#import "ZPicDefine.h"

@implementation ZPhotoCollectionFooterView

@synthesize label;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = BgClearColor;
        
        self.label = [MyTool createUILabel:CGRectZero fontOfSize:15.0 textColor:LightGrayColor backgroundColor:BgClearColor textAlignment:NSTextAlignmentCenter inView:self];
    }
    
    return self;
}

@end
