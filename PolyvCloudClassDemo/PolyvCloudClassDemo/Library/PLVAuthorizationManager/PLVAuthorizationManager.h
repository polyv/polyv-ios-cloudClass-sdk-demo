//
//  PLVAuthorizationManager.h
//  PolyvCloudClassDemo
//
//  Created by ftao on 2018/10/24.
//  Copyright © 2018 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 @enum PLVAuthorizationStatus
 @abstract Authorization Status
 
 @constant PLVAuthorizationStatusNotDetermined
    User has not yet made a choice with regards to this application.
 @constant PLVAuthorizationStatusRestricted
    This application is not authorized to access relevant content. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
 @constant PLVAuthorizationStatusDenied
    User has explicitly denied this application access to relevant content.
 @constant PLVAuthorizationStatusAuthorized
    User has authorized this application to access relevant content.
 */
typedef NS_ENUM(NSInteger, PLVAuthorizationStatus) {
    PLVAuthorizationStatusNotDetermined = 0,
    PLVAuthorizationStatusRestricted    = 1,
    PLVAuthorizationStatusDenied        = 2,
    PLVAuthorizationStatusAuthorized    = 3,
};

typedef NS_ENUM(NSUInteger, PLVAuthorizationType) {
    PLVAuthorizationTypeMediaVideo,
    PLVAuthorizationTypeMediaAudio,
    //PLVAuthorizationTypeMediaLibrary,
    PLVAuthorizationTypePhotoLibrary,
};

@interface PLVAuthorizationManager : NSObject

#pragma mark - Gerneral

+ (PLVAuthorizationStatus)authorizationStatusWithType:(PLVAuthorizationType)type;

+ (void)requestAuthorizationWithType:(PLVAuthorizationType)type completion:(void (^)(BOOL granted))handler;

#pragma mark - Special

/**
 Whether there is audio and video authorization

 @return At the same time, there is camera and audio permission return YES, otherwise return NO.
 */
+ (BOOL)authorizationForAudioAndVideo;

/**
 Request audio and video permissions
 
 @param handler granted be true when both audio and video permissions are successful.
 */
+ (void)requestAuthorizationForAudioAndVideo:(void (^)(BOOL granted))handler;

#pragma mark - Authorization Failure

/**
 show alert
    When you click the ok/setting button from this alert, the system launches the Settings app and displays the app’s custom settings, if it has any.
 
 @param title alert title, can be nil.
 @param message alert message, can be nil.
 @param viewController current controller.
 */
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message viewController:(__weak UIViewController *)viewController;

@end
