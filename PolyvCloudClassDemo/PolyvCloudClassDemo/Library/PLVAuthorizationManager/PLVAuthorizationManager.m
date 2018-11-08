//
//  PLVAuthorizationManager.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2018/10/24.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVAuthorizationManager.h"
#import <Photos/Photos.h>

@implementation PLVAuthorizationManager

#pragma mark - Gerneral

+ (PLVAuthorizationStatus)authorizationStatusWithType:(PLVAuthorizationType)type {
    switch (type) {
        case PLVAuthorizationTypeMediaVideo: {
            AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            return (PLVAuthorizationStatus)status;
        } break;
        case PLVAuthorizationTypeMediaAudio: {
            AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
            return (PLVAuthorizationStatus)status;
        } break;
        case PLVAuthorizationTypePhotoLibrary: {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            return (PLVAuthorizationStatus)status;
        } break;
        default:
            return PLVAuthorizationStatusNotDetermined;
            break;
    }
}

+ (void)requestAuthorizationWithType:(PLVAuthorizationType)type completion:(void (^)(BOOL))handler {
    switch (type) {
        case PLVAuthorizationTypeMediaVideo: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                handler(granted);
            }];
        } break;
        case PLVAuthorizationTypeMediaAudio: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                handler(granted);
            }];
        } break;
        case PLVAuthorizationTypePhotoLibrary: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                handler(status==PHAuthorizationStatusAuthorized);
            }];
        } break;
        default:
            break;
    }
}

#pragma mark - Special

+ (BOOL)authorizationForAudioAndVideo {
    PLVAuthorizationStatus videoStatus = [self authorizationStatusWithType:PLVAuthorizationTypeMediaVideo];
    PLVAuthorizationStatus audioStatus = [self authorizationStatusWithType:PLVAuthorizationTypeMediaAudio];
    if (videoStatus==PLVAuthorizationStatusAuthorized && audioStatus==PLVAuthorizationStatusAuthorized) {
        return YES;
    }else {
        return NO;
    }
}

+ (void)requestAuthorizationForAudioAndVideo:(void (^)(BOOL))handler {
    if (self.authorizationForAudioAndVideo) {
        handler(YES);
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self requestAuthorizationWithType:PLVAuthorizationTypeMediaVideo completion:^(BOOL granted) {
        BOOL videoGranted = granted;
        [weakSelf requestAuthorizationWithType:PLVAuthorizationTypeMediaAudio completion:^(BOOL granted) {
            if (granted && videoGranted) {
                handler(YES);
            }else {
                handler(NO);
            }
        }];
    }];
}

#pragma mark - Authorization Failure

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message viewController:(UIViewController *__weak)viewController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }]];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

@end
