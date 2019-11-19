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

// emoji 符号（字符串）
@property (nonatomic, copy) NSString *text;

// emoji 图片名称
@property (nonatomic, copy) NSString *imagePNG;

/**
 生成一个表情模型
 */
+ (instancetype)modelWithDictionary:(NSDictionary *)data;

@end


@interface PLVEmojiManager : NSObject

/// 表情字典数据
@property (nonatomic) NSMutableDictionary *emotionDictionary;

/// 表情模型数据
@property (nonatomic) NSMutableArray<PLVEmojiModel *> *allEmojiModels;

/**
 获取单例emoji管理者
 */
+ (instancetype)sharedManager;

/**
 获取emoji名称的图片

 @param pngName emoji名称
 @return emoji图片
 */
- (UIImage *)imageForEmotionPNGName:(NSString *)pngName;

/**
 将表情文本转为属性字符串

 @param text 表情文本
 @param font 文本d大小
 @return 属性字符串
 */
- (NSMutableAttributedString *)convertTextEmotionToAttachment:(NSString *)text font:(UIFont *)font;

/**
将已进行过格式处理的 NSMutableAttributedString 类型的表情文本转为属性字符串

@param attributeString 表情文本
@param font 文本d大小
@return 属性字符串
*/
- (NSMutableAttributedString *)convertTextEmotionToAttachmentWithAttributedString:(NSMutableAttributedString *)attributeString
                                                                             font:(UIFont *)font;

@end
