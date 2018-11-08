//
//  PLVChatroomModel.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 24/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVChatroomModel.h"
#import "PLVChatroomManager.h"
#import "PLVUtils.h"

@interface PLVChatroomModel ()

@property (nonatomic, assign) BOOL teacher;
@property (nonatomic, strong) NSString *msgId;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, assign) PLVChatroomModelType type;
@property (nonatomic, assign) PLVChatroomUserType userType;

@property (nonatomic, strong) NSString *content;

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *actor;
@property (nonatomic, strong) NSString *speakContent;
// 头衔自定义颜色
@property (nonatomic, strong) UIColor *actorTextColor;
@property (nonatomic, strong) UIColor *actorBackgroundColor;

/// 图片资源信息
@property (nonatomic, strong) NSString *imgUrl;
@property (nonatomic, assign) CGSize imageViewSize;

@end

NSString *PLVNameStringWithChatroomModelType(PLVChatroomModelType type) {
    switch (type) {
        case PLVChatroomModelTypeSpeakOwn:
            return @"PLVChatroomModelTypeSpeakOwn";
        case PLVChatroomModelTypeSpeakOther:
            return @"PLVChatroomModelTypeSpeakOther";
        case PLVChatroomModelTypeImageSend:
            return @"PLVChatroomModelTypeImageSend";
        case PLVChatroomModelTypeImageReceived:
            return @"PLVChatroomModelTypeImageReceived";
        case PLVChatroomModelTypeFlower:
            return @"PLVChatroomModelTypeFlower";
        case PLVChatroomModelTypeSystem:
            return @"PLVChatroomModelTypeSystem";
        case PLVChatroomModelTypeTime:
            return @"PLVChatroomModelTypeTime";
        default:
            return @"PLVChatroomModelTypeNotDefine";
    }
}

@implementation PLVChatroomModel

#pragma mark - setter/getter

- (CGFloat)cellHeight {
    if (_cellHeight) {
        return _cellHeight;
    }else {
        switch (self.type) {
            case PLVChatroomModelTypeSpeakOwn: {
                PLVChatroomSpeakOwnCell *cell = [PLVChatroomSpeakOwnCell new];
                return [cell calculateCellHeightWithContent:self.speakContent];
            }
            case PLVChatroomModelTypeSpeakOther: {
                PLVChatroomSpeakOtherCell *cell = [PLVChatroomSpeakOtherCell new];
                return [cell calculateCellHeightWithContent:self.speakContent];
            }
            case PLVChatroomModelTypeImageReceived: {
                PLVChatroomImageReceivedCell *cell = [PLVChatroomImageReceivedCell new];
                return [cell calculateCellHeightWithContent:nil];
            }
            default:
                return [[PLVChatroomCell new] calculateCellHeightWithContent:nil];
        }
    }
}

#pragma mark - init

+ (instancetype)modelWithObject:(PLVSocketChatRoomObject *)object {
    PLVChatroomModel *model = [PLVChatroomModel new];
    switch (object.eventType) {
        case PLVSocketChatRoomEventType_LOGIN: {
            model.type = PLVChatroomModelTypeSystem;
            NSString *nickName = object.jsonDict[PLVSocketIOChatRoom_LOGIN_userKey][PLVSocketIOChatRoomUserNickKey];
            model.content = [NSString stringWithFormat:@"欢迎 %@ 加入",nickName];
        } break;
        case PLVSocketChatRoomEventType_SPEAK: {
            NSArray *speakValues = object.jsonDict[@"values"];
            if (object.isLocalMessage) { // 本地发言
                model.type = PLVChatroomModelTypeSpeakOwn;
                model.speakContent = speakValues.firstObject;
            }else {
                NSDictionary *user = object.jsonDict[@"user"];
                NSString *status = object.jsonDict[@"status"];
                if (status) {  // 单播消息
                    if ([status isEqualToString:@"censor"]) { // 聊天室审核
                    }else if ([status isEqualToString:@"error"]) { // 严禁词
                        model.type = PLVChatroomModelTypeSystem;
                        model.content = object.jsonDict[@"message"];
                    }
                }else if (user) { // 用户发言信息
                    model.msgId = object.jsonDict[@"id"];
                    model.speakContent = speakValues.firstObject;
                    [model handleUserInfomationWithUserInfo:user];
                    // 过滤掉自己的消息（开启聊天室审核后，服务器会广播所有审核后的消息，包含自己发送的消息）
                    NSString *userId = [PLVChatroomManager sharedManager].socketUser.userId;
                    if ([model.userId isEqualToString:userId]) {
                        model.type = PLVChatroomModelTypeNotDefine;
                    }else {
                        model.type = PLVChatroomModelTypeSpeakOther;
                    }
                }
            }
        } break;
        case PLVSocketChatRoomEventType_CHAT_IMG: {
            if (object.isLocalMessage) {
                model.type = PLVChatroomModelTypeImageSend;
            }else {
                model.type = PLVChatroomModelTypeImageReceived;
                model.msgId = object.jsonDict[@"id"];
                NSDictionary *content = [object.jsonDict[@"values"] firstObject];
                model.imgUrl = content[@"uploadImgUrl"];
                NSDictionary *imgSize = content[@"size"];
                if (imgSize) {
                    [model calculateImageViewSizeWithImageSize:CGSizeMake([imgSize[@"width"] floatValue], [imgSize[@"height"] floatValue])];
                }
                if ([model.imgUrl hasPrefix:@"http:"]) {
                    model.imgUrl = [model.imgUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
                }
                [model handleUserInfomationWithUserInfo:object.jsonDict[@"user"]];
            }
        } break;
        case PLVSocketChatRoomEventType_S_QUESTION: {
            if (object.isLocalMessage) {
                model.type = PLVChatroomModelTypeSpeakOwn;
                model.speakContent = object.jsonDict[@"content"];
            }
        } break;
        case PLVSocketChatRoomEventType_T_ANSWER:{
            NSString *status = object.jsonDict[@"status"];
            NSDictionary *user = object.jsonDict[@"user"];
            NSString *studentUserId = object.jsonDict[@"s_userId"];
            NSString *userId = [PLVChatroomManager sharedManager].socketUser.userId;
            if (status) {  // 广播消息（如讲师发送严禁词事件）
            }else if (([studentUserId isEqualToString:userId] && user) || object.isLocalMessage) {
                model.type = PLVChatroomModelTypeSpeakOther;
                [model handleUserInfomationWithUserInfo:user];
                model.speakContent = object.jsonDict[@"content"];
            }
        } break;
        case PLVSocketChatRoomEventType_LIKES: {
            model.type = PLVChatroomModelTypeFlower;
            NSString *nickName = object.jsonDict[PLVSocketIOChatRoom_LIKES_nick];
            model.content = [NSString stringWithFormat:@"%@ 赠送了 鲜花",nickName];
        } break;
        default:
            model.type = PLVChatroomModelTypeNotDefine;
            break;
    }
    
    return model;
}

- (PLVChatroomCell *)cellFromModelWithTableView:(UITableView *)tableView {
    NSString *indentifier = PLVNameStringWithChatroomModelType(self.type);
    PLVChatroomCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
    switch (self.type) {
        case PLVChatroomModelTypeSpeakOwn: {
            if (!cell) {
                cell = [[PLVChatroomSpeakOwnCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomSpeakOwnCell *)cell setSpeakContent:self.speakContent];
        } break;
        case PLVChatroomModelTypeSpeakOther: {
            if (!cell) {
                cell = [[PLVChatroomSpeakOtherCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomSpeakOtherCell *)cell setActor:self.actor];
            [(PLVChatroomSpeakOtherCell *)cell setAvatar:self.avatar];
            [(PLVChatroomSpeakOtherCell *)cell setNickName:self.nickName];
            [(PLVChatroomSpeakOtherCell *)cell setSpeakContent:self.speakContent];
            [(PLVChatroomSpeakOtherCell *)cell setActorTextColor:self.actorTextColor];
            [(PLVChatroomSpeakOtherCell *)cell setActorBackgroundColor:self.actorBackgroundColor];
        } break;
        case PLVChatroomModelTypeImageReceived: {
            if (!cell) {
                cell = [[PLVChatroomImageReceivedCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomImageReceivedCell *)cell setAvatar:self.avatar];
            [(PLVChatroomImageReceivedCell *)cell setActor:self.actor];
            [(PLVChatroomImageReceivedCell *)cell setNickName:self.nickName];
            if (!CGSizeEqualToSize(self.imageViewSize, CGSizeZero)) {
                [(PLVChatroomImageReceivedCell *)cell setImageViewSize:self.imageViewSize];
            }
            [(PLVChatroomImageReceivedCell *)cell setImgUrl:self.imgUrl];
            [(PLVChatroomImageReceivedCell *)cell setActorTextColor:self.actorTextColor];
            [(PLVChatroomImageReceivedCell *)cell setActorBackgroundColor:self.actorBackgroundColor];
        } break;
        case PLVChatroomModelTypeFlower: {
            if (!cell) {
                cell = [[PLVChatroomFlowerCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomFlowerCell *)cell setContent:self.content];
        } break;
        case PLVChatroomModelTypeSystem: {
            if (!cell) {
                cell = [[PLVChatroomSystemCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomSystemCell *)cell setContent:self.content];
        } break;
        default: {
            if (!cell)
            cell = [[PLVChatroomCell alloc] initWithReuseIdentifier:indentifier];
        } break;
    }
    self.cellHeight = cell.height;
    
    return cell;
}

- (void)calculateImageViewSizeWithImageSize:(CGSize)size {
    CGFloat x = size.width / size.height;
    if (x == 1) {   // 方图
        if (size.width < 50) {
            self.imageViewSize = CGSizeMake(50, 50);
        }else if (size.width > 132) {
            self.imageViewSize = CGSizeMake(132, 132);
        }else {
            self.imageViewSize = CGSizeMake(size.width, size.width);
        }
    }else if (x < 1) { // 竖图
        CGFloat width = 132 * x;
        if (width < 50) {
            width = 50;
        }
        self.imageViewSize = CGSizeMake(width, 132);
    }else {  // 横图
        CGFloat height = 132 / x;
        if (height < 50) {
            height = 50;
        }
        self.imageViewSize = CGSizeMake(132, height);
    }
}

#pragma mark - private methods

/* -- 返回用户头衔，规则如下：
 1. 消息中存在 actor(头衔) 字段，按照 actor显示
 2. 不存在 actor时按照有身份用户对应中文类型显示
 3. 不存在 actor且无身份时不显示头衔
 */
- (void)handleUserInfomationWithUserInfo:(NSDictionary *)userInfo {
    self.userId = [NSString stringWithFormat:@"%@",userInfo[@"userId"]];
    self.nickName = userInfo[PLVSocketIOChatRoomUserNickKey];
    NSString *userType = userInfo[PLVSocketIOChatRoomUserUserTypeKey];
    if ([userType isEqualToString:@"teacher"]) {
        self.userType = PLVChatroomUserTypeTeacher;
        self.teacher = YES;
        self.actor = @"讲师";
    }else if ([userType isEqualToString:@"manager"]) {
        self.userType = PLVChatroomUserTypeManager;
        self.teacher = YES;
        self.actor = @"管理员";
    }else if ([userType isEqualToString:@"assistant"]) {
        self.userType = PLVChatroomUserTypeAssistant;
        self.teacher = YES;
        self.actor = @"助教";
    }
    
    // 自定义参数
    NSDictionary *authorization = userInfo[@"authorization"];
    NSString *actor = userInfo[@"actor"];
    if (authorization) {
        self.actor = authorization[@"actor"];
        self.actorTextColor = [PLVUtils colorFromHexString:authorization[@"fColor"]];
        self.actorBackgroundColor = [PLVUtils colorFromHexString:authorization[@"bgColor"]];
    }else if (actor && actor.length) {
        self.actor = actor;
    }

    NSString *avatar = userInfo[PLVSocketIOChatRoomUserPicKey];
    // 处理"//"类型开头的地址和 HTTP 协议地址为 HTTPS
    if ([avatar hasPrefix:@"//"]) {
        self.avatar = [@"https:" stringByAppendingString:avatar];
    }else if ([avatar hasPrefix:@"http:"]) {
        self.avatar = [avatar stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    }else {
        self.avatar = avatar;
    }
}

@end
