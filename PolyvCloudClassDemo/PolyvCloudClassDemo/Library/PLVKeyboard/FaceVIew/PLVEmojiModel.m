//
//  PLVEmotionModel.m
//  BCKeyBoardDemo
//
//  Created by ftao on 2017/1/13.
//  Copyright © 2017年 io.hzlzh.yunshouyi. All rights reserved.
//

#import "PLVEmojiModel.h"

@implementation PLVEmojiModel

+ (instancetype)modelWithDictionary:(NSDictionary *)data {
    PLVEmojiModel *model = [PLVEmojiModel new];
    model.text = [NSString stringWithFormat:@"[%@]",data[@"text"]];
    model.imagePNG = data[@"image"];
    
    return model;
}

@end

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

@interface PLVEmojiModelManager ()

@property (nonatomic, strong) NSBundle *emotionBundle;
@property (nonatomic, strong) NSRegularExpression *regularExpression;

@end

@implementation PLVEmojiModelManager

CREATE_SHARED_MANAGER(PLVEmojiModelManager)

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Emotion" ofType:@"bundle"];
        self.emotionBundle = [NSBundle bundleWithPath:path];
        self.regularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\[]{1,5}\\]" options:kNilOptions error:nil];
    }
    
    return self;
}


- (UIImage *)imageForEmotionPNGName:(NSString *)pngName {
    return [UIImage imageNamed:pngName inBundle:self.emotionBundle compatibleWithTraitCollection:nil];
}

- (NSMutableAttributedString *)convertTextEmotionToAttachment:(NSString *)text font:(UIFont *)font {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font}];
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

@end
