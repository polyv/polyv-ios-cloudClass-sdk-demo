/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * Created by james <https://github.com/mystcolor> on 9/28/11.
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDecoder.h"
#import "MyTool.h"
#import "ZPicDefine.h"

@implementation UIImage (ForceDecode)

+ (void)requestThumbnailsImage:(PHAsset*)asset deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = deliveryMode;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:ThumbnailsSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        @autoreleasepool {
            resultHandler(result, info);
        }
    }];
}

+ (PHImageRequestID)requestOriginImageData:(PHAsset*)asset synchronous:(BOOL)synchronous imageHandler:(void (^)(UIImage *img, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))imageHandler dataHandler:(void (^)(NSData *imgData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))dataHandler errorHandler:(void (^)(NSDictionary *info))errorHandler {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = synchronous;
    options.networkAccessAllowed = YES;
    return [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info) {
        @autoreleasepool {
            if (imageData == nil) {
                if (errorHandler != nil) {
                    errorHandler(info);
                }
            } else {
                if (imageHandler != nil) {
                    UIImage *img = [UIImage imageWithData:imageData];
                    imageHandler(img, dataUTI, orientation, info);
                } else if (dataHandler != nil) {
                    dataHandler(imageData, dataUTI, orientation, info);
                }
            }
        }
    }];
}

+ (UIImage*)getVideoImage:(AVAssetImageGenerator*)imgGenerator time:(CMTime)time {
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef imageRef = [imgGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if (error == nil && imageRef != NULL) {
        UIImage *img = [[UIImage alloc] initWithCGImage:imageRef];
        CGImageRelease(imageRef);
        return [self decodedOriginImage:img];
    }
    return nil;
}

+ (NSDictionary*)getExifFromImageData:(NSData*)imgData {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imgData, NULL);
    CFDictionaryRef imageInfo = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    NSDictionary *exifDic = (__bridge NSDictionary*)CFDictionaryGetValue(imageInfo, kCGImagePropertyExifDictionary);
    CFRelease(imageInfo);
    CFRelease(imageSource);    
    return exifDic;
}

+ (CGSize)getImageSize:(UIImage*)image {
    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGSize size = CGSizeMake(width, height);
    
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            size = CGSizeMake(height, width);
            break;
        default:
            break;
    }
    
    return size;
}

+ (UIImage*)decodedImage:(UIImage*)image size:(CGSize)size {
    if (image.images) {
        return image;
    }

    CGImageRef imageRef = image.CGImage;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone || infoMask == kCGImageAlphaNoneSkipFirst || infoMask == kCGImageAlphaNoneSkipLast);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (CGImageGetBitsPerComponent(imageRef) > 8) {
        bitmapInfo = 0;
        bitmapInfo |= kCGBitmapByteOrderDefault;
        bitmapInfo |= kCGImageAlphaPremultipliedLast;
    } else if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1) {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    } else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    } else {
        bitmapInfo = 0;
        bitmapInfo |= kCGBitmapByteOrderDefault;
        bitmapInfo |= kCGImageAlphaPremultipliedLast;
    }

    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        return image;
    }
    
    BOOL flag = YES;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeRotation(M_PI);
            transform = CGAffineTransformTranslate(transform, -(CGFloat)size.width, -(CGFloat)size.height);
            break;
        case UIImageOrientationLeft:
            flag = NO;
            transform = CGAffineTransformMakeRotation(M_PI_2);
            transform = CGAffineTransformTranslate(transform, -(CGFloat)0, -(CGFloat)size.width);
            break;
        case UIImageOrientationRight:
            flag = NO;
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            transform = CGAffineTransformTranslate(transform, -(CGFloat)size.height, (CGFloat)0);
            break;
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformTranslate(transform, (CGFloat)size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, 0, (CGFloat)size.height);
            transform = CGAffineTransformScale(transform, 1, -1);
            break;
        case UIImageOrientationLeftMirrored:
            flag = NO;
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            transform = CGAffineTransformScale(transform, 1, -1);
            transform = CGAffineTransformTranslate(transform, -(CGFloat)size.height, -(CGFloat)size.width);
            break;
        case UIImageOrientationRightMirrored:
            flag = NO;
            transform = CGAffineTransformMakeRotation(M_PI_2);
            transform = CGAffineTransformScale(transform, 1, -1);
            break;
        default:
            break;
    }

    CGContextConcatCTM(context, transform);
    if (flag) {
        CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), imageRef);
    } else {
        CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.height, size.width), imageRef);
    }
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

+ (CGSize)imageSizeOnScaleWidth:(UIImage*)image {
    CGSize imageSize = [UIImage getImageSize:image];
    CGFloat w = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
    if (imageSize.width > w) {
        CGFloat scale_w = w / imageSize.width;
        CGSize imageSize_w = CGSizeMake(w, (int)(imageSize.height * scale_w));
        if (imageSize_w.width * imageSize_w.height * 3 >= imageSize.width * imageSize.height) {
            imageSize = imageSize_w;
        } else {
           imageSize = CGSizeMake((int)(imageSize.width / 2.5), (int)(imageSize.height / 2.5));
        }
    }
    return imageSize;
}

+ (UIImage*)decodedScaleImage:(UIImage*)image {
    return [UIImage decodedImage:image size:[UIImage imageSizeOnScaleWidth:image]];
}

+ (CGSize)imageSizeOnBaseWidth:(UIImage*)image {
    CGSize imageSize = [UIImage getImageSize:image];
    CGFloat w = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
    if (imageSize.width != w) {
        CGFloat scale_w = w / imageSize.width;
        imageSize = CGSizeMake(w, (int)(imageSize.height * scale_w));
    }
    return imageSize;
}

+ (UIImage*)decodedBaseWidthImage:(UIImage*)image {
    return [UIImage decodedImage:image size:[UIImage imageSizeOnBaseWidth:image]];
}

+ (UIImage*)decodedOriginImage:(UIImage*)image {
    return [UIImage decodedImage:image size:[UIImage getImageSize:image]];
}

@end
