//
//  PLVGiveRewardGoodsButton.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVGiveRewardGoodsButton.h"

#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVGiveRewardGoodsButton ()

@property (nonatomic, strong) UIImageView * prizeImageView;
@property (nonatomic, strong) UILabel * prizeNameLabel;
@property (nonatomic, strong) UILabel * prizePointsLabel;

@end

@implementation PLVGiveRewardGoodsButton

#pragma mark - [ Init ]
- (instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI{
    self.layer.cornerRadius = 6;
    
    [self addSubview:self.prizeImageView];
    [self addSubview:self.prizeNameLabel];
    [self addSubview:self.prizePointsLabel];
    
    /// layout
    __weak typeof(self) weakSelf = self;
    [self.prizeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.offset(80);
        make.centerX.offset(0);
        make.top.offset(8);
    }];

    [self.prizeNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.mas_equalTo(weakSelf.prizeImageView.mas_bottom).offset(4);
        make.height.offset(12);
    }];
    
    [self.prizePointsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.mas_equalTo(weakSelf.prizeNameLabel.mas_bottom).offset(2);
    }];
}


#pragma mark - [ Public Methods ]
- (void)setModel:(PLVRewardGoodsModel *)model{
    if (model) {
        [self.prizeImageView sd_setImageWithURL: [NSURL URLWithString:model.goodImgFullURL]];
        self.prizeNameLabel.text = model.goodName;
        self.prizePointsLabel.text = [NSString stringWithFormat:@"%.0lf点",model.goodPrice];
    }
}


#pragma mark - [ Super Methods ]
- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:166/255.0 green:39/255.0 blue:50/255.0 alpha:1.0];
    }else{
        self.backgroundColor = [UIColor clearColor];
    }
}


#pragma mark - [ Private Methods ]
#pragma mark Getter
- (UIImageView *)prizeImageView{
    if (!_prizeImageView) {
        _prizeImageView = [[UIImageView alloc]init];
    }
    return _prizeImageView;
}

- (UILabel *)prizeNameLabel{
    if (!_prizeNameLabel) {
        _prizeNameLabel = [[UILabel alloc]init];
        _prizeNameLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _prizeNameLabel.textColor = [UIColor colorWithRed:255/255.0 green:249/255.0 blue:196/255.0 alpha:1.0];
        _prizeNameLabel.text = @"礼物";
    }
    return _prizeNameLabel;
}

- (UILabel *)prizePointsLabel{
    if (!_prizePointsLabel) {
        _prizePointsLabel = [[UILabel alloc]init];
        _prizePointsLabel.font = [UIFont fontWithName:@"PingFang SC" size:10];
        _prizePointsLabel.textColor = [UIColor colorWithRed:255/255.0 green:249/255.0 blue:196/255.0 alpha:1.0];
        _prizePointsLabel.text = @"0点";
    }
    return _prizePointsLabel;
}

@end


