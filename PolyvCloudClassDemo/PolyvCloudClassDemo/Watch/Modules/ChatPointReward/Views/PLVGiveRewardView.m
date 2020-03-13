//
//  PLVGiveRewardView.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVGiveRewardView.h"

#import <Masonry/Masonry.h>
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>
#import <PolyvCloudClassSDK/PolyvCloudClassSDK.h>

#import "PLVGiveRewardGoodsButton.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

@interface PLVGiveRewardView ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIView * bgView;
@property (nonatomic, strong) UIView * rewardBgView;

@property (nonatomic, strong) UIView * titleBgView;
@property (nonatomic, strong) UIButton * backButton;
@property (nonatomic, strong) UIButton * titleTabButton;

@property (nonatomic, strong) UIView * prizeBgView;
@property (nonatomic, strong) CAGradientLayer * prizeBgLayer;
@property (nonatomic, strong) UIImageView * ribbonImageView;
@property (nonatomic, strong) UILabel * pointsLabel;
@property (nonatomic, strong) UIScrollView * prizeBgScrollView;
@property (nonatomic, strong) UIPageControl * pageControl;

@property (nonatomic, strong) UIView * numBgView;
@property (nonatomic, strong) UIScrollView * numButtonScrollView;
@property (nonatomic, strong) UIButton * sendButton;

/// 数据
@property (nonatomic, strong) NSArray <PLVRewardGoodsModel *> * modelArray;
@property (nonatomic, assign) CGFloat rewardBgViewH;

/// 状态
@property (nonatomic, strong) UIButton * curSelectedNumButton;
@property (nonatomic, strong) PLVGiveRewardGoodsButton * curSelectedPrizeButton;
@property (nonatomic, strong) PLVRewardGoodsModel * curSelectedPrizeModel;
@property (nonatomic, assign) BOOL oriUnableRotate;

@end


@implementation PLVGiveRewardView

- (void)layoutSubviews{
    self.prizeBgLayer.frame = self.prizeBgView.bounds;
}

#pragma mark - [ Init ]
- (instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI{
    self.rewardBgViewH = 342 + ([self isiPhoneXSeries] ? 34 : 0);

    [self addSubview:self.bgView];
    [self addSubview:self.rewardBgView];
    
    [self.rewardBgView addSubview:self.titleBgView];
    [self.titleBgView addSubview:self.backButton];
    [self.titleBgView addSubview:self.titleTabButton];

    [self.rewardBgView addSubview:self.prizeBgView];
    [self.prizeBgView.layer addSublayer:self.prizeBgLayer];
    [self.prizeBgView addSubview:self.ribbonImageView];
    [self.prizeBgView addSubview:self.pointsLabel];
    [self.prizeBgView addSubview:self.prizeBgScrollView];
    [self.prizeBgView addSubview:self.pageControl];

    [self.rewardBgView addSubview:self.numBgView];
    [self.numBgView addSubview:self.numButtonScrollView];
    [self.numBgView addSubview:self.sendButton];
    
    CGFloat numButtonWidth = 38;
    CGFloat numButtonPadding = 4;
    NSArray * numArray = @[@"1",@"5",@"10",@"66",@"88",@"666"];
    for (int i = 0; i < numArray.count; i ++) {
        NSString * numString = numArray[i];
        UIButton * numButton = [self createNumButtonWithNumString:numString];
        numButton.tag = 100 + i;
        [self.numButtonScrollView addSubview:numButton];
        
        if (i==0) {
            numButton.selected = YES;
            self.curSelectedNumButton = numButton;
        }
        
        [numButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(12);
            make.width.offset(numButtonWidth);
            make.height.offset(24);
            if (i==0) {
                make.left.offset(19);
            }else{
                UIButton * lastButton = (UIButton *)[self.numButtonScrollView viewWithTag:numButton.tag - 1];
                make.left.mas_equalTo(lastButton.mas_right).offset(numButtonPadding);
            }
        }];
    }
    CGFloat totalWidth = 19 + (numButtonWidth + numButtonPadding) * numArray.count;
    self.numButtonScrollView.contentSize = CGSizeMake(totalWidth, 48);
    
    /// layout
    __weak typeof(self) weakSelf = self;
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    [self.rewardBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.height.offset(weakSelf.rewardBgViewH);
        make.bottom.offset(weakSelf.rewardBgViewH);
    }];
    
    [self.titleBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.offset(0);
        make.height.offset(48);
    }];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(0);
        make.height.width.mas_equalTo(weakSelf.titleBgView.mas_height).offset(0);
    }];
    [self.titleTabButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.bottom.offset(0);
        make.width.offset(70);
    }];
    
    [self.prizeBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.offset(48);
        make.bottom.mas_equalTo(weakSelf.numBgView.mas_top).offset(0);
    }];
    [self.ribbonImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(16);
        make.left.right.offset(0);
        make.height.offset(67);
    }];
    [self.pointsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-16);
        make.bottom.mas_equalTo(weakSelf.ribbonImageView.mas_bottom).offset(-5);
    }];
    [self.prizeBgScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.ribbonImageView.mas_bottom).offset(3);
        make.left.right.offset(0);
        make.height.offset(130);
    }];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(0);
        make.height.offset(16);
        make.left.right.offset(0);
    }];
    
    CGFloat numBgViewH = 48 + ([weakSelf isiPhoneXSeries] ? 34 : 0);
    [self.numBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.offset(numBgViewH);
        make.left.right.offset(0);
        make.bottom.offset(0);
    }];
    [self.numButtonScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.offset(0);
        make.right.mas_equalTo(weakSelf.sendButton.mas_left).offset(-19);
    }];
    [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.offset(24);
        make.width.offset(64);
        make.right.offset(-16);
        make.top.offset(12);
    }];

}


#pragma mark - [ Private Methods ]
- (void)hide{
    if (self.alpha == 0) { return; }
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0;
        [weakSelf.rewardBgView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.offset(weakSelf.rewardBgViewH);
        }];
        [weakSelf layoutIfNeeded];
    } completion:^(BOOL finished) {
        [PLVLiveVideoConfig sharedInstance].unableRotate = weakSelf.oriUnableRotate;
        [weakSelf removeFromSuperview];
    }];
}

- (void)prizeScrollviewRefreshGoods:(NSArray <PLVRewardGoodsModel *> *)prizeModelArray{
    for (UIView * subview in self.prizeBgScrollView.subviews) {
        [subview removeFromSuperview];
    }
    
    for (int j = 0; j < prizeModelArray.count; j ++) {
        PLVRewardGoodsModel * model = prizeModelArray[j];
        
        PLVGiveRewardGoodsButton * button = [[PLVGiveRewardGoodsButton alloc]init];
        button.model = model;
        button.tag = 200 + j;
        [button addTarget:self action:@selector(prizeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.prizeBgScrollView addSubview:button];
        
        if (j == 0) {
            button.selected = YES;
            self.curSelectedPrizeButton = button;
            self.curSelectedPrizeModel = model;
        }
        
        int row = j % 3;
        int section = j / 3;
        float width = 100.0;
        float height = 130.0;
        float paddingScale = (SCREEN_WIDTH - width * 3) / 75.0;
        float padding = 7.5 * paddingScale;
        float leftPadding = 30 * paddingScale;
        float x = section * SCREEN_WIDTH + leftPadding + row * (width + padding);
        button.frame = CGRectMake(x, 0, width, height);
    }
}

- (UIButton *)createNumButtonWithNumString:(NSString *)num{
    UIButton * numButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [numButton setTitle:num forState:UIControlStateNormal];
    [numButton setTitleColor:[UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0] forState:UIControlStateNormal];
    [numButton setTitleColor:[UIColor colorWithRed:198/255.0 green:64/255.0 blue:76/255.0 alpha:1.0] forState:UIControlStateSelected];
    [numButton setBackgroundImage:[PLVColorUtil createImageWithColor:[UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0]] forState:UIControlStateSelected];
    [numButton setBackgroundImage:[PLVColorUtil createImageWithColor:[UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0]] forState:UIControlStateSelected];
    numButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    numButton.layer.masksToBounds = YES;
    numButton.layer.cornerRadius = 12;
    numButton.layer.borderWidth = 1;
    numButton.layer.borderColor = [UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0].CGColor;
    [numButton addTarget:self action:@selector(numButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    return numButton;
}

- (BOOL)isiPhoneXSeries{
    BOOL isPhoneX = NO;
    if (PLV_iOSVERSION_Available_11_0) {
        isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;
    }
    return isPhoneX;
}

#pragma mark Getter
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        [_bgView addGestureRecognizer: [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bgViewTapAction:)]];
    }
    return _bgView;
}

- (UIView *)rewardBgView{
    if (!_rewardBgView) {
         _rewardBgView = [[UIView alloc]init];
         _rewardBgView.backgroundColor = [UIColor darkGrayColor];
     }
     return _rewardBgView;
}

- (UIView *)titleBgView{
    if (!_titleBgView) {
        _titleBgView = [[UIView alloc]init];
        _titleBgView.backgroundColor = [UIColor colorWithRed:207/255.0 green:63/255.0 blue:78/255.0 alpha:1.0];
    }
    return _titleBgView;
}

- (UIButton *)backButton{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage imageNamed:@"plv_btn_reward_backBtn"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)titleTabButton{
    if (!_titleTabButton) {
        _titleTabButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _titleTabButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];
        [_titleTabButton setTitle:@"积分打赏" forState:UIControlStateNormal];
        [_titleTabButton setTitleColor:[UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0] forState:UIControlStateNormal];
        
        UIView * lineView = [[UIView alloc]init];
        lineView.backgroundColor = [UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0];
        lineView.layer.cornerRadius = 1;
        [_titleTabButton addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.offset(0);
            make.centerX.offset(0);
            make.width.offset(64);
            make.height.offset(2);
        }];
    }
    return _titleTabButton;
}

- (UIView *)prizeBgView{
    if (!_prizeBgView) {
        _prizeBgView = [[UIView alloc]init];
    }
    return _prizeBgView;
}

- (CAGradientLayer *)prizeBgLayer{
    if (!_prizeBgLayer) {
        _prizeBgLayer = [CAGradientLayer layer];
        _prizeBgLayer.startPoint = CGPointMake(0.5, 0.35);
        _prizeBgLayer.endPoint = CGPointMake(0.5, 1);
        _prizeBgLayer.colors = @[(__bridge id)[UIColor colorWithRed:229/255.0 green:88/255.0 blue:95/255.0 alpha:1.0].CGColor, (__bridge id)[UIColor colorWithRed:186/255.0 green:54/255.0 blue:69/255.0 alpha:1.0].CGColor];
        _prizeBgLayer.locations = @[@(0), @(1.0f)];
    }
    return _prizeBgLayer;
}

- (UIImageView *)ribbonImageView{
    if (!_ribbonImageView) {
        _ribbonImageView = [[UIImageView alloc]init];
        _ribbonImageView.image = [UIImage imageNamed:@"plv_image_reward_ribbon"];
    }
    return _ribbonImageView;
}

- (UILabel *)pointsLabel{
    if (!_pointsLabel) {
        _pointsLabel = [[UILabel alloc]init];
        _pointsLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _pointsLabel.textColor = [UIColor colorWithRed:255/255.0 green:249/255.0 blue:196/255.0 alpha:1.0];
        _pointsLabel.text = @"我的积分：0";
        _pointsLabel.textAlignment = NSTextAlignmentRight;
    }
    return _pointsLabel;
}

- (UIScrollView *)prizeBgScrollView{
    if (!_prizeBgScrollView) {
        _prizeBgScrollView = [[UIScrollView alloc]init];
        _prizeBgScrollView.pagingEnabled = YES;
        _prizeBgScrollView.showsVerticalScrollIndicator = NO;
        _prizeBgScrollView.showsHorizontalScrollIndicator = NO;
        _prizeBgScrollView.delegate = self;
    }
    return _prizeBgScrollView;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc]init];
        _pageControl.numberOfPages = 5;
        _pageControl.currentPage = 0;
        _pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0];
        _pageControl.pageIndicatorTintColor = [UIColor colorWithRed:162/255.0 green:51/255.0 blue:62/255.0 alpha:1.0];
        _pageControl.hidesForSinglePage = YES;
        _pageControl.userInteractionEnabled = NO;
    }
    return _pageControl;
}

- (UIView *)numBgView{
    if (!_numBgView) {
        _numBgView = [[UIView alloc]init];
        _numBgView.backgroundColor = [UIColor colorWithRed:207/255.0 green:63/255.0 blue:78/255.0 alpha:1.0];
    }
    return _numBgView;
}

- (UIScrollView *)numButtonScrollView{
    if (!_numButtonScrollView) {
        _numButtonScrollView = [[UIScrollView alloc]init];
        _numButtonScrollView.showsVerticalScrollIndicator = NO;
        _numButtonScrollView.showsHorizontalScrollIndicator = NO;
    }
    return _numButtonScrollView;
}

- (UIButton *)sendButton{
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor colorWithRed:198/255.0 green:64/255.0 blue:76/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_sendButton setBackgroundImage:[PLVColorUtil createImageWithColor:[UIColor colorWithRed:255/255.0 green:248/255.0 blue:198/255.0 alpha:1.0]] forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _sendButton.layer.masksToBounds = YES;
        _sendButton.layer.cornerRadius = 12;
    }
    return _sendButton;
}


#pragma mark - [ Delegate ]
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    int pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.pageControl.currentPage = pageNumber;
}


#pragma mark - [ Event ]
- (void)bgViewTapAction:(UITapGestureRecognizer *)tap{
    [self hide];
}

- (void)backButtonAction:(UIButton *)button{
    [self hide];
}

- (void)sendButtonAction:(UIButton *)button{
    NSInteger num = [self.curSelectedNumButton.titleLabel.text integerValue];
    if ([self.delegate respondsToSelector:@selector(plvGiveRewardView:goodsModel:num:)]) {
        [self.delegate plvGiveRewardView:self goodsModel:self.curSelectedPrizeModel num:num];
    }
    [self hide];
}

- (void)numButtonAction:(UIButton *)button{
    if (button.selected) { return; }
    
    self.curSelectedNumButton.selected = NO;
    self.curSelectedNumButton.userInteractionEnabled = YES;
    self.curSelectedNumButton = button;
    self.curSelectedNumButton.selected = YES;
    self.curSelectedNumButton.userInteractionEnabled = NO;
}

- (void)prizeButtonAction:(PLVGiveRewardGoodsButton *)button{
    if (button.selected) { return; }
    
    self.curSelectedPrizeButton.selected = NO;
    self.curSelectedPrizeButton.userInteractionEnabled = YES;
    self.curSelectedPrizeButton = button;
    self.curSelectedPrizeButton.selected = YES;
    self.curSelectedPrizeButton.userInteractionEnabled = NO;
    
    PLVRewardGoodsModel * model = self.modelArray[button.tag - 200];
    self.curSelectedPrizeModel = model;
}


#pragma mark - [ Public Methods ]
- (void)refreshGoods:(NSArray<PLVRewardGoodsModel *> *)goodsModelArray{
    if (goodsModelArray.count > 0) {
        [self prizeScrollviewRefreshGoods:goodsModelArray];
        double page = ceil(goodsModelArray.count / 3.0);
        self.pageControl.numberOfPages = page;
        self.prizeBgScrollView.contentSize = CGSizeMake(SCREEN_WIDTH * page, 130);
        self.modelArray = goodsModelArray;
    }
}

- (void)refreshUserPoint:(NSString *)userPoint{
    if (userPoint && [userPoint isKindOfClass:NSString.class] && userPoint.length > 0) {
        self.pointsLabel.text = [NSString stringWithFormat:@"我的积分：%@ %@",userPoint,self.pointUnit];
    }
}

- (void)showOnView:(UIView *)superView{
    self.oriUnableRotate = [PLVLiveVideoConfig sharedInstance].unableRotate;
    [PLVLiveVideoConfig sharedInstance].unableRotate = YES;
    
    self.frame = superView.bounds;
    [superView addSubview:self];
    [self layoutIfNeeded];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 1;
        [weakSelf.rewardBgView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.offset(0);
        }];
        [weakSelf layoutIfNeeded];
    } completion:nil];
}

@end
