//
//  PLVChatModel.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/31.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatModel.h"
#import "PLVEmojiManager.h"
#import "PCCUtils.h"

@implementation PLVChatUser

/* -- 返回用户头衔，规则如下：
 1. 消息中存在 actor(头衔) 字段，按照 actor显示
 2. 不存在 actor时按照有身份用户对应中文类型显示
 3. 不存在 actor且无身份时不显示头衔
 */
- (instancetype)initWithUserInfo:(NSDictionary *)userInfo {
    if (!userInfo || [userInfo isKindOfClass:[NSNull class]]) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.userId = [NSString stringWithFormat:@"%@",userInfo[@"userId"]];
        self.nickName = [NSString stringWithFormat:@"%@",userInfo[@"nick"]];
        NSString *userType = userInfo[@"userType"];
        if ([userType isEqualToString:@"teacher"]) {
            self.userType = PLVChatUserTypeTeacher;
            self.actor = @"讲师";
        }else if ([userType isEqualToString:@"manager"]) {
            self.userType = PLVChatUserTypeManager;
            self.actor = @"管理员";
        }else if ([userType isEqualToString:@"assistant"]) {
            self.userType = PLVChatUserTypeAssistant;
            self.actor = @"助教";
        }else if ([userType isEqualToString:@"student"]) {
            self.userType = PLVChatUserTypeStudent;
        }else if ([userType isEqualToString:@"slice"]) {
            self.userType = PLVChatUserTypeSlice;
        }else {
            self.userType = PLVChatUserTypeUnknown;
        }
        
        self.guest = [userType isEqualToString:@"guest"];
        
        // 自定义参数
        NSDictionary *authorization = userInfo[@"authorization"];
        NSString *actor = userInfo[@"actor"];
        if (authorization) {
            self.actor = authorization[@"actor"];
            self.actorTextColor = [PCCUtils colorFromHexString:authorization[@"fColor"]];
            self.actorBackgroundColor = [PCCUtils colorFromHexString:authorization[@"bgColor"]];
        }else if (actor && actor.length) {
            self.actor = actor;
        }
        
        self.avatar = userInfo[@"pic"];
        // 处理"//"类型开头的地址为 HTTPS
        if ([self.avatar hasPrefix:@"//"]) {
            self.avatar = [@"https:" stringByAppendingString:self.avatar];
        }
    }
    return self;
}

- (BOOL)isAudience {
    return (self.userType != PLVChatUserTypeTeacher
             && self.userType != PLVChatUserTypeAssistant
             && self.userType != PLVChatUserTypeManager);
}

@end

@implementation PLVChatImageContent

- (instancetype)initWithImage:(id)image imgId:(NSString *)imgId size:(CGSize)size {
    self = [super init];
    if (self) {
        self.imgId = imgId;
        if ([image isKindOfClass:[NSString class]]) {
            self.url = (NSString *)image;
            if ([(NSString *)image hasPrefix:@"http:"]) {
                self.url = [(NSString *)image stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
            }
        } else if ([image isKindOfClass:[UIImage class]]) {
            self.image = (UIImage *)image;
        }
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            [self calculateImageViewSizeWithImageSize:size];
        }
    }
    return self;
}

- (void)calculateImageViewSizeWithImageSize:(CGSize)size {
    CGFloat x = size.width / size.height;
    if (x == 1) {   // 方图
        if (size.width < 50) {
            self.size = CGSizeMake(50, 50);
        }else if (size.width > 132) {
            self.size = CGSizeMake(132, 132);
        }else {
            self.size = CGSizeMake(size.width, size.width);
        }
    }else if (x < 1) { // 竖图
        CGFloat width = 132 * x;
        if (width < 50) {
            width = 50;
        }
        self.size = CGSizeMake(width, 132);
    }else {  // 横图
        CGFloat height = 132 / x;
        if (height < 50) {
            height = 50;
        }
        self.size = CGSizeMake(132, height);
    }
}

@end

@implementation PLVChatModel
@synthesize cellHeight = _cellHeight;

- (void)setType:(PLVChatModelType)type {
    _type = type;
    self.localMessage = (type==PLVChatModelTypeMySpeak) || (type==PLVChatModelTypeMyImage);
}

- (CGFloat)cellHeight {
    if (_cellHeight == 0) {
        switch (self.type) {
            case PLVChatModelTypeMySpeak:
            case PLVChatModelTypeOtherSpeak:
                _cellHeight = [PLVChatSpeakCell cellHeightWithModel:self];
                break;
            case PLVChatModelTypeMyImage:
            case PLVChatModelTypeOtherImage:
                _cellHeight = [PLVChatImageCell cellHeightWithModel:self];
                break;
            default:
                break;
        }
    }
    return _cellHeight;
}

- (PLVBaseCell *)makeCellWithTableView:(UITableView *)tableView {
    PLVChatCell *cell;
    switch (self.type) {
        case PLVChatModelTypeMySpeak:
        case PLVChatModelTypeOtherSpeak: {
            cell = [tableView dequeueReusableCellWithIdentifier:PLVChatSpeakCell.identifier];
            if (!cell) {
                cell = [[PLVChatSpeakCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PLVChatSpeakCell.identifier];
            }
        } break;
        case PLVChatModelTypeMyImage:
        case PLVChatModelTypeOtherImage: {
            cell = [tableView dequeueReusableCellWithIdentifier:PLVChatImageCell.identifier];
            if (!cell) {
                cell = [[PLVChatImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PLVChatImageCell.identifier];
            }
        } break;
        default: {
        } break;
    }
    return cell;
}

@end
