//
//  Emoji.m
//  Emoji
//
//  Created by Aliksandr Andrashuk on 26.10.12.
//  Copyright (c) 2012 Aliksandr Andrashuk. All rights reserved.
//

#import "PLVEmoji.h"
#import <UIKit/UIKit.h>



@interface PLVEmoji ()

// 存放表情的字典
//@property (nonatomic) NSMutableDictionary *emotionDictionary;
//
//// 存放表情模型的数组
//@property (nonatomic) NSMutableArray<PLVEmojiModel *> *allEmojiModels;


@end

@implementation PLVEmoji


//+ (NSString *)emojiWithCode:(int)code {
//    int sym = EMOJI_CODE_TO_SYMBOL(code);
//    return [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
//}

+ (PLVEmoji *)sharedEmoji {
//+ (NSArray *)allImageEmoji {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Emotions" ofType:@"plist"];
    NSArray<NSDictionary *> *groups = [NSArray arrayWithContentsOfFile:path];               // 获取到plist中的文件内容

    PLVEmoji *emoji = [PLVEmoji new];
    emoji.emotionDictionary = [NSMutableDictionary dictionary];
    emoji.allEmojiModels = [NSMutableArray new];
    
    for (NSDictionary *group in groups) {
        if ([group[@"type"] isEqualToString:@"emoji"]) {
            
            NSArray<NSDictionary *> *items = group[@"items"];
            for (NSDictionary *item in items) {
                PLVEmojiModel *model = [PLVEmojiModel modelWithDictionary:item];
                // 两种方式保存数据
                [emoji.allEmojiModels addObject:model];
                emoji.emotionDictionary[model.text] = model.imagePNG;
            }
        }
    }
    
    //return emoji.allEmojiModels;
    return emoji;
}


@end
