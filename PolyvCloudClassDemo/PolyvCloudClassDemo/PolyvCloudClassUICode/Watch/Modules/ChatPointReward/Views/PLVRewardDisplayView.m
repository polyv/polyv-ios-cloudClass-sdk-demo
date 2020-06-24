//
//  PLVRewardDisplayView.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVRewardDisplayView.h"

#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVRewardDisplayView ()

@property (nonatomic, strong) UIView * bgView;
@property (nonatomic, strong) UIView * gradientBgView;
@property (nonatomic, strong) CAGradientLayer * gradientBgLayer;
@property (nonatomic, strong) UILabel * nameLabel;
@property (nonatomic, strong) UILabel * prizeNameLabel;
@property (nonatomic, strong) UIImageView * prizeImageView;
@property (nonatomic, strong) UIView * animationBgView;
@property (nonatomic, strong) PLVStrokeBorderLabel * xSymbolLabel;
@property (nonatomic, strong) PLVStrokeBorderLabel * numLabel;

@property (nonatomic, strong) PLVRewardGoodsModel * model;

@end

@implementation PLVRewardDisplayView

- (void)layoutSubviews{
    self.gradientBgLayer.frame = self.gradientBgView.bounds;
}

#pragma mark - [ Init ]
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI{
    self.clipsToBounds = YES;
    
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.gradientBgView];
    [self.gradientBgView.layer addSublayer:self.gradientBgLayer];
    [self.bgView addSubview:self.nameLabel];
    [self.bgView addSubview:self.prizeNameLabel];

    [self.bgView addSubview:self.prizeImageView];
    [self.bgView addSubview:self.animationBgView];
//    self.animationBgView.backgroundColor = [UIColor yellowColor];
    [self.animationBgView addSubview:self.xSymbolLabel];
    [self.animationBgView addSubview:self.numLabel];

    /// layout
    __weak typeof(self) weakSelf = self;
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.bottom.offset(0);
        make.height.offset(PLVDisplayViewHeight);
    }];
    
    [self.gradientBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.offset(0);
        make.top.offset(11);
    }];
    
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(12);
        make.top.mas_equalTo(weakSelf.gradientBgView.mas_top).offset(4);
        make.right.mas_equalTo(weakSelf.prizeImageView.mas_left).offset(-2);
    }];
    
    [self.prizeNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(13);
        make.bottom.mas_equalTo(weakSelf.gradientBgView.mas_bottom).offset(-4);
    }];

    [self.prizeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.offset(48);
        make.left.offset(155);
        make.bottom.offset(-4);
    }];
    
    [self.animationBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(weakSelf.bgView.mas_height).offset(0);
        make.top.offset(11);
        make.right.offset(0);
        make.left.mas_equalTo(weakSelf.prizeImageView.mas_right).offset(0);
    }];
    
    [self.xSymbolLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(weakSelf.bgView.mas_bottom).offset(-2);
        make.left.mas_equalTo(weakSelf.prizeImageView.mas_right).offset(-2);
        make.width.offset(20);
    }];
    
    [self.numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(weakSelf.bgView.mas_bottom).offset(0);
        make.left.mas_equalTo(weakSelf.xSymbolLabel.mas_right).offset(0);
        make.right.mas_equalTo(weakSelf.bgView.mas_right).offset(0);
    }];
}

#pragma mark - [ Private Methods ]
#pragma mark Getter
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
    }
    return _bgView;
}

- (UIView *)gradientBgView{
    if (!_gradientBgView) {
        _gradientBgView = [[UIView alloc]init];
//        _gradientBgView.backgroundColor = [UIColor lightGrayColor];
    }
    return _gradientBgView;
}

- (CAGradientLayer *)gradientBgLayer{
    if (!_gradientBgLayer) {
        _gradientBgLayer = [CAGradientLayer layer];
        _gradientBgLayer.startPoint = CGPointMake(0.5, 0.5);
        _gradientBgLayer.endPoint = CGPointMake(1.0, 0.5);
        _gradientBgLayer.colors = @[(__bridge id)[UIColor colorWithRed:235/255.0 green:81/255.0 blue:69/255.0 alpha:1.0].CGColor, (__bridge id)[UIColor colorWithWhite:1 alpha:0].CGColor];
        _gradientBgLayer.locations = @[@(0), @(1.0f)];
    }
    return _gradientBgLayer;
}

- (UILabel *)nameLabel{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.textColor = [UIColor colorWithRed:252/255.0 green:242/255.0 blue:166/255.0 alpha:1.0];
        _nameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _nameLabel.text = @"观众名";
    }
    return _nameLabel;
}

- (UILabel *)prizeNameLabel{
    if (!_prizeNameLabel) {
        _prizeNameLabel = [[UILabel alloc]init];
        _prizeNameLabel.textAlignment = NSTextAlignmentLeft;
        _prizeNameLabel.textColor = [UIColor whiteColor];
        _prizeNameLabel.font = [UIFont fontWithName:@"PingFang SC" size:10];
        _prizeNameLabel.text = @"赠送    礼物";
    }
    return _prizeNameLabel;
}

- (UIImageView *)prizeImageView{
    if (!_prizeImageView) {
        _prizeImageView = [[UIImageView alloc]init];
        
    }
    return _prizeImageView;
}

- (UIView *)animationBgView{
    if (!_animationBgView) {
        _animationBgView = [[UIView alloc]init];
    }
    return _animationBgView;
}

- (PLVStrokeBorderLabel *)xSymbolLabel{
    if (!_xSymbolLabel) {
        _xSymbolLabel = [[PLVStrokeBorderLabel alloc]init];
        _xSymbolLabel.text = @"x";
        _xSymbolLabel.textAlignment = NSTextAlignmentCenter;
        _xSymbolLabel.textColor = [UIColor colorWithRed:245/255.0 green:124/255.0 blue:0/255.0 alpha:1.0];
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(5 * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor * fontDesc = [UIFontDescriptor fontDescriptorWithName:@"Helvetica-BoldOblique" matrix:matrix];
        _xSymbolLabel.font = [UIFont fontWithDescriptor:fontDesc size:20];
    }
    return _xSymbolLabel;
}

- (PLVStrokeBorderLabel *)numLabel{
    if (!_numLabel) {
        _numLabel = [[PLVStrokeBorderLabel alloc]init];
        _numLabel.text = @"x 1";
        _numLabel.textAlignment = NSTextAlignmentLeft;
        _numLabel.textColor = [UIColor colorWithRed:245/255.0 green:124/255.0 blue:0/255.0 alpha:1.0];
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(5 * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor * fontDesc = [UIFontDescriptor fontDescriptorWithName:@"Helvetica-BoldOblique" matrix:matrix];
        _numLabel.font = [UIFont fontWithDescriptor:fontDesc size:28];
    }
    return _numLabel;
}


#pragma mark - [ Public Methods ]
+ (instancetype)displayViewWithModel:(PLVRewardGoodsModel *)model
                            goodsNum:(NSInteger)goodsNum
                          personName:(NSString *)personName{
    if ([model isKindOfClass:PLVRewardGoodsModel.class]) {
        PLVRewardDisplayView * view = [[PLVRewardDisplayView alloc]init];
        [view.prizeImageView sd_setImageWithURL:[NSURL URLWithString:model.goodImgFullURL]];
        view.prizeNameLabel.text = [NSString stringWithFormat:@"赠送  %@",model.goodName];
        
        view.nameLabel.text = personName;
        view.numLabel.text = [NSString stringWithFormat:@"%ld",goodsNum];
        
        if (goodsNum > 1) {
            view.animationBgView.hidden = NO;
        }else{
            view.animationBgView.hidden = YES;
        }
        
        view.model = model;
        return view;
    }else{
        return nil;
    }
}

- (void)showNumAnimation{
    if ([self.numLabel.text integerValue] > 1) {
        [self showZoomAnimationWithLayer:self.animationBgView.layer];
    }
    
    __weak typeof(self) weakSelf = self;
    float delayTime = 0.12 + 0.15 + 0.15 + 1;
    [UIView animateWithDuration:0.1 delay:delayTime options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.bgView.alpha = 0.2;
        [weakSelf.bgView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.offset(- PLVDisplayViewHeight);
        }];
        [weakSelf layoutIfNeeded];
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
        if (weakSelf.willRemoveBlock) { weakSelf.willRemoveBlock(); }
    }];
}

- (void)showZoomAnimationWithLayer:(CALayer *)layer{
    float toTime = 0.12;
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:1.5];
    animation.duration = toTime;
    animation.autoreverses = NO;
    animation.repeatCount = 0;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [layer addAnimation:animation forKey:@"zoom"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(toTime + 0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CABasicAnimation * animationBack = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        animationBack.fromValue = [NSNumber numberWithFloat:1.5];
        animationBack.toValue = [NSNumber numberWithFloat:1.0];
        animationBack.duration = 0.15;
        animationBack.autoreverses = NO;
        animationBack.repeatCount = 0;
        animationBack.removedOnCompletion = NO;
        animationBack.fillMode = kCAFillModeForwards;
        [layer addAnimation:animationBack forKey:@"zoom"];
    });
}

@end

@implementation PLVStrokeBorderLabel

- (void)drawTextInRect:(CGRect)rect
{
    // 描边
    CGContextRef c = UIGraphicsGetCurrentContext ();
    CGContextSetLineWidth (c, 3);
    CGContextSetLineJoin (c, kCGLineJoinRound);
    CGContextSetTextDrawingMode (c, kCGTextStroke);

    // 描边颜色
    UIColor * originColor = self.textColor;
    self.textColor = [UIColor whiteColor];
    [super drawTextInRect:rect];

    // 文字颜色
    self.textColor = originColor;
    CGContextSetTextDrawingMode (c, kCGTextFill);
    [super drawTextInRect:rect];
}

@end
