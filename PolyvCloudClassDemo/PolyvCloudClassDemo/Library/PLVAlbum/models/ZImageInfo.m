//
//  ZImageInfo.m
//  zPic
//
//  Created by zykhbl on 2017/7/11.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZImageInfo.h"

@implementation ZImageInfo

@synthesize requestID;
@synthesize asset;
@synthesize pixelSize;
@synthesize imgView;
@synthesize originImg;
@synthesize bitmapImg;

@synthesize video;
@synthesize duration;
@synthesize frameTimeStamp;
@synthesize frameTime;

- (id)init {
    self = [super init];
    if (self) {
        self.requestID = PHInvalidImageRequestID;
    }
    return self;
}

@end
