//
//  PLVPhotoBrowser.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2018/10/24.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVPhotoBrowser.h"
#import <PolyvFoundationSDK/PLVAuthorizationManager.h>
#import <PolyvFoundationSDK/PLVProgressHUD.h>
#import <Masonry/Masonry.h>

NSString *const PLVPhotoBrowserDidShowImageOnScreenNotification = @"PLVPhotoBrowserDidShowImageOnScreenNotification"; 

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PLVPhotoBrowser ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) CGRect originFrame;
@property (nonatomic, assign) CGFloat scale;

@end

@implementation PLVPhotoBrowser

- (void)scaleImageViewToFullScreen:(UIImageView *)imageView {
    self.image = imageView.image;
    if (!self.image) {
        return;
    }
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.scale = 1.0;
    
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.backgroundView setBackgroundColor:[UIColor blackColor]];
    [self.backgroundView setAlpha:0];
    [window addSubview:self.backgroundView];
    
    self.originFrame = [imageView convertRect:imageView.bounds toView:window];
    UIImageView *largeImageView = [[UIImageView alloc] initWithFrame:self.originFrame];
    [largeImageView setImage:imageView.image];
    [largeImageView setTag:10];
    [self.backgroundView addSubview:largeImageView];
    
    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [downloadBtn setImage:[UIImage imageNamed:@"plv_btn_download"] forState:UIControlStateNormal];
    [downloadBtn addTarget:self action:@selector(downloadButtonBeClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.backgroundView addSubview:downloadBtn];
    [downloadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 40));
        make.right.equalTo(self.backgroundView.mas_right).offset(-15.0);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.backgroundView.mas_safeAreaLayoutGuideBottom).offset(-15.0);
        } else {
            make.bottom.equalTo(self.backgroundView.mas_bottom).offset(-15.0);
        }
    }];
    
    CGFloat newHeight = SCREEN_WIDTH * imageView.image.size.height / imageView.image.size.width;
    [UIView animateWithDuration:0.3 animations:^{
        [largeImageView setFrame:CGRectMake(0, 0, SCREEN_WIDTH, newHeight)];
        [largeImageView setCenter:self.backgroundView.center];
        [self.backgroundView setAlpha:1];
    } completion:^(BOOL finished) {
        if (finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:PLVPhotoBrowserDidShowImageOnScreenNotification object:self];
        }
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self.backgroundView addGestureRecognizer:tapGesture];
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [self.backgroundView addGestureRecognizer:pinchGesture];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGseture:)];
    [self.backgroundView addGestureRecognizer:panGesture];
}

#pragma mark - Privates

- (void)tapGesture:(UIGestureRecognizer *)recognizer {
    UIImageView *imageView = [self.backgroundView viewWithTag:10];
    [UIView animateWithDuration:0.3 animations:^{
        [imageView setFrame:self.originFrame];
        [self.backgroundView setAlpha:0];
    } completion:^(BOOL finished) {
        [self.backgroundView removeFromSuperview];
    }];
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)recognizer {
    UIImageView *imageView = [self.backgroundView viewWithTag:10];
    
    CGFloat oldScale = self.scale;
    self.scale *= recognizer.scale;
    if (self.scale < 1.0) {
        self.scale = 1.0;
        imageView.transform = CGAffineTransformIdentity;
    } else {
        imageView.transform = CGAffineTransformScale(imageView.transform, recognizer.scale, recognizer.scale);
    }
    
    if (self.scale < oldScale) {
        CGFloat imageWidth = SCREEN_WIDTH;
        CGFloat dw = imageWidth * self.scale - SCREEN_WIDTH;
        CGFloat dx = imageView.center.x;
        if (dw > 0.0) {
            if (dx < (SCREEN_WIDTH - dw) * 0.5) {
                dx = (SCREEN_WIDTH - dw) * 0.5;
            } else if (dx > (SCREEN_WIDTH + dw) * 0.5) {
                dx = (SCREEN_WIDTH + dw) * 0.5;
            }
        } else {
            dx = SCREEN_WIDTH * 0.5;
        }

        CGFloat imageHeight = SCREEN_WIDTH * imageView.image.size.height / imageView.image.size.width;
        CGFloat dh = imageHeight * self.scale - SCREEN_HEIGHT;
        CGFloat dy = imageView.center.y;
        if (dh > 0.0) {
            if (dy < (SCREEN_HEIGHT - dh) * 0.5) {
                dy = (SCREEN_HEIGHT - dh) * 0.5;
            } else if (dy > (SCREEN_HEIGHT + dh) * 0.5) {
                dy = (SCREEN_HEIGHT + dh) * 0.5;
            }
        } else {
            dy = SCREEN_HEIGHT * 0.5;
        }

        [imageView setCenter:CGPointMake(dx, dy)];
    }
    
    recognizer.scale = 1.0;
}

- (void)panGseture:(UIPanGestureRecognizer *)recognizer {
    UIImageView *imageView = [self.backgroundView viewWithTag:10];
    CGPoint translation = [recognizer translationInView:self.backgroundView];
    
    CGFloat imageWidth = SCREEN_WIDTH;
    CGFloat dw = imageWidth * self.scale - SCREEN_WIDTH;
    CGFloat dx = imageView.center.x;
    if (dw > 0.0) {
        dx = imageView.center.x + translation.x;
        if (dx < (SCREEN_WIDTH - dw) * 0.5) {
            dx = (SCREEN_WIDTH - dw) * 0.5;
        } else if (dx > (SCREEN_WIDTH + dw) * 0.5) {
            dx = (SCREEN_WIDTH + dw) * 0.5;
        }
    }
    
    CGFloat imageHeight = SCREEN_WIDTH * imageView.image.size.height / imageView.image.size.width;
    CGFloat dh = imageHeight * self.scale - SCREEN_HEIGHT;
    CGFloat dy = imageView.center.y;
    if (dh > 0.0) {
        dy = imageView.center.y + translation.y;
        if (dy < (SCREEN_HEIGHT - dh) * 0.5) {
            dy = (SCREEN_HEIGHT - dh) * 0.5;
        } else if (dy > (SCREEN_HEIGHT + dh) * 0.5) {
            dy = (SCREEN_HEIGHT + dh) * 0.5;
        }
    }
    
    [imageView setCenter:CGPointMake(dx, dy)];
    [recognizer setTranslation:CGPointZero inView:self.backgroundView];
}

- (void)downloadButtonBeClicked {
    PLVAuthorizationStatus status = [PLVAuthorizationManager authorizationStatusWithType:PLVAuthorizationTypePhotoLibrary];
    switch (status) {
        case PLVAuthorizationStatusAuthorized: {
            UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        } break;
        case PLVAuthorizationStatusDenied: {
            [self showHUDWithTitle:@"您无权访问相册，请授权后重新保存" detail:nil];
        } break;
        case PLVAuthorizationStatusNotDetermined: {
            [PLVAuthorizationManager requestAuthorizationWithType:PLVAuthorizationTypePhotoLibrary completion:^(BOOL granted) {
                if (granted) {
                    UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                }else {
                    [self showHUDWithTitle:@"授权失败，无法保存至您的相册" detail:nil];
                }
            }];
        } break;
        default:
            break;
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        [self showHUDWithTitle:@"图片保存至相册失败" detail:error.localizedDescription];
    }else {
        [self showHUDWithTitle:@"图片已保存到系统相册" detail:nil];
    }
}

- (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.backgroundView animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = title;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:3.0];
}

@end
