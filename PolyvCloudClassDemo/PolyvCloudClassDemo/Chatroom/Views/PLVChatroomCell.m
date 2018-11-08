//
//  PLVChatroomCell.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 24/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVChatroomCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "PLVEmojiModel.h"
#import "PLVUtils.h"
#import "PLVLabel.h"
#import "PLVPhotoBrowser.h"

#define DEFAULT_CELL_HEIGHT 44.0
#define CHAT_TEXT_FONT [UIFont systemFontOfSize:14.0]

@interface PLVChatroomCell ()

@property (nonatomic, assign) CGFloat height;

- (CGSize)autoCalculateSize:(CGSize)size attributedContent:(NSAttributedString *)attributedContent;
- (void)drawCornerRadiusWithView:(UIView *)view size:(CGSize)size roundingCorners:(UIRectCorner)corners;

@end

@implementation PLVChatroomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (instancetype)initWithReuseIdentifier:(NSString *)indentifier {
    self.height = DEFAULT_CELL_HEIGHT;
    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indentifier];
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    return self;
}

- (CGFloat)calculateCellHeightWithContent:(NSString *)content {
    return DEFAULT_CELL_HEIGHT;
}

- (void)drawCornerRadiusWithView:(UIView *)view size:(CGSize)size roundingCorners:(UIRectCorner)corners {
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
}

/// 计算属性字符串文本的宽或高
- (CGSize)autoCalculateSize:(CGSize)size attributedContent:(NSAttributedString *)attributedContent {
    CGRect rect = [attributedContent boundingRectWithSize:size
                                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  context:nil];
    return rect.size;
}

#pragma mark - test
+ (NSArray *)cellFromChatroom {
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
}
//+ (NSString *)indentifyWithModel:(PLVChatroomModel *)model;
//- (instancetype)initWithModel:(PLVChatroomModel *)model identifier:(NSString *)identifier{
//    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier]){
//
//    }
//}

@end

@interface PLVChatroomSpeakOwnCell ()

@property (nonatomic, strong) PLVLabel *messageLB;
@end

@implementation PLVChatroomSpeakOwnCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.messageLB = [[PLVLabel alloc] init];
        self.messageLB.numberOfLines = 0;
        self.messageLB.textColor = [UIColor whiteColor];
        self.messageLB.font = CHAT_TEXT_FONT;
        self.messageLB.backgroundColor = UIColorFromRGB(0x8CC152);
        self.messageLB.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [self addSubview:self.messageLB];
    }
    return self;
}

- (void)setSpeakContent:(NSString *)speakContent {
    _speakContent = speakContent;
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:speakContent font:CHAT_TEXT_FONT];
    self.messageLB.attributedText = attributedStr;
    CGSize newSize = [self.messageLB sizeThatFits:CGSizeMake(270, MAXFLOAT)];
    [self drawCornerRadiusWithView:self.messageLB size:newSize roundingCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft|UIRectCornerBottomRight];
    [self.messageLB mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(newSize);
        make.top.equalTo(self.mas_top).offset(10.0);
        make.right.equalTo(self.mas_right).offset(-10);
    }];
    
    self.height = newSize.height + 10;
}

- (CGFloat)calculateCellHeightWithContent:(NSString *)content {
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:content font:CHAT_TEXT_FONT];
    // -10 = 10(顶部间隔)-10(PLVLabel上内边距)-10(PLVLabel上内边距)
    return [self autoCalculateSize:CGSizeMake(270, MAXFLOAT) attributedContent:attributedStr].height - 10;
}

@end

@interface PLVChatroomSpeakOtherCell ()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *actorLB;
@property (nonatomic, strong) UILabel *nickNameLB;
@property (nonatomic, strong) PLVLabel *messageLB;
@end

@implementation PLVChatroomSpeakOtherCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 35, 35)];
        self.avatarView.layer.cornerRadius = 35.0/2;
        self.avatarView.layer.masksToBounds = YES;
        [self addSubview:self.avatarView];
        
        self.actorLB = [[UILabel alloc] init];
        self.actorLB.layer.cornerRadius = 9.0;
        self.actorLB.layer.masksToBounds = YES;
        self.actorLB.textColor = [UIColor whiteColor];
        self.actorLB.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium];
        self.actorLB.backgroundColor = UIColorFromRGB(0x2196F3);
        self.actorLB.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.actorLB];
        
        self.nickNameLB = [[UILabel alloc] init];
        self.nickNameLB.backgroundColor = [UIColor clearColor];
        self.nickNameLB.textColor = [UIColor colorWithWhite:135/255.0 alpha:1.0];
        self.nickNameLB.font = [UIFont systemFontOfSize:11.0];
        [self addSubview:self.nickNameLB];
        
        self.messageLB = [[PLVLabel alloc] init];
        self.messageLB.numberOfLines = 0;
        self.messageLB.font = CHAT_TEXT_FONT;
        self.messageLB.textColor = UIColorFromRGB(0x546E7A);
        self.messageLB.backgroundColor = [UIColor whiteColor];
        self.messageLB.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [self addSubview:self.messageLB];
        
        [self.actorLB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarView.mas_top);
            make.height.mas_equalTo(@(18));
            make.leading.equalTo(self.avatarView.mas_trailing).offset(10);
        }];
        [self.nickNameLB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarView.mas_top);
            make.height.mas_equalTo(@(18));
            make.leading.equalTo(self.actorLB.mas_trailing).offset(5);
        }];
    }
    return self;
}

- (void)setAvatar:(NSString *)avatar {
    _avatar = avatar;
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:avatar] placeholderImage:[UIImage imageNamed:@"plv_img_default_avatar"]];
}

- (void)setActor:(NSString *)actor {
    _actor = actor;
    if (actor) {
        _actorLB.text = actor;
        CGSize size = [_actorLB sizeThatFits:CGSizeMake(MAXFLOAT, 18)];
        [_actorLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(size.width+20, 18));
            make.top.equalTo(self.avatarView.mas_top);
            make.leading.equalTo(self.avatarView.mas_trailing).offset(10);
        }];
    }else {
        [_actorLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeZero);
            make.top.equalTo(self.avatarView.mas_top);
            make.leading.equalTo(self.avatarView.mas_trailing).offset(5);
        }];
    }
}

- (void)setNickName:(NSString *)nickName {
    _nickName = nickName;
    _nickNameLB.text = nickName;
}

/*! 聊天室内容转义问题（测试）
 NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithData:[content dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
 [attributedStr addAttribute:NSFontAttributeName value:contentLB.font range:NSMakeRange(0, attributedStr.length)];
 */
- (void)setSpeakContent:(NSString *)speakContent {
    _speakContent = speakContent;
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:speakContent font:CHAT_TEXT_FONT];
    self.messageLB.attributedText = attributedStr;
    CGSize newSize = [self.messageLB sizeThatFits:CGSizeMake(260, MAXFLOAT)];
    [self drawCornerRadiusWithView:self.messageLB size:newSize roundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopRight];
    [self.messageLB mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(newSize);
        make.top.equalTo(self.nickNameLB.mas_bottom).offset(5);
        make.leading.equalTo(self.avatarView.mas_trailing).offset(10);
    }];
    
    self.height = newSize.height + 33; //10+18+5
}

- (void)setActorTextColor:(UIColor *)actorTextColor {
    _actorTextColor = actorTextColor;
    if (actorTextColor) {
        _actorLB.textColor = actorTextColor;
    }
}

- (void)setActorBackgroundColor:(UIColor *)actorBackgroundColor {
    _actorBackgroundColor = actorBackgroundColor;
    if (actorBackgroundColor) {
        _actorLB.backgroundColor = actorBackgroundColor;
    }
}

- (CGFloat)calculateCellHeightWithContent:(NSString *)content {
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:content font:CHAT_TEXT_FONT];
    // +13 = 10+18+5(顶部间隔)-10(PLVLabel上内边距)-10(PLVLabel上内边距)
    return [self autoCalculateSize:CGSizeMake(260, MAXFLOAT) attributedContent:attributedStr].height + 13;
}

@end

@implementation PLVChatroomImageSendCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

@end

@interface PLVChatroomImageReceivedCell ()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *actorLB;
@property (nonatomic, strong) UILabel *nickNameLB;
@property (nonatomic, strong) UIImageView *imgView;

@property (nonatomic, strong) PLVPhotoBrowser *phototBrowser;
@end

@implementation PLVChatroomImageReceivedCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 35, 35)];
        self.avatarView.layer.cornerRadius = 35.0/2;
        self.avatarView.layer.masksToBounds = YES;
        [self addSubview:self.avatarView];
        
        self.actorLB = [[UILabel alloc] init];
        self.actorLB.layer.cornerRadius = 9.0;
        self.actorLB.layer.masksToBounds = YES;
        self.actorLB.textColor = [UIColor whiteColor];
        self.actorLB.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium];
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
        self.imgView.layer.cornerRadius = 5.0;
        self.imgView.layer.masksToBounds = YES;
        self.imgView.userInteractionEnabled = YES;
        [self addSubview:self.imgView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageView:)];
        [self.imgView addGestureRecognizer:tapGesture];
        
        [self.actorLB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarView.mas_top);
            make.height.mas_equalTo(@(18));
            make.leading.equalTo(self.avatarView.mas_trailing).offset(10);
        }];
        [self.nickNameLB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.avatarView.mas_top);
            make.height.mas_equalTo(@(18));
            make.leading.equalTo(self.actorLB.mas_trailing).offset(5);
        }];
        [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(132, 132));
            make.top.equalTo(self.nickNameLB.mas_bottom).offset(5);
            make.leading.equalTo(self.avatarView.mas_trailing).offset(10);
        }];
        
        self.height = 165; // 10+18+5+132
        self.phototBrowser = [PLVPhotoBrowser new];
    }
    return self;
}

- (void)setAvatar:(NSString *)avatar {
    _avatar = avatar;
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:avatar] placeholderImage:[UIImage imageNamed:@"plv_img_default_avatar"]];
}

- (void)setActor:(NSString *)actor {
    _actor = actor;
    if (actor) {
        _actorLB.text = actor;
        CGSize size = [_actorLB sizeThatFits:CGSizeMake(MAXFLOAT, 18)];
        [_actorLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(size.width+20, 18));
            make.top.equalTo(self.avatarView.mas_top);
            make.leading.equalTo(self.avatarView.mas_trailing).offset(10);
        }];
    }else {
        [_actorLB mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeZero);
            make.top.equalTo(self.avatarView.mas_top);
            make.leading.equalTo(self.avatarView.mas_trailing).offset(5);
        }];
    }
}

- (void)setNickName:(NSString *)nickName {
    _nickName = nickName;
    _nickNameLB.text = nickName;
}

- (void)setImgUrl:(NSString *)imgUrl {
    _imgUrl = imgUrl;
    if (!imgUrl) return;
    
    __weak typeof(self)weakSelf = self;
    if (CGSizeEqualToSize(self.imageViewSize, CGSizeZero)) { // 兼容无 size 数据
        [_imgView sd_setImageWithURL:[NSURL URLWithString:imgUrl] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error) {
                NSLog(@"image error:%@",error);
            }else {
                //NSLog(@"image size:%@",NSStringFromCGSize(image.size));
                if (image.size.width > 132 || image.size.height > 132) {
                    weakSelf.imgView.contentMode = UIViewContentModeScaleAspectFit;
                }else {
                    weakSelf.imgView.contentMode = UIViewContentModeCenter;
                }
            }
        }];
    }else { // 有 size 数据
        [_imgView sd_setImageWithURL:[NSURL URLWithString:imgUrl]];
        self.imgView.contentMode = UIViewContentModeScaleAspectFill;
        [self.imgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(self.imageViewSize);
            make.top.equalTo(self.nickNameLB.mas_bottom).offset(5);
            make.leading.equalTo(self.avatarView.mas_trailing).offset(10);
        }];
    }
}

- (void)setImageViewSize:(CGSize)imageViewSize {
    _imageViewSize = imageViewSize;
    self.height = imageViewSize.height + 33;
}

- (void)setActorTextColor:(UIColor *)actorTextColor {
    _actorTextColor = actorTextColor;
    if (actorTextColor) {
        _actorLB.textColor = actorTextColor;
    }
}

- (void)setActorBackgroundColor:(UIColor *)actorBackgroundColor {
    _actorBackgroundColor = actorBackgroundColor;
    if (actorBackgroundColor) {
        _actorLB.backgroundColor = actorBackgroundColor;
    }
}

- (CGFloat)calculateCellHeightWithContent:(NSString *)content {
    //return 165; // equal to self.height, 10+18+5+132
    if (CGSizeEqualToSize(self.imageViewSize, CGSizeZero)) {
        return 165;
    }else {
        return self.imageViewSize.height + 33;
    }
}

#pragma mark Private

- (void)tapImageView:(UIGestureRecognizer *)sender {
    UIImageView *imageView = (UIImageView *)sender.view;
    [self.phototBrowser scaleImageViewToFullScreen:imageView];
}

@end

@interface PLVChatroomFlowerCell ()

@property (nonatomic, strong) UILabel *contentLB;
@end

@implementation PLVChatroomFlowerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentLB = [[UILabel alloc] init];
        self.contentLB.backgroundColor = [UIColor clearColor];
        self.contentLB.textColor = [UIColor colorWithWhite:135/255.0 alpha:1.0];
        self.contentLB.font = [UIFont systemFontOfSize:12.0];
        self.contentLB.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.contentLB];
        
        UIImage *flower = [UIImage imageNamed:@"plv_img_flower"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[PLVUtils imageRotatedByDegrees:flower deg:30]];
        [self addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(30, 30));
            make.leading.equalTo(self.contentLB.mas_trailing);
            make.centerY.equalTo(self.mas_centerY);
        }];
    }
    return self;
}

- (void)setContent:(NSString *)content {
    _content = content;
    self.contentLB.text = content;
    [self.contentLB mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(17);
        make.width.lessThanOrEqualTo(@(250));
        make.centerY.equalTo(self.mas_centerY);
        make.centerX.equalTo(self.mas_centerX).offset(-15);
    }];
}

@end

@interface PLVChatroomSystemCell ()

@property (nonatomic, strong) UILabel *contentLB;
@end

@implementation PLVChatroomSystemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentLB = [[UILabel alloc] init];
        self.contentLB.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        self.contentLB.layer.cornerRadius = 4.0;
        self.contentLB.layer.masksToBounds = YES;
        self.contentLB.textColor = [UIColor whiteColor];
        self.contentLB.font = [UIFont systemFontOfSize:12.0];
        self.contentLB.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.contentLB];
        [self.contentLB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.height.mas_equalTo(24);
            make.width.greaterThanOrEqualTo(@(80));
            make.width.lessThanOrEqualTo(self.mas_width);
        }];
    }
    return self;
}

- (void)setContent:(NSString *)content {
    _content = content;
    self.contentLB.text = content;
    CGSize size = [self.contentLB sizeThatFits:CGSizeMake(MAXFLOAT, 24)];
    [self.contentLB mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(size.width+20, 24));
        make.width.greaterThanOrEqualTo(@(80));
        make.width.lessThanOrEqualTo(self.mas_width);
    }];
}

@end

@implementation PLVChatroomTimeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

@end
