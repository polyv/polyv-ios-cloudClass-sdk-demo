//
//  PLVRewardGoodsModel.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/9.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVRewardGoodsModel.h"

#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

/// 打赏奖品数据模型
@implementation PLVRewardGoodsModel

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary{
    if (dictionary && [dictionary isKindOfClass:NSDictionary.class] && dictionary.count > 0) {
        PLVRewardGoodsModel * model = [[PLVRewardGoodsModel alloc]init];
        model.goodName = [NSString stringWithFormat:@"%@",dictionary[@"goodName"]];
        model.goodImgURL = [NSString stringWithFormat:@"%@",dictionary[@"goodImg"]];
        
        model.goodPrice = [[NSString stringWithFormat:@"%@",dictionary[@"goodPrice"]] floatValue];
        model.goodEnabled = [(NSNumber *)dictionary[@"goodEnabled"] boolValue];
        return model;
    }else{
        return nil;
    }
}

+ (instancetype)modelWithSocketObject:(PLVSocketChatRoomObject *)object{
    if (object && [object isKindOfClass:PLVSocketChatRoomObject.class]) {
        PLVRewardGoodsModel * model = [[PLVRewardGoodsModel alloc]init];
        
        NSDictionary * contentDict = object.jsonDict[@"content"];
        if ([contentDict isKindOfClass:NSDictionary.class]) {
            NSString * gimg = [NSString stringWithFormat:@"%@",contentDict[@"gimg"]];
            NSString * rewardContent = [NSString stringWithFormat:@"%@",contentDict[@"rewardContent"]];
            
            model.goodName = rewardContent;
            model.goodImgURL = gimg;
            return model;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

- (NSString *)goodImgFullURL{
    NSString * fullURL = self.goodImgURL;
    if ([fullURL hasPrefix:@"//"]) { fullURL = [@"https:" stringByAppendingString:fullURL]; }
    return fullURL;
}

@end
