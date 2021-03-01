//
//  PLVPlayerLogo.h
//  PolyvCloudClassDemo
//
//  Created by jiaweihuang on 2020/12/11.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/// logo位置：
typedef NS_ENUM(NSInteger, PLVPlayerLogoPosition) {
    PLVPlayerLogoPositionNone = 0,   // 不显示
    PLVPlayerLogoPositionLeftUp,     // 左上
    PLVPlayerLogoPositionRightUp,    // 右上（默认值）
    PLVPlayerLogoPositionLeftDown,   // 左下
    PLVPlayerLogoPositionRightDown   // 右下
};

/// logo 配置参数类
@interface PLVPlayerLogoParam : NSObject

/*
 logo 宽高像素单位与百分比单位二选其一
 */
/// logo 宽与高像素（单位：pt），默认 0
@property (nonatomic, assign) CGFloat logoWidth;
@property (nonatomic, assign) CGFloat logoHeight;

/// logo 宽与高百分比（单位：%），取值范围 [0,1]，默认 0
@property (nonatomic, assign) CGFloat logoWidthScale;
@property (nonatomic, assign) CGFloat logoHeightScale;

/*
logo 水平与垂直偏移像素单位与百分比单位二选其一
*/
/// logo 水平与垂直偏移像素（单位：pt），默认 0
@property (nonatomic, assign) CGFloat xOffset;
@property (nonatomic, assign) CGFloat yOffset;

/// logo 水平与垂直偏移百分比（单位：%），取值范围 [0,1]，默认 0
@property (nonatomic, assign) CGFloat xOffsetScale;
@property (nonatomic, assign) CGFloat yOffsetScale;

/// logo 位置，默认右上角
@property (nonatomic, assign) PLVPlayerLogoPosition position;

///透明度，取值范围 [0,1]，默认 1
@property (nonatomic, assign) CGFloat logoAlpha;

/// logo图片的URL，必须使用 https 协议
@property (nonatomic, copy) NSString *logoUrl;


@end

@interface PLVPlayerLogo : UIView

/// 添加 logo，一个 PLVPlayerLogo 对象可同时添加最多两个 logo
- (void)insertLogoWithParam:(PLVPlayerLogoParam *)param;

- (void)addAtView:(UIView *)container;

@end

