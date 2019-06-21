//
//  PLVPlayerSkinAudioModeView.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/6/11.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVPlayerSkinAudioModeView.h"
#import <Masonry/Masonry.h>

@interface PLVPlayerSkinAudioModeView ()

@property (nonatomic, strong) UIImageView * animationImgV;
@property (nonatomic, strong) NSMutableArray * imgArr;
@property (nonatomic, strong) UIButton * playVideoBtn;
@property (nonatomic, strong) dispatch_semaphore_t sem;

@end

@implementation PLVPlayerSkinAudioModeView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.sem = dispatch_semaphore_create(1);
        [self createUI];
    }
    return self;
}

- (void)dealloc{
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - ----------------- < Private Method > -----------------
- (void)createUI{
    self.backgroundColor = [UIColor colorWithRed:33/255.0 green:33/255.0 blue:33/255.0 alpha:1.0];
    
    self.alpha = 0;
    self.userInteractionEnabled = NO;
    
    [self addSubview:self.animationImgV];
    [self addSubview:self.playVideoBtn];
    
    [self loadImgArr];

    [self.animationImgV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.playVideoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.offset(0);
        make.height.offset(32);
        make.width.offset(96);
    }];
}

- (UIImageView *)animationImgV{
    if (_animationImgV == nil) {
        _animationImgV = [[UIImageView alloc]init];
        _animationImgV.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _animationImgV;
}

- (void)loadImgArr{
    if (self.imgArr == nil) {
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            dispatch_semaphore_wait(self.sem, DISPATCH_TIME_FOREVER);
            if (self.imgArr!=nil) {
                dispatch_semaphore_signal(self.sem);
                return;
            }
            
            NSMutableArray * imgArr = [NSMutableArray array];
            for (int i = 1; i <= 60; i++) {
                NSString * imgName = [NSString stringWithFormat:@"sound00%02d.png",i];
                UIImage * img = [self playerSkinImage:imgName];
                if (img != nil) {
                    [imgArr addObject:img];
                }
            }
            self.imgArr = imgArr;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.animationImgV.animationImages = imgArr;
                self.animationImgV.animationDuration = 3.5;
                [self.animationImgV startAnimating];
                dispatch_semaphore_signal(self.sem);
            });
        });
    }
}

- (UIButton *)playVideoBtn{
    if (_playVideoBtn == nil) {
        _playVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playVideoBtn setTitle:@"播放画面" forState:UIControlStateNormal];
        _playVideoBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:13];
        [_playVideoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_playVideoBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.7] forState:UIControlStateHighlighted];
        _playVideoBtn.layer.cornerRadius = 16;
        _playVideoBtn.layer.masksToBounds = YES;
        _playVideoBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        [_playVideoBtn.layer setBorderWidth:1.0];
        _playVideoBtn.backgroundColor = [UIColor colorWithRed:33/255.0 green:33/255.0 blue:33/255.0 alpha:1.0];
        [_playVideoBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_playVideoBtn addTarget:self action:@selector(playBtnDown:) forControlEvents:UIControlEventTouchDown];
    }
    return _playVideoBtn;
}

- (UIImage *)playerSkinImage:(NSString *)name {
    NSString *imageName = [@"PLVPlayerSkin.bundle/soundpng_60" stringByAppendingPathComponent:name];
    return [UIImage imageNamed:imageName];
}

#pragma mark - ----------------- < Event > -----------------
- (void)playBtnClick:(UIButton *)btn{
    _playVideoBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playVideoAudioModeView:)]) {
        [self.delegate playVideoAudioModeView:self];
    }
}

- (void)playBtnDown:(UIButton *)btn{
    _playVideoBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
}

#pragma mark - ----------------- < Public Method > -----------------
- (void)appear:(BOOL)show{
    NSTimeInterval alpha = show ? 1 : 0;
    BOOL enable = show ? YES : NO;
    if (show) {
        [UIView animateWithDuration:0.33 animations:^{
            self.alpha = alpha;
            self.userInteractionEnabled = enable;
        }];
    }else{
        self.alpha = alpha;
        self.userInteractionEnabled = enable;
    }

    if (show) {
        [self.animationImgV startAnimating];
    }else{
        [self.animationImgV stopAnimating];
    }
}

@end
