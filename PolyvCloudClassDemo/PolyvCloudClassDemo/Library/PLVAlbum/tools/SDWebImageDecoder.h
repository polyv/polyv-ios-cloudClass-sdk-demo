/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * Created by james <https://github.com/mystcolor> on 9/28/11.
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "ZImageInfo.h"

@interface UIImage (ForceDecode)

+ (void)requestThumbnailsImage:(PHAsset*)asset deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode resultHandler:(void (^)(UIImage *result, NSDictionary *info))resultHandler;
+ (PHImageRequestID)requestOriginImageData:(PHAsset*)asset synchronous:(BOOL)synchronous imageHandler:(void (^)(UIImage *img, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))imageHandler dataHandler:(void (^)(NSData *imgData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))dataHandler errorHandler:(void (^)(NSDictionary *info))errorHandler;
+ (UIImage*)getVideoImage:(AVAssetImageGenerator*)imgGenerator time:(CMTime)time;
+ (NSDictionary*)getExifFromImageData:(NSData*)imgData;
+ (CGSize)getImageSize:(UIImage*)image;

+ (CGSize)imageSizeOnScaleWidth:(UIImage*)image;
+ (UIImage*)decodedScaleImage:(UIImage*)image;
+ (UIImage*)decodedBaseWidthImage:(UIImage*)image;
+ (UIImage*)decodedOriginImage:(UIImage*)image;

@end
