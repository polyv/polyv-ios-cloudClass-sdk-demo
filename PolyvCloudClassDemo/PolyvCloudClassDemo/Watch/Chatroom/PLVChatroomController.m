//
//  PLVChatroomController.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 23/08/2018.
//  Copyright © 2018 polyv. All rights reserved.
//

#import "PLVChatroomController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <PolyvFoundationSDK/PLVDateUtil.h>
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>
#import "PLVChatroomModel.h"
#import "PLVEmojiModel.h"
#import "PCCUtils.h"
#import "MarqueeLabel.h"
#import "PLVChatroomQueue.h"
#import "ZNavigationController.h"
#import "ZPickerController.h"
#import "PLVCameraViewController.h"

typedef NS_ENUM(NSInteger, PLVMarqueeViewType) {
    PLVMarqueeViewTypeMarquee     = 1,// 跑马灯公告
    PLVMarqueeViewTypeWelcome     = 2 // 欢迎语
};

@interface PLVMarqueeView : UIView

@property (nonatomic, strong) MarqueeLabel *marqueeLabe;

@end

@implementation PLVMarqueeView

- (void)loadSubViews:(PLVMarqueeViewType)type {
    if (type == PLVMarqueeViewTypeMarquee) {
        self.backgroundColor = [UIColor colorWithRed:57.0 / 255.0 green:56.0 / 255.0 blue:66.0 / 255.0 alpha:0.8];
        
        CGRect marqueeRect = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
        self.marqueeLabe = [[MarqueeLabel alloc] initWithFrame:marqueeRect duration:8.0 andFadeLength:0];
        self.marqueeLabe.textColor = [UIColor whiteColor];
        self.marqueeLabe.leadingBuffer = CGRectGetWidth(self.bounds);
        [self addSubview:self.marqueeLabe];
    } else {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithRed:253.0 / 255.0 green:248.0 / 255.0 blue:203.0 / 255.0 alpha:1.0];
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.borderWidth = 0.5;
        self.layer.cornerRadius = 5.0;
        
        CGFloat x = 0.0;
        CGRect marqueeRect = CGRectMake(x, 0.0, self.bounds.size.width - x * 2.0, self.bounds.size.height);
        self.marqueeLabe = [[MarqueeLabel alloc] initWithFrame:marqueeRect duration:1.5 andFadeLength:0];
        self.marqueeLabe.marqueeType = MLLeft;
        self.marqueeLabe.textAlignment = NSTextAlignmentCenter;
        self.marqueeLabe.textColor = [UIColor blackColor];
        self.marqueeLabe.leadingBuffer = 0.0;
        [self addSubview:self.marqueeLabe];
    }
}

@end

@interface PLVChatroomController () <UITableViewDelegate, UITableViewDataSource, PLVTextInputViewDelegate, PLVChatroomQueueDeleage, PLVChatroomImageSendCellDelegate, PLVCameraViewControllerDelegate, ZPickerControllerDelegate>

@property (nonatomic, assign) NSUInteger roomId;
@property (nonatomic, assign) PLVTextInputViewType type;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<PLVChatroomModel *> *chatroomData;
@property (nonatomic, strong) NSMutableArray<PLVChatroomModel *> *teacherData;

@property (nonatomic, strong) PLVMarqueeView *marqueeView;
@property (nonatomic, strong) PLVMarqueeView *welcomeView;
@property (nonatomic, strong) UIButton *showLatestMessageBtn;
@property (nonatomic, strong) PLVTextInputView *inputView;
@property (nonatomic, strong) PLVChatroomQueue *chatroomQueue;
@property (nonatomic, assign) NSUInteger likeCountOfHttp;//代码setter，getter likeCountOfHttp 时要保证线程安全
@property (nonatomic, assign) NSUInteger likeCountOfSocket;//代码setter，getter likeCountOfSocket 时要保证线程安全
@property (nonatomic, strong) NSTimer *likeTimer;
@property (nonatomic, assign) NSUInteger likeTiming;
@property (nonatomic, strong) PLVSocketChatRoomObject *likeSoctetObjectBySelf;

@property (nonatomic, assign) BOOL scrollsToBottom;  // default is YES.
@property (nonatomic, assign) BOOL showTeacherOnly;  // 只看讲师（有身份用户）数据
@property (nonatomic, assign) BOOL moreMessageHistory;
@property (nonatomic, assign) BOOL nickNameSetted;
@property (nonatomic, assign) NSUInteger startIndex;

@property (nonatomic, assign) NSUInteger onlineCount;

@end

static NSMutableSet *forbiddenUsers;

/// 生成一个teacher回答的伪数据
PLVSocketChatRoomObject *createTeacherAnswerObject() {
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObject:@"T_ANSWER" forKey:@"EVENT"];
    jsonDict[@"content"] = @"同学，您好！请问有什么问题吗？";
    jsonDict[@"user"] = @{@"nick" : @"讲师", @"pic" : @"https://livestatic.polyv.net/assets/images/teacher.png", @"userType" : @"teacher"};
    PLVSocketChatRoomObject *teacherAnswer = [PLVSocketChatRoomObject socketObjectWithJsonDict:jsonDict];
    teacherAnswer.localMessage = YES;
    return teacherAnswer;
}

@implementation PLVChatroomController {
    BOOL _loadMoreMessage;
    CGFloat _contentHeight;
}

#pragma mark - Permission
+ (BOOL)havePermissionToWatchLive:(NSUInteger)roomId {
    if (forbiddenUsers && forbiddenUsers.count) {
        return ![forbiddenUsers containsObject:@(roomId)];
    } else {
        return YES;
    }
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.chatroomData = [NSMutableArray array];
    self.teacherData = [NSMutableArray array];
    
    if (self.type == PLVTextInputViewTypePrivate) {
        PLVChatroomModel *model = [PLVChatroomModel modelWithObject:createTeacherAnswerObject()];
        [self.chatroomData addObject:model];
    } else {
        self.likeTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(pollHandleLikeCount) userInfo:nil repeats:YES];
        [self.likeTimer fire];
        
        self.chatroomQueue = [[PLVChatroomQueue alloc] init];
        self.chatroomQueue.delegate = self;
    }
}

- (void)dealloc {
    NSLog(@"-[%@ %@] type:%ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)self.type);
}

#pragma mark - alloc / init
+ (instancetype)chatroomWithType:(PLVTextInputViewType)type roomId:(NSUInteger)roomId frame:(CGRect)frame {
    return [[PLVChatroomController alloc] initChatroomWithType:type roomId:roomId frame:frame];
}

- (instancetype)initChatroomWithType:(PLVTextInputViewType)type roomId:(NSUInteger)roomId frame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.type = type;
        self.roomId = roomId;
        self.view.frame = frame;
        self.scrollsToBottom = YES;
        self.moreMessageHistory = YES;
        if (!forbiddenUsers) {
            forbiddenUsers = [NSMutableSet set];
        }
    }
    return self;
}

#pragma mark - public
- (void)clearResource {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.likeTimer) {
        [self.likeTimer invalidate];
        self.likeTimer = nil;
    }
    [self.chatroomQueue clearTimer];
}

- (void)loadSubViews {
    CGFloat h = 50.0;
    if (@available(iOS 11.0, *)) {
        CGRect rect = [UIApplication sharedApplication].delegate.window.bounds;
        CGRect layoutFrame = [UIApplication sharedApplication].delegate.window.safeAreaLayoutGuide.layoutFrame;
        h += (rect.size.height - layoutFrame.origin.y - layoutFrame.size.height);
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-h) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    [self.view addSubview:self.tableView];
    
    if (self.type < PLVTextInputViewTypePrivate) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshClickAction:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:refreshControl];
        [self refreshClickAction:refreshControl];
    }
    
    self.inputView = [[PLVTextInputView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-h, CGRectGetWidth(self.view.bounds), h)];
    self.inputView.delegate = self;
    [self.view addSubview:self.inputView];
    [self.inputView loadViews:self.type enableMore:NO];
    
    self.showLatestMessageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.showLatestMessageBtn.layer.cornerRadius = 15.0;
    self.showLatestMessageBtn.layer.masksToBounds = YES;
    [self.showLatestMessageBtn setTitle:@"有更多新消息，点击查看" forState:UIControlStateNormal];
    [self.showLatestMessageBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.showLatestMessageBtn.titleLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightMedium]];
    self.showLatestMessageBtn.backgroundColor = [UIColor colorWithRed:90/255.0 green:200/255.0 blue:250/255.0 alpha:1];
    self.showLatestMessageBtn.hidden = YES;
    [self.showLatestMessageBtn addTarget:self action:@selector(loadMoreMessageBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.showLatestMessageBtn];
    
    [self.showLatestMessageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(185, 30));
        make.bottom.equalTo(self.inputView.mas_top).offset(-10);
    }];
}

- (void)setSocketUser:(PLVSocketObject *)socketUser {
    _socketUser = socketUser;
    if (_type < PLVTextInputViewTypePrivate && !_nickNameSetted) {
        // 保证在公有聊天中设置过昵称后不再修改值
        _nickNameSetted = !socketUser.defaultUser;
        [_inputView nickNameSetted:!socketUser.defaultUser];
    }
}

- (void)setNickNameSetted:(BOOL)nickNameSetted {
    if (!_nickNameSetted && nickNameSetted) {
        [_inputView nickNameSetted:YES];
    }
    _nickNameSetted = nickNameSetted;
}

- (void)setSwitchInfo:(NSDictionary *)switchInfo {
    _switchInfo = switchInfo;
    if (self.type != PLVTextInputViewTypePrivate) {
        _closed = ![switchInfo[@"chat"] boolValue];
        if ([switchInfo[@"viewerSendImgEnabled"] boolValue]) { // 图片开关
            [self.inputView loadViews:self.type enableMore:YES];
        }
    }
}

#pragma mark - Action
- (void)refreshClickAction:(UIRefreshControl *)refreshControl {
    [refreshControl endRefreshing];
    const NSUInteger length = 21;
    if (self.moreMessageHistory) {
        __weak typeof(self)weakSelf = self;
        [PLVLiveVideoAPI requestChatRoomHistoryWithRoomId:self.roomId startIndex:self.startIndex endIndex:self.startIndex+length completion:^(NSArray *historyList) {
            [weakSelf handleChatroomMessageHistory:historyList];
            [weakSelf.tableView reloadData];
            if (weakSelf.startIndex) {
                [weakSelf.tableView scrollsToTop];
            }else {
                [weakSelf scrollsToBottom:YES];
            }
            if (historyList.count < length) {
                weakSelf.moreMessageHistory = NO;
            }else {
                weakSelf.startIndex += length - 1;
            }
        } failure:^(NSError *error) {
            [PCCUtils showChatroomMessage:@"历史记录获取失败！" addedToView:self.view];
        }];
    }else {
        [PCCUtils showChatroomMessage:@"没有更多数据了！" addedToView:self.view];
    }
}

- (void)loadMoreMessageBtnAction {
    [self scrollsToBottom:YES];
}

#pragma mark - addNewChatroomObject
- (void)addNewChatroomObject:(PLVSocketChatRoomObject *)object {
    switch (object.eventType) {
        case PLVSocketChatRoomEventType_LOGIN: {
            NSString *userId = object.jsonDict[PLVSocketIOChatRoom_LOGIN_userKey][PLVSocketIOChatRoomUserUserIdKey];
            [self.chatroomQueue addSocketChatRoomObject:object me:[userId isEqualToString:self.socketUser.userId]];
        } break;
        case PLVSocketChatRoomEventType_SET_NICK: {
            NSString *status = object.jsonDict[@"status"];
            if ([status isEqualToString:@"success"]) {// success：广播消息；
                if ([object.jsonDict[@"userId"] isEqualToString:self.socketUser.userId]) {
                    self.nickNameSetted = YES;
                    [self nickNameRenamed:object.jsonDict[@"nick"] success:YES message:object.jsonDict[@"message"]];
                }
            }else {// error：单播消息（设置出错）
                [self nickNameRenamed:nil success:NO message:object.jsonDict[@"message"]];
            }
        } break;
        case PLVSocketChatRoomEventType_CLOSEROOM: {
            _closed = [object.jsonDict[@"value"][@"closed"] boolValue];
            [PCCUtils showChatroomMessage:self.isClosed?@"房间已经关闭":@"房间已经开启" addedToView:self.view];
        } break;
        case PLVSocketChatRoomEventType_REMOVE_CONTENT: {
            [self removeModelWithSocketObject:object];
        } break;
        case PLVSocketChatRoomEventType_REMOVE_HISTORY: {
            [self clearAllData];
        } break;
        case PLVSocketChatRoomEventType_ADD_SHIELD: {
            if ([object.jsonDict[@"value"] isEqualToString:self.socketUser.clientIp]) {
                self.socketUser.banned = YES;
            }
        } break;
        case PLVSocketChatRoomEventType_REMOVE_SHIELD: {
            if ([object.jsonDict[@"value"] isEqualToString:self.socketUser.clientIp]) {
                self.socketUser.banned = NO;
            }
        } break;
        case PLVSocketChatRoomEventType_KICK: {
            if ([object.jsonDict[@"user"][@"userId"] isEqualToString:self.socketUser.userId]) {
                [forbiddenUsers addObject:@(self.roomId)];
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatroom:didOpenError:)]) {
                    [self.delegate chatroom:self didOpenError:PLVChatroomErrorCodeBeKicked];
                }
            }
        } break;
        case PLVSocketChatRoomEventType_CHAT_IMG: {
            NSArray *values = object.jsonDict[@"values"];
            BOOL result = [object.jsonDict[@"result"] boolValue];
            if (values) {
                PLVChatroomModel *findModel = nil;
                PLVChatroomImageSendCell *findSendCell = nil;
                for (PLVChatroomModel *model in self.chatroomData) {
                    if (model.type == PLVChatroomModelTypeImageSend && [model.imgId isEqualToString:values.firstObject[@"id"]]) {
                        findModel = model;
                        for (UITableViewCell *cell in self.tableView.visibleCells) {
                            if ([cell isKindOfClass:[PLVChatroomImageSendCell class]]) {
                                PLVChatroomImageSendCell *sendCell = (PLVChatroomImageSendCell *)cell;
                                if ([sendCell.imgId isEqualToString:values.firstObject[@"id"]]) {
                                    findSendCell = sendCell;
                                    break;
                                }
                            }
                        }
                    }
                }
                if (findModel != nil) {
                    if (!result) {
                        findModel.checkFail = YES;
                        if (findSendCell) {
                            [findSendCell checkFail:YES];
                        }
                        [PCCUtils showHUDWithTitle:nil detail:@"图片包含违法内容，审核失败！" view:[UIApplication sharedApplication].delegate.window];
                    }
                } else if (result) {
                    PLVChatroomModel *model = [PLVChatroomModel modelWithObject:object];
                    [self addModel:model];
                }
            }
        } break;
        case PLVSocketChatRoomEventType_LIKES: {
            if (![object.jsonDict[@"userId"] isEqualToString:self.socketUser.userId]) {
                [self handleLikeSocket:object];
            }
        } break;
        default: {
            PLVChatroomModel *model = [PLVChatroomModel modelWithObject:object];
            [self addModel:model];
        } break;
    }
    if (object.eventType==PLVSocketChatRoomEventType_LOGIN
        || object.eventType==PLVSocketChatRoomEventType_LOGOUT) {
        self.onlineCount = [object.jsonDict[@"onlineUserNumber"] unsignedIntegerValue];
    }
}

- (void)likeAnimation {
    CGRect frame = self.view.frame;
    NSArray *colors = @[UIColorFromRGB(0x9D86D2), UIColorFromRGB(0xF25268), UIColorFromRGB(0x5890FF), UIColorFromRGB(0xFCBC71)];
    
    CGFloat inputViewY = self.inputView.frame.origin.y;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plv_like.png"]];
    imageView.frame = CGRectMake(CGRectGetWidth(frame) - 50.0, inputViewY - 44.0, 40.0, 40.0);
    imageView.backgroundColor = colors[rand()%4];
    [imageView setContentMode:UIViewContentModeCenter];
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = 20.0;
    [self.view addSubview:imageView];
    
    CGFloat finishX = CGRectGetWidth(frame) - round(random() % 130);
    CGFloat speed = 1.0 / round(random() % 900) + 0.6;
    NSTimeInterval duration = 4.0 * speed;
    if (duration == INFINITY) {
        duration = 2.412346;
    }
    
    [UIView animateWithDuration:duration animations:^{
        imageView.alpha = 0.0;
        imageView.frame = CGRectMake(finishX, inputViewY - 200.0, 40.0, 40.0);
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

- (void)nickNameRenamed:(NSString *)newName success:(BOOL)success message:(NSString *)message {
    if (success) {
        [self.socketUser renameNickname:newName];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroom:nickNameRenamed:success:message:)]) {
        [self.delegate chatroom:self nickNameRenamed:newName success:success message:message];
    }
}

- (void)addModel:(PLVChatroomModel *)model {
    if (model.type == PLVChatroomModelTypeNotDefine)
        return;
    
    [self.chatroomData addObject:model];
    if (self.type < PLVTextInputViewTypePrivate) {
        if (model.isTeacher) {
            [self.teacherData addObject:model];
        }
        if (model.userType == PLVChatroomUserTypeManager) {
            if (model.speakContent) {// 可能为图片消息
                [self showMarqueeWithMessage:model.speakContent]; // 跑马灯公告
            }
        }
    }
    
    [self.tableView reloadData];
    
    if (model.type == PLVChatroomModelTypeSpeakOwn || self.scrollsToBottom) {
        [self scrollsToBottom:YES];
    } else if (self.type < PLVTextInputViewTypePrivate && !self.showTeacherOnly) {
        self.showLatestMessageBtn.hidden = NO;
    }
    
    if (self.type < PLVTextInputViewTypePrivate && model.speakContent) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatroom:didSendSpeakContent:)]) {
            [self.delegate chatroom:self didSendSpeakContent:model.speakContent];
        }
    }
}

- (void)removeModelWithSocketObject:(PLVSocketChatRoomObject *)object {
    NSString *removeMsgId = object.jsonDict[@"id"];
    for (int i=0; i<self.chatroomData.count; i++) {
        PLVChatroomModel *model = self.chatroomData[i];
        if (model.msgId && [removeMsgId isEqualToString:model.msgId]) {
            if (model.isTeacher) {
                [self.teacherData removeObject:model];
            }
            [self.chatroomData removeObject:model];
            if (self.showTeacherOnly) {
                [self.tableView reloadData];
            }else {
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            }
            break;
        }
    }
}

- (void)clearAllData {
    [self.chatroomData removeAllObjects];
    [self.teacherData removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark - private methods
- (BOOL)emitChatroomMessageWithObject:(PLVSocketChatRoomObject *)object {
    // 关闭房间、禁言只对聊天室发言有效
    if (self.type < PLVTextInputViewTypePrivate && object.eventType==PLVSocketChatRoomEventType_SPEAK) {
        if (self.isClosed) {
            [PCCUtils showChatroomMessage:[NSString stringWithFormat:@"消息发送失败！%ld", (long)PLVChatroomErrorCodeRoomClose] addedToView:self.view];
            return NO;
        }
        if (self.type < PLVTextInputViewTypePrivate && self.socketUser.isBanned) { // only log.
            NSLog(@"消息发送失败！%ld", (long)PLVChatroomErrorCodeBanned);
            return YES;
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroom:emitSocketObject:)]) {
        [self.delegate chatroom:self emitSocketObject:object];
        return YES;
    } else {
        return NO;
    }
}

- (void)scrollsToBottom:(BOOL)animated {
    NSIndexPath *lastIndexPath;
    if (self.type < PLVTextInputViewTypePrivate && self.showTeacherOnly) {
        lastIndexPath = [NSIndexPath indexPathForRow:self.teacherData.count-1 inSection:0];
    }else {
        lastIndexPath = [NSIndexPath indexPathForRow:self.chatroomData.count-1 inSection:0];
    }
    
    if (lastIndexPath.row < 1) {
        return;
    }
    _loadMoreMessage = YES;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:lastIndexPath];
    if (cell) {
        CGFloat offsetY = self.tableView.contentSize.height - CGRectGetHeight(self.tableView.bounds);
        if (offsetY < 0) {
            return;
        }
        [self.tableView setContentOffset:CGPointMake(0, offsetY) animated:animated];
    } else {
        [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)handleChatroomMessageHistory:(NSArray *)messageArr {
    if (messageArr && messageArr.count) {
        for (NSDictionary *messageDict in messageArr) {
            PLVSocketChatRoomObject *chatroomObject;
            NSString *msgSource = messageDict[@"msgSource"];
            if (msgSource) {
                if ([msgSource isEqualToString:@"chatImg"]) { // 图片
                    NSDictionary *imageDict = @{@"EVENT" : @"CHAT_IMG", @"values" : @[messageDict[@"content"]], @"user" : messageDict[@"user"]};
                    chatroomObject = [PLVSocketChatRoomObject socketObjectWithJsonDict:imageDict];
                } // redpaper（红包）、get_redpaper（领红包）
            } else {
                NSString *uid = [NSString stringWithFormat:@"%@",messageDict[@"user"][@"uid"]];
                if ([uid isEqualToString:@"1"] || [uid isEqualToString:@"1"]) {
                    // uid = 1，打赏消息；uid = 2，自定义消息
                }else { // speak message
                    NSDictionary *speakDict = @{@"EVENT" : @"SPEAK", @"values" : @[messageDict[@"content"]], @"user" : messageDict[@"user"]};
                    chatroomObject = [PLVSocketChatRoomObject socketObjectWithJsonDict:speakDict];
                }
            }
            if (chatroomObject) {
                PLVChatroomModel *model = [PLVChatroomModel modelWithObject:chatroomObject];
                [self.chatroomData insertObject:model atIndex:0];
                if (self.type < PLVTextInputViewTypePrivate && model.isTeacher) {
                    [self.teacherData insertObject:model atIndex:0];
                }
            }
        }
    }
}

#pragma mark - Interaction
- (void)showMarqueeWithMessage:(NSString *)message {
    if (!self.marqueeView) {
        self.marqueeView = [[PLVMarqueeView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 40.0)];
        [self.marqueeView loadSubViews:PLVMarqueeViewTypeMarquee];
        [self.view insertSubview:self.marqueeView aboveSubview:self.tableView];
    }
    self.marqueeView.hidden = NO;
    [self changeWelcomeViewFrame];
    
    UIFont *font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:message font:font];
    
    [self.marqueeView.marqueeLabe setAttributedText:attributedStr];
    [self.marqueeView.marqueeLabe restartLabel];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shutdownMarqueeView) object:nil];
    [self performSelector:@selector(shutdownMarqueeView) withObject:nil afterDelay:self.marqueeView.marqueeLabe.scrollDuration * 3.0];
}

- (void)shutdownMarqueeView {
    [self.marqueeView.marqueeLabe shutdownLabel];
    self.marqueeView.hidden = YES;
    [self changeWelcomeViewFrame];
}

- (void)showNicknameAlert {
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:nil message:@"请输入聊天昵称" preferredStyle:UIAlertControllerStyleAlert];
    [alertCtrl addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"简单易记的名称有助于让大家认识你哦";
    }];
    [alertCtrl addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self)weakSelf = self;
    __weak UIAlertController *alertCtrlRef = alertCtrl;
    [alertCtrl addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertCtrlRef.textFields.firstObject;
        NSString *newText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (newText.length) {
            if (textField.text.length > 20) {
                [PCCUtils showChatroomMessage:@"昵称字符串不超过20个字符！" addedToView:weakSelf.view];
            } else {
                PLVSocketChatRoomObject *newNickname = [PLVSocketChatRoomObject chatRoomObjectForNewNickNameWithLoginObject:self.socketUser nickName:textField.text];
                [weakSelf emitChatroomMessageWithObject:newNickname];
            }
        } else {
            [PCCUtils showChatroomMessage:@"设置昵称不能为空！" addedToView:weakSelf.view];
        }
    }]];
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.type < PLVTextInputViewTypePrivate && self.showTeacherOnly) {
        return self.teacherData.count;
    } else {
        return self.chatroomData.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.type < PLVTextInputViewTypePrivate && self.showTeacherOnly) {
        PLVChatroomModel *model = self.teacherData[indexPath.row];
        return [model cellFromModelWithTableView:tableView];
    } else {
        PLVChatroomModel *model = self.chatroomData[indexPath.row];
        PLVChatroomCell *cell = [model cellFromModelWithTableView:tableView];
        if ([cell isKindOfClass:[PLVChatroomImageSendCell class]]) {
            PLVChatroomImageSendCell *sendCell = (PLVChatroomImageSendCell *)cell;
            sendCell.delegate = self;
        }
        return cell;
    }
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.type < PLVTextInputViewTypePrivate && self.showTeacherOnly) {
        PLVChatroomModel *model = self.teacherData[indexPath.row];
        return model.cellHeight;
    } else {
        PLVChatroomModel *model = self.chatroomData[indexPath.row];
        return model.cellHeight;
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.type < PLVTextInputViewTypePrivate) {
        CGFloat viewHeight = CGRectGetHeight(scrollView.bounds);
        CGFloat contentHeight = scrollView.contentSize.height;
        CGFloat contentOffsetY = scrollView.contentOffset.y;
        CGFloat bottomOffset = contentHeight - contentOffsetY;
        if (contentHeight != _contentHeight) {
            _contentHeight = contentHeight;
            if (_loadMoreMessage) {
                [scrollView setContentOffset:CGPointMake(0, contentHeight-viewHeight) animated:YES];
            }
        }
        if (bottomOffset < viewHeight + 1) { // tolerance
            _loadMoreMessage = NO;
            self.scrollsToBottom = YES;
            self.showLatestMessageBtn.hidden = YES;
        } else {
            self.scrollsToBottom = NO;
        }
    }
}

#pragma mark - currentChannelSessionId
- (NSString *)currentChannelSessionId {
    NSString *sessionId = @"";
    if (self.delegate && [self.delegate respondsToSelector:@selector(currentChannelSessionId:)]) {
        NSString *currentChannelSessionId = [self.delegate currentChannelSessionId:self];
        if (currentChannelSessionId.length > 0) {
            sessionId = currentChannelSessionId;
        }
    }
    return sessionId;
}

#pragma mark - likeTimer poll
- (void)pollHandleLikeCount {//5秒轮询一次
    self.likeTiming++;
    @synchronized (self) {
        if (self.socketUser && self.likeCountOfSocket > 0) {//5秒发送一次点砸 Socket（本时间段内的点赞总数）
            if (self.likeCountOfSocket > 5) {
                self.likeCountOfSocket = 5;
            }
            self.likeCountOfHttp += self.likeCountOfSocket;
            PLVSocketChatRoomObject *likeSocketObject = [PLVSocketChatRoomObject chatRoomObjectForLikesEventTypeWithRoomId:self.socketUser.roomId userId:self.socketUser.userId nickName:self.socketUser.nickName sessionId:[self currentChannelSessionId] likeCount:self.likeCountOfSocket];
            [self emitChatroomMessageWithObject:likeSocketObject];
            self.likeCountOfSocket = 0;
        }
        if (self.socketUser && self.likeCountOfHttp > 0 && self.likeTiming % 6 == 0) {//30秒发送一次点赞 http 统计（本时间段内的点赞总数）
            if (self.likeCountOfHttp > 30) {
                self.likeCountOfHttp = 30;
            }
            NSUInteger currentLikeCountOfHttp = self.likeCountOfHttp;
            __weak typeof(self) weakSelf = self;
            [PLVLiveVideoAPI likeWithChannelId:self.roomId viewerId:self.socketUser.userId times:currentLikeCountOfHttp completion:^{
                @synchronized (weakSelf) {
                    weakSelf.likeCountOfHttp -= currentLikeCountOfHttp;
                }
            } failure:^(NSError *error) {
                NSLog(@"%@", error);
            }];
        }
    }
}

- (void)handleLikeSocket:(PLVSocketChatRoomObject *)object {
    if (self.type == PLVTextInputViewTypeNormalPublic) {
        [self likeAnimation];
    }
    PLVChatroomModel *model = [PLVChatroomModel modelWithObject:object flower:self.type != PLVTextInputViewTypeNormalPublic];
    [self addModel:model];
}

#pragma mark - PLVTextInputViewDelegate
- (void)textInputView:(PLVTextInputView *)inputView followKeyboardAnimation:(BOOL)flag {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroom:followKeyboardAnimation:)]) {
        [self.delegate chatroom:self followKeyboardAnimation:flag];
    }
}

- (void)textInputView:(PLVTextInputView *)inputView didSendText:(NSString *)text {
    NSString *newText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!self.socketUser || !newText.length) {
        return;
    }
    // TODO:发言时间间隔3s
    PLVChatroomModel *model;
    if (self.type < PLVTextInputViewTypePrivate) {
        PLVSocketChatRoomObject *mySpeak = [PLVSocketChatRoomObject chatRoomObjectForSpeakEventTypeWithRoomId:self.socketUser.roomId content:text];
        BOOL success = [self emitChatroomMessageWithObject:mySpeak];
        if (success)
            model = [PLVChatroomModel modelWithObject:mySpeak];
    } else {
        PLVSocketChatRoomObject *question = [PLVSocketChatRoomObject chatRoomObjectForStudentQuestionEventTypeWithLoginObject:self.socketUser content:text];
        BOOL success = [self emitChatroomMessageWithObject:question];
        if (success)
            model = [PLVChatroomModel modelWithObject:question];
    }
    if (model) {
        [self addModel:model];
    }
}

- (void)sendFlower:(PLVTextInputView *)inputView {
    @synchronized (self) {
        self.likeCountOfSocket++;
    }
    if (self.likeSoctetObjectBySelf == nil && self.socketUser != nil) {
        self.likeSoctetObjectBySelf = [PLVSocketChatRoomObject socketObjectWithJsonDict:@{PLVSocketIOChatRoom_LIKES_nick : self.socketUser.nickName}];
    }
    if (self.likeSoctetObjectBySelf != nil) {
        [self handleLikeSocket:self.likeSoctetObjectBySelf];
    }
}

- (void)textInputView:(PLVTextInputView *)inputView onlyTeacher:(BOOL)on {
    [PCCUtils showChatroomMessage:on?@"只看讲师":@"查看所有人" addedToView:self.view];
    self.showTeacherOnly = on;
    [self.tableView reloadData];
}

- (void)textInputView:(PLVTextInputView *)inputView nickNameSetted:(BOOL)nickNameSetted {
    if (nickNameSetted) {
        [self scrollsToBottom:YES];
    } else {
        [self showNicknameAlert];
    }
}

- (void)openAlbum:(PLVTextInputView *)inputView {
    [PLVLiveVideoConfig sharedInstance].unableRotate = YES;
    ZPickerController *pickerVC = [[ZPickerController alloc] initWithPickerModer:PickerModerOfNormal];
    pickerVC.delegate = self;
    ZNavigationController *navigationController = [[ZNavigationController alloc] initWithRootViewController:pickerVC];
    [self deviceOnInterfaceOrientationMaskPortrait];
    [(UIViewController *)self.delegate presentViewController:navigationController animated:YES completion:nil];
}

- (void)shoot:(PLVTextInputView *)inputView {
    [PLVLiveVideoConfig sharedInstance].unableRotate = YES;
    PLVCameraViewController *cameraVC = [[PLVCameraViewController alloc] init];
    cameraVC.delegate = self;
    [self deviceOnInterfaceOrientationMaskPortrait];
    [(UIViewController *)self.delegate presentViewController:cameraVC animated:YES completion:nil];
}

#pragma mark - UIDevice UIInterfaceOrientationMaskPortrait
- (void)deviceOnInterfaceOrientationMaskPortrait {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIInterfaceOrientationMaskPortrait;//弹出，弹入相册或照相机时，强制把设备UIDevice的方向设置为竖屏
        [invocation setArgument:&val atIndex:2];//从2开始，因为0 1 两个参数已经被selector和target占用
        [invocation invoke];
    }
}

#pragma mark - PLVChatroomQueueDeleage
- (void)pop:(PLVChatroomQueue *)queue welcomeMessage:(NSMutableAttributedString *)welcomeMessage {
    if (!self.welcomeView) {
        self.welcomeView = [[PLVMarqueeView alloc] init];
        [self changeWelcomeViewFrame];
        [self.welcomeView loadSubViews:PLVMarqueeViewTypeWelcome];
        [self.view insertSubview:self.welcomeView aboveSubview:self.tableView];
    }
    self.welcomeView.hidden = NO;
    [self changeWelcomeViewFrame];

    __block CGRect rect = self.welcomeView.marqueeLabe.frame;
    rect.origin.x += rect.size.width;
    self.welcomeView.marqueeLabe.frame = rect;
    
    UIFont *font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    CGSize textSize = [welcomeMessage.string sizeWithAttributes:@{NSFontAttributeName : font}];
    if (textSize.width + 6.0 > rect.size.width) {
        self.welcomeView.marqueeLabe.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium];
    } else {
        self.welcomeView.marqueeLabe.font = font;
    }
    [self.welcomeView.marqueeLabe setAttributedText:welcomeMessage];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        rect.origin.x = 0.0;
        weakSelf.welcomeView.marqueeLabe.frame = rect;
    } completion:nil];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shutdownWelcomeView) object:nil];
    [self performSelector:@selector(shutdownWelcomeView) withObject:nil afterDelay:4.0];
}

- (void)shutdownWelcomeView {
    [self.welcomeView.marqueeLabe shutdownLabel];
    self.welcomeView.hidden = YES;
}

- (void)changeWelcomeViewFrame {
    if (self.marqueeView.hidden) {
        self.welcomeView.frame = CGRectMake(10.0, 10.0, CGRectGetWidth(self.view.bounds) - 20.0, 40.0);
    } else {
        self.welcomeView.frame = CGRectMake(10.0, self.marqueeView.frame.origin.y + self.marqueeView.frame.size.height + 10.0, CGRectGetWidth(self.view.bounds) - 20.0, 40.0);
    }
}

#pragma mark - ZPickerControllerDelegate
- (void)pickerController:(ZPickerController*)pVC uploadImage:(UIImage *)uploadImage {
    [self uploadImage:uploadImage];
}

- (void)dismissPickerController:(ZPickerController*)pVC {
    [self deviceOnInterfaceOrientationMaskPortrait];
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [PLVLiveVideoConfig sharedInstance].unableRotate = NO;
        [weakSelf setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark - PLVCameraViewControllerDelegate
- (void)cameraViewController:(PLVCameraViewController *)cameraVC uploadImage:(UIImage *)uploadImage {
    [self uploadImage:uploadImage];
}

- (void)dismissCameraViewController:(PLVCameraViewController*)cameraVC {
    [self deviceOnInterfaceOrientationMaskPortrait];
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [PLVLiveVideoConfig sharedInstance].unableRotate = NO;
        [weakSelf setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark Upload Image
- (void)uploadImage:(UIImage *)image {
    NSString *imageId = [NSString stringWithFormat:@"chat_img_iOS_%@", [PLVDateUtil curTimeStamp]];
    NSString *imageName = [NSString stringWithFormat:@"%@.jpeg", imageId];
    PLVSocketChatRoomObject *uploadObject = [PLVSocketChatRoomObject chatRoomObjectForSendImageWithValues:@[imageId, image]];
    PLVChatroomModel *model = [PLVChatroomModel modelWithObject:uploadObject];
    [self addModel:model];
    [self uploadImage:image imageId:imageId imageName:imageName];
}

- (void)uploadImage:(UIImage *)image imageId:(NSString *)imageId imageName:(NSString *)imageName {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI uploadImage:image imageName:imageName progress:^(NSProgress * _Nonnull progress) {
        [self uploadImageProgress:progress.fractionCompleted withImageId:imageId];
    } success:^(NSDictionary * _Nonnull uploadImageTokenDict, NSString * _Nonnull key, NSString * _Nonnull imageName) {
        [self uploadImageProgress:1.0 withImageId:imageId];
        
        PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
        PLVSocketChatRoomObject *uploadedObject = [PLVSocketChatRoomObject chatRoomObjectForUploadImage:@(weakSelf.roomId).stringValue accountId:liveConfig.userId sessionId:[weakSelf currentChannelSessionId] tokenDict:uploadImageTokenDict key:key imageId:imageId imageWidth:image.size.width imageHeight:image.size.height];
        [weakSelf emitChatroomMessageWithObject:uploadedObject];
    } fail:^(NSError * _Nonnull error) {
        NSLog(@"上传图片失败：%@", error.description);
        [self uploadImageFail:imageId];
    }];
}

- (void)uploadImageProgress:(CGFloat)progress withImageId:(NSString *)imageId {
    for (PLVChatroomModel *model in self.chatroomData) {
        if (model.type == PLVChatroomModelTypeImageSend && [model.imgId isEqualToString:imageId]) {
            model.uploadProgress = progress;
            if (progress == 1.0) {
                model.uploadFail = NO;
            }
            for (UITableViewCell *cell in self.tableView.visibleCells) {
                if ([cell isKindOfClass:[PLVChatroomImageSendCell class]]) {
                    PLVChatroomImageSendCell *sendCell = (PLVChatroomImageSendCell *)cell;
                    if ([sendCell.imgId isEqualToString:imageId]) {
                        [sendCell uploadProgress:progress];
                        return;
                    }
                }
            }
        }
    }
}

- (void)uploadImageFail:(NSString *)imageId {
    for (PLVChatroomModel *model in self.chatroomData) {
        if (model.type == PLVChatroomModelTypeImageSend && [model.imgId isEqualToString:imageId]) {
            model.uploadFail = YES;
            for (UITableViewCell *cell in self.tableView.visibleCells) {
                if ([cell isKindOfClass:[PLVChatroomImageSendCell class]]) {
                    PLVChatroomImageSendCell *sendCell = (PLVChatroomImageSendCell *)cell;
                    if ([sendCell.imgId isEqualToString:imageId]) {
                        sendCell.refreshBtn.hidden = NO;
                        sendCell.refreshBtn.enabled = YES;
                        [sendCell uploadProgress:-1.0];
                        return;
                    }
                }
            }
        }
    }
}

#pragma mark - PLVChatroomImageSendCellDelegate
- (void)refreshUpload:(PLVChatroomImageSendCell *)sendCell {
    NSString *imageName = [NSString stringWithFormat:@"%@.jpeg", sendCell.imgId];
    [self uploadImage:sendCell.image imageId:sendCell.imgId imageName:imageName];
}

@end
