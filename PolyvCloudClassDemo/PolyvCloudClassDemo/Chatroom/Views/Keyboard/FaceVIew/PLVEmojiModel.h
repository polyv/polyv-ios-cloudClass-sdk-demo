//
//  PLVEmotionModel.h
//  BCKeyBoardDemo
//
//  Created by ftao on 2017/1/13.
//  Copyright © 2017年 io.hzlzh.yunshouyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PLVEmojiModel : NSObject

@property (nonatomic, copy) NSString *text;     // 表情符号
@property (nonatomic, copy) NSString *imagePNG; // png资源名称

// 根据字典生成一个表情模型
+ (instancetype)modelWithDictionary:(NSDictionary *)data;

@end


@interface PLVEmojiModelManager : NSObject

// 存放表情的字典
@property (nonatomic) NSMutableDictionary *emotionDictionary;

// 获取一个单例Emoji管理者
+ (instancetype)sharedManager;

- (UIImage *)imageForEmotionPNGName:(NSString *)pngName;

- (NSMutableAttributedString *)convertTextEmotionToAttachment:(NSString *)text font:(UIFont *)font;

@end
