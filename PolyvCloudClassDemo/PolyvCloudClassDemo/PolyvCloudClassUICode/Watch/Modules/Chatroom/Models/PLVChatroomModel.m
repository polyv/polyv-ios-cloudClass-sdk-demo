//
//  PLVChatroomModel.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 24/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVChatroomModel.h"
#import "PCCUtils.h"
#import "PLVChatroomManager.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>

@interface PLVChatroomModel ()

@property (nonatomic, assign) BOOL teacher;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, assign) PLVChatroomModelType type;
@property (nonatomic, assign) PLVChatroomUserType userType;

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *actor;
@property (nonatomic, strong) NSString *speakContent;
/// 头衔自定义颜色
@property (nonatomic, strong) UIColor *actorTextColor;
@property (nonatomic, strong) UIColor *actorBackgroundColor;

/// 图片资源信息
@property (nonatomic, strong) NSString *imgUrl;
@property (nonatomic, strong) NSString *imgId;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGSize imageViewSize;

/// 打赏信息
@property (nonatomic, assign) NSInteger goodNum;

/// 回复相关字段
@property (nonatomic, strong) NSString *quoteUserNickName;
@property (nonatomic, strong) NSString *quoteSpeakContent;
@property (nonatomic, strong) NSString *quoteImageUrl;
@property (nonatomic, assign) CGFloat quoteImageWidth;
@property (nonatomic, assign) CGFloat quoteImageHeight;

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
        case PLVChatroomModelTypeReward:
            return @"PLVChatroomModelTypeReward";
        case PLVChatroomModelTypeLike:
            return @"PLVChatroomModelTypeLike";
        case PLVChatroomModelTypeSystem:
            return @"PLVChatroomModelTypeSystem";
        case PLVChatroomModelTypeTime:
            return @"PLVChatroomModelTypeTime";
        case PLVChatroomModelTypeContentReply:
            return @"PLVChatroomModelTypeContentReply";
        default:
            return @"PLVChatroomModelTypeNotDefine";
    }
}

@implementation PLVChatroomModel

#pragma mark - setter/getter

- (CGFloat)cellHeight {
    if (!_cellHeight) {
        switch (self.type) {
            case PLVChatroomModelTypeSpeakOwn: {
                PLVChatroomSpeakOwnCell *cell = [PLVChatroomSpeakOwnCell new];
                _cellHeight = [cell calculateCellHeightWithContent:self.speakContent];
            } break;
            case PLVChatroomModelTypeSpeakOther: {
                static PLVChatroomSpeakOtherCell *speakOtherCell = nil;
                if (speakOtherCell == nil) {
                    speakOtherCell = [PLVChatroomSpeakOtherCell new];
                }
                _cellHeight = [speakOtherCell calculateCellHeightWithContent:self.speakContent];
            } break;
            case PLVChatroomModelTypeContentReply: {
                static PLVChatroomContentReplyCell *replyCell = nil;
                if (replyCell == nil) {
                    replyCell = [PLVChatroomContentReplyCell new];
                }
                _cellHeight = [replyCell calculateCellHeightWithModel:self];
            } break;
            case PLVChatroomModelTypeImageSend: {
                PLVChatroomImageSendCell *cell = [PLVChatroomImageSendCell new];
                cell.imageViewSize = self.imageViewSize;
                _cellHeight = [cell calculateCellHeightWithContent:nil];
            } break;
            case PLVChatroomModelTypeImageReceived: {
                static PLVChatroomImageReceivedCell *imageReceivedCell = nil;
                if (imageReceivedCell == nil) {
                    imageReceivedCell = [PLVChatroomImageReceivedCell new];
                }
                imageReceivedCell.imageViewSize = self.imageViewSize;
                _cellHeight = [imageReceivedCell calculateCellHeightWithContent:nil];
            } break;
            default:
                _cellHeight = [[PLVChatroomCell new] calculateCellHeightWithContent:nil];
                break;
        }
    }
    return _cellHeight;
}

#pragma mark - init

+ (instancetype)modelWithObject:(PLVSocketChatRoomObject *)object {
    PLVChatroomModel *model = [PLVChatroomModel new];
    model.localMessageModel = object.isLocalMessage;
    switch (object.eventType) {
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
                        //model.type = PLVChatroomModelTypeSystem;
                        model.type = PLVChatroomModelTypeProhibitedWord; //严禁词类型
                        model.content = object.jsonDict[@"message"];
                    }
                }else if (user) { // 用户发言信息
                    model.msgId = object.jsonDict[@"id"];
                    model.speakContent = speakValues.firstObject;
                    [model handleUserInfomationWithUserInfo:user];
                    
                    if (PLV_SafeDictionaryForDictKey(object.jsonDict, @"quote")) {
                        model.type = PLVChatroomModelTypeContentReply;
                        NSDictionary *quote = PLV_SafeDictionaryForDictKey(object.jsonDict, @"quote");
                        model.quoteUserNickName = quote[@"nick"];
                        model.quoteSpeakContent = quote[@"content"];
                        NSDictionary *imageDict = PLV_SafeDictionaryForDictKey(quote, @"image");
                        if (imageDict) {
                            model.quoteImageUrl = PLV_SafeStringForDictKey(imageDict, @"url");
                            model.quoteImageWidth = PLV_SafeFloatForDictKey(imageDict, @"width");
                            model.quoteImageHeight = PLV_SafeFloatForDictKey(imageDict, @"height");
                        }
                    } else {
                        model.type = PLVChatroomModelTypeSpeakOther;
                        
                        // 过滤掉自己的消息（开启聊天室审核后，服务器会广播所有审核后的消息，包含自己发送的消息）
                        PLVSocketObject *socketUser = [PLVChatroomManager sharedManager].socketUser;
                        if (socketUser) {
                            if ([model.userId isEqualToString:socketUser.userId]) {
                                model.type = PLVChatroomModelTypeSpeakOwnCensor;
                            }
                        }
                    }
                }
            }
        } break;
        case PLVSocketChatRoomEventType_CHAT_IMG: {
            // 初始化历史图片消息
            if ([object.jsonDict[@"user"][@"userId"] isEqualToString:
                 [PLVChatroomManager sharedManager].socketUser.userId]) {
                model.localMessageModel = YES;
                model.type = PLVChatroomModelTypeImageSend;
                NSDictionary *content = [object.jsonDict[@"values"] firstObject];
                NSDictionary *imgSize = content[@"size"];
                model.imgUrl = content[@"uploadImgUrl"];
                [model calculateImageViewSizeWithImageSize:CGSizeMake([imgSize[@"width"] floatValue], [imgSize[@"height"] floatValue])];
                if ([model.imgUrl hasPrefix:@"http:"]) {
                    model.imgUrl = [model.imgUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
                }
            } else if (model.localMessageModel) {
                // 自己刚发送的图片消息
                model.type = PLVChatroomModelTypeImageSend;
                model.uploadProgress = 0.0;
                NSArray *values = object.jsonDict[@"values"];
                model.imgId = values[0];
                model.image = values[1];
                [model calculateImageViewSizeWithImageSize:model.image.size];
            } else {
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
            NSString *nickName = [NSString stringWithFormat:@"%@",object.jsonDict[@"nick"]];
            model.content = [NSString stringWithFormat:@"%@ 赠送了 鲜花",nickName];
        } break;
        case PLVSocketChatRoomEventType_REWARD: {
            model.type = PLVChatroomModelTypeReward;
            NSDictionary * contentDict = object.jsonDict[@"content"];
            if ([contentDict isKindOfClass:NSDictionary.class]) {
                NSInteger goodNum = [NSString stringWithFormat:@"%@",contentDict[@"goodNum"]].integerValue;
                model.goodNum = goodNum;
                NSString * rewardContent = [NSString stringWithFormat:@"%@",contentDict[@"rewardContent"]];
                NSString * unick = [NSString stringWithFormat:@"%@",contentDict[@"unick"]];
                model.content = [NSString stringWithFormat:@"%@ 赠送了 %@",unick,rewardContent];
                NSString * goodImg = [NSString stringWithFormat:@"%@",contentDict[@"gimg"]];
                if ([goodImg hasPrefix:@"//"]) { goodImg = [@"https:" stringByAppendingString:goodImg]; }
                model.imgUrl = goodImg;
            }
        } break;
        default:
            model.type = PLVChatroomModelTypeNotDefine;
            break;
    }
    
    return model;
}

+ (instancetype)modelWithObject:(PLVSocketChatRoomObject *)object flower:(BOOL)flower {
    PLVChatroomModel *model = [PLVChatroomModel new];
    model.localMessageModel = object.localMessage;
    if (flower) {
        model.type = PLVChatroomModelTypeFlower;
        NSString *nickName = [NSString stringWithFormat:@"%@",object.jsonDict[@"nick"]];
        model.content = [NSString stringWithFormat:@"%@ 赠送了 鲜花", nickName];
    } else {
        model.type = PLVChatroomModelTypeLike;
        NSString *nickName = [NSString stringWithFormat:@"%@",object.jsonDict[@"nick"]];
        model.content = [NSString stringWithFormat:@"%@ 觉得主持人讲得很棒", nickName];
    }
    return model;
}

- (PLVChatroomCell *)cellFromModelWithTableView:(UITableView *)tableView {
    NSString *indentifier = PLVNameStringWithChatroomModelType(self.type);
    PLVChatroomCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
    switch (self.type) {
        case PLVChatroomModelTypeSpeakOwn:
        case PLVChatroomModelTypeSpeakOwnCensor: {
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
            [(PLVChatroomSpeakOtherCell *)cell setActorTextColor:self.actorTextColor];
            [(PLVChatroomSpeakOtherCell *)cell setActorBackgroundColor:self.actorBackgroundColor];
            [(PLVChatroomSpeakOtherCell *)cell setSpeakContent:self.speakContent admin:self.isTeacher];
        } break;
        case PLVChatroomModelTypeImageSend: {
            if (!cell) {
                cell = [[PLVChatroomImageSendCell alloc] initWithReuseIdentifier:indentifier];
            }
            ((PLVChatroomImageSendCell *)cell).imgId = self.imgId;
            if (!CGSizeEqualToSize(self.imageViewSize, CGSizeZero)) {
                [(PLVChatroomImageSendCell *)cell setImageViewSize:self.imageViewSize];
            }
            if (!self.imgUrl) {
                [(PLVChatroomImageSendCell *)cell uploadProgress:self.uploadFail ? -1.0 : self.uploadProgress];
                [(PLVChatroomImageSendCell *)cell setImage:self.image];
            } else {
                [(PLVChatroomImageSendCell *)cell setImgUrl:self.imgUrl];
            }
            ((PLVChatroomImageSendCell *)cell).refreshBtn.hidden = !self.uploadFail;
            ((PLVChatroomImageSendCell *)cell).refreshBtn.enabled = YES;
            [(PLVChatroomImageSendCell *)cell checkFail:self.checkFail];
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
        case PLVChatroomModelTypeReward: {
            if (!cell) {
                cell = [[PLVChatroomRewardCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomRewardCell *)cell setContent:self.content];
            [(PLVChatroomRewardCell *)cell setImgUrl:self.imgUrl];
            [(PLVChatroomRewardCell *)cell setGoodNum:self.goodNum];
        } break;
        case PLVChatroomModelTypeLike: {
            if (!cell) {
                cell = [[PLVChatroomFlowerCell alloc] initWithReuseIdentifier:indentifier];
            }
            ((PLVChatroomFlowerCell *)cell).imgView.hidden = YES;
            [(PLVChatroomFlowerCell *)cell setContent:self.content];
        } break;
        case PLVChatroomModelTypeSystem: {
            if (!cell) {
                cell = [[PLVChatroomSystemCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomSystemCell *)cell setContent:self.content];
        } break;
        case PLVChatroomModelTypeContentReply: {
            if (!cell) {
                cell = [[PLVChatroomContentReplyCell alloc] initWithReuseIdentifier:indentifier];
            }
            [(PLVChatroomContentReplyCell *)cell setActor:self.actor];
            [(PLVChatroomContentReplyCell *)cell setAvatar:self.avatar];
            [(PLVChatroomContentReplyCell *)cell setNickName:self.nickName];
            [(PLVChatroomContentReplyCell *)cell setActorTextColor:self.actorTextColor];
            [(PLVChatroomContentReplyCell *)cell setActorBackgroundColor:self.actorBackgroundColor];
            [(PLVChatroomContentReplyCell *)cell setModel:self];
        } break;
        default: {
            if (!cell)
            cell = [[PLVChatroomCell alloc] initWithReuseIdentifier:indentifier];
        } break;
    }
    self.cellHeight = cell.height;
    
    return cell;
}

#pragma mark - private methods

- (void)calculateImageViewSizeWithImageSize:(CGSize)size {
    CGFloat x = size.width / size.height;
    if (isnan(x)){
        self.imageViewSize = CGSizeMake(100, 100);
    }else if (x == 1) {   // 方图
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

/* -- 返回用户头衔，规则如下：
 1. 消息中存在 actor(头衔) 字段，按照 actor显示
 2. 不存在 actor时按照有身份用户对应中文类型显示
 3. 不存在 actor且无身份时不显示头衔
 */
- (void)handleUserInfomationWithUserInfo:(NSDictionary *)userInfo {
    self.userId = [NSString stringWithFormat:@"%@",userInfo[@"userId"]];
    self.nickName = [NSString stringWithFormat:@"%@",userInfo[@"nick"]];
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
    } else if ([userType isEqualToString:@"guest"]) {
        self.userType = PLVChatroomUserTypeGuest;
        self.teacher = YES;
        self.actor = @"嘉宾";
    }
    
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

    NSString *avatar = userInfo[PLVSocketIOChatRoomUserPicKey];
    // 处理"//"类型开头的地址和 HTTP 协议地址为 HTTPS
    if ([avatar hasPrefix:@"//"]) {
        self.avatar = [@"https:" stringByAppendingString:avatar];
    }else {
        self.avatar = avatar;
    }
    // URL percent-Encoding，头像地址中含有中文字符问题
    self.avatar = [PLVFdUtil stringBySafeAddingPercentEncoding:self.avatar];
}

@end
