//
//  PLVCameraViewController.m
//  zPin_Pro
//
//  Created by zykhbl on 2017/12/17.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "PLVCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SDWebImageDecoder.h"

#define WIDTH [[UIScreen mainScreen] bounds].size.width
#define HEIGHT [[UIScreen mainScreen] bounds].size.height

@interface PLVCameraViewController ()

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *exitBtn;
@property (nonatomic, strong) UIButton *switchCameraBtn;
@property (nonatomic, strong) UIButton *shootBtn;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, strong) UIImage *selectedImage;

@end

@implementation PLVCameraViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [self.device lockForConfiguration:nil];
    if (self.device.position == AVCaptureDevicePositionFront || self.device.position == AVCaptureDevicePositionUnspecified) {
        if ([self.device isFlashModeSupported:AVCaptureFlashModeOff]) {
            [self.device setFlashMode:AVCaptureFlashModeOff];
        } else if ([self.device isFlashModeSupported:AVCaptureFlashModeOn]) {
            [self.device setFlashMode:AVCaptureFlashModeOn];
        } else if ([self.device isFlashModeSupported:AVCaptureFlashModeOn]) {
            [self.device setFlashMode:AVCaptureFlashModeAuto];
        }
    } else if ([self.device isFlashModeSupported:AVCaptureFlashModeAuto]) {
        [self.device setFlashMode:AVCaptureFlashModeAuto];
    }
    [self.device unlockForConfiguration];
    
    self.session = [[AVCaptureSession alloc] init];
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.stillImageOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    [self.session startRunning];
    
    self.preLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.preLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.preLayer.frame = CGRectMake(0.0, 0.0, WIDTH, HEIGHT);
    [self.view.layer addSublayer:self.preLayer];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, HEIGHT)];
    self.imageView.hidden = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.imageView];
    
    CGFloat y = 30.0;
    if (@available(iOS 11.0, *)) {
        y += self.view.safeAreaLayoutGuide.layoutFrame.origin.y;
    }
    self.exitBtn = [self createButton:@"plv_shoot_close.png" frame:CGRectMake(20.0, y, 44.0, 44.0) action:@selector(exitAction:)];
    self.switchCameraBtn = [self createButton:@"plv_shoot_switchCamera.png" frame:CGRectMake(WIDTH - 50.0, y, 44.0, 44.0) action:@selector(switchCameraAction:)];
    self.shootBtn = [self createButton:@"plv_btn_shoot.png" frame:CGRectMake(WIDTH * 0.5 - 37.0, HEIGHT - 117.0, 74.0, 74.0) action:@selector(shootAction:)];
    self.cancelBtn = [self createButton:@"plv_shoot_cancel.png" frame:self.shootBtn.frame action:@selector(cancelAction:)];
    self.cancelBtn.hidden = YES;
    self.sendBtn = [self createButton:@"plv_shoot_send.png" frame:self.shootBtn.frame action:@selector(sendAction:)];
    self.sendBtn.hidden = YES;
}

- (void)dealloc {
    [self.session stopRunning];
}

#pragma mark - Action
- (IBAction)exitAction:(UIButton *)sender {
    [self dismissCameraViewController];
}

- (IBAction)switchCameraAction:(UIButton *)sender {
    self.switchCameraBtn.selected = !self.switchCameraBtn.selected;
    
    AVCaptureDevicePosition direction = AVCaptureDevicePositionBack;
    if (self.switchCameraBtn.selected) {
        direction = AVCaptureDevicePositionFront;
    }
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == direction) {
            [self.preLayer.session beginConfiguration];
            for (AVCaptureInput *oldInput in self.preLayer.session.inputs) {
                [self.preLayer.session removeInput:oldInput];
            }
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            [self.preLayer.session addInput:input];
            [self.preLayer.session commitConfiguration];
            break;
        }
    }
}

- (IBAction)shootAction:(UIButton *)sender {
    self.exitBtn.hidden = YES;
    self.shootBtn.hidden = YES;
    AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!connection) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
        if (!error) {
            NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            weakSelf.selectedImage = [UIImage decodedScaleImage:[UIImage imageWithData:jpegData]];
            weakSelf.imageView.image = weakSelf.selectedImage;
            [weakSelf switchView:YES];
        } else {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

- (IBAction)cancelAction:(UIButton *)sender {
    [self switchView:NO];
}

- (IBAction)sendAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraViewController:uploadImage:)]) {
        [self.delegate cameraViewController:self uploadImage:self.selectedImage];
    }
    [self dismissCameraViewController];
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - private
- (UIButton *)createButton:(NSString *)normalImage frame:(CGRect)frame action:(SEL)action {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    [btn setBackgroundImage:[UIImage imageNamed:normalImage] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

- (void)switchView:(BOOL)flag {
    self.preLayer.hidden = flag;
    self.exitBtn.hidden = flag;
    self.switchCameraBtn.hidden = flag;
    
    if (flag) {
        self.imageView.hidden = !flag;
        self.shootBtn.hidden = flag;
        self.cancelBtn.hidden = !flag;
        self.sendBtn.hidden = !flag;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        if (flag) {
            weakSelf.cancelBtn.frame = CGRectMake(WIDTH * 0.5 - 134.0, HEIGHT -117.0, 74.0, 74.0);
            weakSelf.sendBtn.frame = CGRectMake(WIDTH * 0.5 + 60.0, HEIGHT -117.0, 74.0, 74.0);
        } else {
            weakSelf.imageView.alpha = 0.0;
            weakSelf.cancelBtn.frame = weakSelf.shootBtn.frame;
            weakSelf.sendBtn.frame = weakSelf.shootBtn.frame;
        }
    } completion:^(BOOL finished) {
        weakSelf.imageView.alpha = 1.0;
        if (!flag) {
            weakSelf.imageView.hidden = !flag;
            weakSelf.shootBtn.hidden = flag;
            weakSelf.cancelBtn.hidden = !flag;
            weakSelf.sendBtn.hidden = !flag;
        }
    }];
}

- (void)dismissCameraViewController {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissCameraViewController:)]) {
        [self.delegate dismissCameraViewController:self];
    }
}

@end
