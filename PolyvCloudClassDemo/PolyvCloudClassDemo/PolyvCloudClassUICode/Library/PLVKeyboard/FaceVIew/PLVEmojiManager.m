//
//  PLVEmotionModel.m
//  BCKeyBoardDemo
//
//  Created by ftao on 2017/1/13.
//  Copyright © 2017年 io.hzlzh.yunshouyi. All rights reserved.
//

#import "PLVEmojiManager.h"

#define CREATE_SHARED_MANAGER(CLASS_NAME) \
+ (instancetype)sharedManager { \
static CLASS_NAME *_instance; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[CLASS_NAME alloc] init]; \
}); \
\
return _instance; \
}

@implementation PLVEmojiModel

+ (instancetype)modelWithDictionary:(NSDictionary *)data {
    PLVEmojiModel *model = [PLVEmojiModel new];
    model.text = [NSString stringWithFormat:@"[%@]",data[@"text"]];
    model.imagePNG = data[@"image"];
    return model;
}

@end

@interface PLVEmojiManager ()

@property (nonatomic, strong) NSBundle *emotionBundle;
@property (nonatomic, strong) NSRegularExpression *regularExpression;

@end

@implementation PLVEmojiManager

CREATE_SHARED_MANAGER(PLVEmojiManager)

- (NSBundle *)emotionBundle {
    if (!_emotionBundle) {
        _emotionBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Emotion" ofType:@"bundle"]];
    }
    return _emotionBundle;
}

- (NSRegularExpression *)regularExpression {
    if (!_regularExpression) {
        _regularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\[]{1,5}\\]" options:kNilOptions error:nil];
    }
    return _regularExpression;
}

- (NSMutableArray<PLVEmojiModel *> *)allEmojiModels {
    if (!_allEmojiModels) {
        [self loadEmotions];
    }
    return _allEmojiModels;
}

- (NSMutableDictionary *)emotionDictionary {
    if (!_emotionDictionary) {
        [self loadEmotions];
    }
    return _emotionDictionary;
}
#pragma mark - public

- (UIImage *)imageForEmotionPNGName:(NSString *)pngName {
    return [UIImage imageNamed:pngName inBundle:self.emotionBundle compatibleWithTraitCollection:nil];
}

- (NSMutableAttributedString *)convertTextEmotionToAttachment:(NSString *)text font:(UIFont *)font {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font}];
    return [self convertTextEmotionToAttachmentWithAttributedString:attributeString font:font];
}

- (NSMutableAttributedString *)convertTextEmotionToAttachmentWithAttributedString:(NSMutableAttributedString *)attributeString
                                                                             font:(UIFont *)font {
    NSArray<NSTextCheckingResult *> *matchArray = [self.regularExpression matchesInString:attributeString.string options:kNilOptions range:NSMakeRange(0, attributeString.length)];
    NSUInteger offset = 0;
    for (NSTextCheckingResult *result in matchArray) {
        NSRange range = NSMakeRange(result.range.location - offset, result.range.length);
        NSTextAttachment *attachMent = [[NSTextAttachment alloc] init];
        NSString *imageText = [attributeString.string substringWithRange:NSMakeRange(range.location, range.length)];
        NSString *imageName = self.emotionDictionary[imageText];
        UIImage *image = [self imageForEmotionPNGName:imageName];
        
        attachMent.image = image;
        attachMent.bounds = CGRectMake(0, font.descender, font.lineHeight, font.lineHeight);
        
        NSAttributedString *emojiAttrStr = [NSAttributedString attributedStringWithAttachment:attachMent];
        [attributeString replaceCharactersInRange:range withAttributedString:emojiAttrStr];
        offset += result.range.length - emojiAttrStr.length;
    }
    
    return attributeString;
}


#pragma mark - private

- (void)loadEmotions {
    self.allEmojiModels = [NSMutableArray array];
    self.emotionDictionary = [NSMutableDictionary dictionary];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Emotions" ofType:@"plist"];
    NSArray<NSDictionary *> *groups = [NSArray arrayWithContentsOfFile:path];  // 获取plist文件内容
    for (NSDictionary *group in groups) {
        if ([group[@"type"] isEqualToString:@"emoji"]) {
            NSArray<NSDictionary *> *items = group[@"items"];
            for (NSDictionary *item in items) {
                PLVEmojiModel *model = [PLVEmojiModel modelWithDictionary:item];
                [self.allEmojiModels addObject:model];
                self.emotionDictionary[model.text] = model.imagePNG;
            }
        }
    }
}

@end
