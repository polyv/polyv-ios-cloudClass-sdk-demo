//
//  PLVChatroomKouCell.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/1/18.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatroomCustomKouCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "PCCUtils.h"

@interface PLVChatroomCustomKouCell ()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *actorLB;
@property (nonatomic, strong) UILabel *nickNameLB;
@property (nonatomic, strong) UIImageView *imgView;

@end

@implementation PLVChatroomCustomKouCell
@synthesize height = _height;
@synthesize modelDict = _modelDict;

#pragma mark - 必须实现的方法
/// 通过模型计算高度：固定值/计算值
- (CGFloat)calculateCellHeightWithModelDict:(NSDictionary *)modelDict {
    if (self.myself) {
        return 40.0;
    } else {
        return 54.0;
    }
}

#pragma mark 自定义数据解析
- (void)setModelDict:(NSDictionary *)modelDict {
    _modelDict = modelDict;
    
    // 解析模型数据
    NSInteger contentType = [modelDict[@"contentType"] integerValue];
    if (self.myself) {
        self.avatarView.hidden = YES;
        self.actorLB.hidden = YES;
        self.nickNameLB.hidden = YES;
        self.imgView.frame = CGRectMake(self.bounds.size.width - 30.0, 3.0, 20.0, 34.0);
        _height = 40.0;
    } else {
        self.avatarView.hidden = NO;
        self.actorLB.hidden = NO;
        self.nickNameLB.hidden = NO;
        
        self.avatarView.frame = CGRectMake(10.0, 10.0, 35.0, 35.0);
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:@"plv_img_default_avatar"]];
        
        __weak typeof(self) weakSelf = self;
        if (1) {
            self.actorLB.text = @"";
            CGSize size = [_actorLB sizeThatFits:CGSizeMake(MAXFLOAT, 18.0)];
            [self.actorLB mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(weakSelf.avatarView.mas_top);
                make.leading.equalTo(weakSelf.avatarView.mas_trailing).offset(10.0);
                make.size.mas_equalTo(CGSizeMake(size.width + 20.0, 18.0));
            }];
        } else {
            self.actorLB.text = nil;
            [self.actorLB mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.avatarView.mas_top);
                make.leading.equalTo(self.avatarView.mas_trailing).offset(5.0);
                make.size.mas_equalTo(CGSizeZero);
            }];
        }
        
        _nickNameLB.text = @"";
        [self.nickNameLB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakSelf.avatarView.mas_top);
            make.leading.equalTo(weakSelf.actorLB.mas_trailing).offset(5.0);
            make.height.mas_equalTo(@(18.0));
        }];
        
        [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakSelf.avatarView.mas_top).offset(20.0);
            make.leading.equalTo(self.avatarView.mas_trailing).offset(5.0);
            make.size.mas_equalTo(CGSizeMake(20.0, 34.0));
        }];
        _height = 54.0;
    }
    
    switch (contentType) {
        case 1: {
            self.imgView.image = [UIImage imageNamed:@"plv_kou1_img"];
        } break;
        case 2: {
            self.imgView.image = [UIImage imageNamed:@"plv_kou2_img"];
        } break;
        default:
            break;
    }
}

#pragma mark UI 样式自定义
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.avatarView = [[UIImageView alloc] init];
        self.avatarView.layer.cornerRadius = 35.0/2;
        self.avatarView.layer.masksToBounds = YES;
        [self addSubview:self.avatarView];
        
        self.actorLB = [[UILabel alloc] init];
        self.actorLB.layer.cornerRadius = 9.0;
        self.actorLB.layer.masksToBounds = YES;
        self.actorLB.textColor = [UIColor whiteColor];
        if (@available(iOS 8.2, *)) {
            self.actorLB.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium];
        } else {
            self.actorLB.font = [UIFont systemFontOfSize:10.0];
        }
        self.actorLB.backgroundColor = UIColorFromRGB(0x2196F3);
        self.actorLB.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.actorLB];
        
        self.nickNameLB = [[UILabel alloc] init];
        self.nickNameLB.backgroundColor = [UIColor clearColor];
        self.nickNameLB.textColor = [UIColor colorWithWhite:135/255.0 alpha:1.0];
        self.nickNameLB.font = [UIFont systemFontOfSize:11.0];
        [self addSubview:self.nickNameLB];
        
        self.imgView = [[UIImageView alloc] init];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        self.imgView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.imgView];
    }
    return self;
}

@end
