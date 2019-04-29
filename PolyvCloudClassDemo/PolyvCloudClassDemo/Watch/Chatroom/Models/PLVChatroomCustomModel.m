//
//  PLVChatroomCustomModel.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/1/18.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatroomCustomModel.h"

@implementation PLVChatroomCustomModel
@synthesize type = _type;
@synthesize event = _event;
@synthesize message = _message;
@synthesize defined = _defined;
@synthesize tip = _tip;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _type = PLVChatroomModelTypeCustom;
    }
    return self;
}

+ (instancetype)modelWithCustomMessage:(NSDictionary *)message {
    if (message && [message isKindOfClass:[NSDictionary class]]) {
        PLVChatroomCustomModel *model = [[self alloc] init];
        model->_message = message;
        model->_event = message[@"EVENT"];
        model->_tip = message[@"tip"];
        if (![model isMemberOfClass:[PLVChatroomCustomModel class]]) {
            model->_defined = YES;
        }
        if (message[@"data"] && [message[@"data"] isKindOfClass:[NSDictionary class]]) {
            return model;
        }
        return nil;
    }
    return nil;
}

@end
