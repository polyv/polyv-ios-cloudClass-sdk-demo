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
#import "PLVChatroomModel.h"
#import "PLVEmojiModel.h"
#import "PLVUtils.h"
#import "MarqueeLabel.h"

@interface PLVChatroomController () <UITableViewDelegate, UITableViewDataSource, PLVTextInputViewDelegate>

@property (nonatomic, assign) NSUInteger roomId;
@property (nonatomic, assign) PLVChatroomType type;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<PLVChatroomModel *> *chatroomData;
@property (nonatomic, strong) NSMutableArray<PLVChatroomModel *> *teacherData;

@property (nonatomic, strong) UIView *marqueeView;
@property (nonatomic, strong) MarqueeLabel *marquee;
@property (nonatomic, strong) UIButton *showLatestMessageBtn;
@property (nonatomic, strong) PLVTextInputView *inputView;

@property (nonatomic, assign) BOOL scrollsToBottom;  // default is YES.
@property (nonatomic, assign) BOOL showTeacherOnly;  // 只看讲师（有身份用户）数据
@property (nonatomic, assign) BOOL moreMessageHistory;
@property (nonatomic, assign) BOOL nickNameSetted;
@property (nonatomic, assign) NSUInteger startIndex;
@property (nonatomic, strong) NSString *imgId;      // 上传图片Id

@property (nonatomic, assign) NSUInteger onlineCount;

@end

static NSMutableSet *forbiddenUsers;

/// 生成一个teacher回答的伪数据
PLVSocketChatRoomObject *createTeacherAnswerObject() {
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObject:@"T_ANSWER" forKey:@"EVENT"];
    jsonDict[@"content"] = @"同学，您好！请问有什么问题吗？";
    jsonDict[@"user"] = @{ @"nick" : @"讲师",
                           @"pic" : @"https://livestatic.polyv.net/assets/images/teacher.png",
                           @"userType" : @"teacher" };
    PLVSocketChatRoomObject *teacherAnswer = [PLVSocketChatRoomObject socketObjectWithJsonDict:jsonDict];
    teacherAnswer.localMessage = YES;
    return teacherAnswer;
}

@implementation PLVChatroomController {
    BOOL _loadMoreMessage;
    CGFloat _contentHeight;
}

+ (BOOL)havePermissionToWatchLive:(NSUInteger)roomId {
    if (forbiddenUsers && forbiddenUsers.count) {
        return ![forbiddenUsers containsObject:@(roomId)];
    }else {
        return YES;
    }
}

#pragma mark - setter/getter

- (void)setSocketUser:(PLVSocketObject *)socketUser {
    _socketUser = socketUser;
    if (_type==PLVChatroomTypePublic && !_nickNameSetted) {
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

- (UIView *)marqueeView {
    if (!_marqueeView) {
        _marqueeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
        _marqueeView.backgroundColor = [UIColor colorWithRed:57/255.0 green:56/255.0 blue:66/255.0 alpha:0.65];
        [self.view addSubview:_marqueeView];
    }
    return _marqueeView;
}

- (MarqueeLabel *)marquee {
    if (!_marquee) {
        _marquee = [[MarqueeLabel alloc] initWithFrame:self.marqueeView.bounds duration:8.0 andFadeLength:0];
        _marquee.textColor = [UIColor whiteColor];
        _marquee.leadingBuffer = CGRectGetWidth(self.view.bounds);
        [self.marqueeView addSubview:_marquee];
    }
    return _marquee;
}

#pragma mark - life cycle

- (void)dealloc {
    NSLog(@"-[%@ %@]",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.chatroomData = [NSMutableArray array];
    self.teacherData = [NSMutableArray array];
    
    if (self.type==PLVChatroomTypePrivate) {
        PLVChatroomModel *model = [PLVChatroomModel modelWithObject:createTeacherAnswerObject()];
        [self.chatroomData addObject:model];
    }
}

#pragma mark - public methods

+ (instancetype)chatroomWithType:(PLVChatroomType)type roomId:(NSUInteger)roomId frame:(CGRect)frame {
    return [[PLVChatroomController alloc] initChatroomWithType:type roomId:roomId frame:frame];
}

- (instancetype)initChatroomWithType:(PLVChatroomType)type roomId:(NSUInteger)roomId frame:(CGRect)frame {
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
    
    if (self.type == PLVChatroomTypePublic) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshClick:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:refreshControl];
        [self refreshClick:refreshControl];
    }
    
    self.inputView = [[PLVTextInputView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-h, CGRectGetWidth(self.view.bounds), h)];
    self.inputView.delegate = self;
    [self.view addSubview:self.inputView];
    [self.inputView loadViews:self.type == PLVChatroomTypePublic ? PLVTextInputViewTypePublic : PLVTextInputViewTypePrivate];
    
    self.showLatestMessageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.showLatestMessageBtn.layer.cornerRadius = 15.0;
    self.showLatestMessageBtn.layer.masksToBounds = YES;
    [self.showLatestMessageBtn setTitle:@"有更多新消息，点击查看" forState:UIControlStateNormal];
    [self.showLatestMessageBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.showLatestMessageBtn.titleLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightMedium]];
    self.showLatestMessageBtn.backgroundColor = [UIColor colorWithRed:90/255.0 green:200/255.0 blue:250/255.0 alpha:1];
    self.showLatestMessageBtn.hidden = YES;
    [self.showLatestMessageBtn addTarget:self action:@selector(loadMoreMessages) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.showLatestMessageBtn];
    
    [self.showLatestMessageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(185, 30));
        make.bottom.equalTo(self.inputView.mas_top).offset(-10);
    }];
}

- (void)addNewChatroomObject:(PLVSocketChatRoomObject *)object {
    switch (object.eventType) {
        //case PLVSocketChatRoomEventType_GONGGAO: { (弃)
            //[self showMarqueeWithMessage:object.jsonDict[@"content"]];
        //} break;
        case PLVSocketChatRoomEventType_SET_NICK: {
            NSString *status = object.jsonDict[@"status"];
            if ([status isEqualToString:@"success"]) {  // success：广播消息；
                if ([object.jsonDict[@"userId"] isEqualToString:self.socketUser.userId]) {
                    self.nickNameSetted = YES;
                    [self nickNameRenamed:object.jsonDict[@"nick"] success:YES message:object.jsonDict[@"message"]];
                }
            }else { // error：单播消息（设置出错）
                [self nickNameRenamed:nil success:NO message:object.jsonDict[@"message"]];
            }
        } break;
        case PLVSocketChatRoomEventType_CLOSEROOM: {
            self.close = [object.jsonDict[@"value"][@"closed"] boolValue];
            [PLVUtils showChatroomMessage:self.isClosed?@"房间已经关闭":@"房间已经开启" addedToView:self.view];
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
                if (self.imgId && [self.imgId isEqualToString:values.firstObject[@"id"]]) {
                    if (result) {
                        NSLog(@"图片发送/审核成功！");
                    }else {
                        NSLog(@"图片审核失败！");
                    }
                }else if (result) {
                    PLVChatroomModel *model = [PLVChatroomModel modelWithObject:object];
                    if (CGSizeEqualToSize(model.imageViewSize, CGSizeZero)) { // 兼容无image size数据
                        __weak typeof(self)weakSelf = self;
                        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:model.imgUrl] options:SDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                            if (error) {
                                NSLog(@"download image error:%@",error.localizedDescription);
                            }else if (image) {
                                [model calculateImageViewSizeWithImageSize:image.size];
                                [weakSelf addModel:model];
                            }
                        }];
                    }else {
                        [self addModel:model];
                    }
                }
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

#pragma mark - private methods

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
    if (self.type == PLVChatroomTypePublic) {
        if (model.isTeacher) {
            [self.teacherData addObject:model];
        }
        if (model.userType == PLVChatroomUserTypeManager) {
            if (model.speakContent) {   // 可能为图片消息
                [self showMarqueeWithMessage:model.speakContent]; // 跑马灯公告
            }
        }
    }
    
    [self.tableView reloadData];
    
    if (model.type==PLVChatroomModelTypeSpeakOwn || self.scrollsToBottom) {
        [self scrollsToBottom:YES];
    }else if (self.type==PLVChatroomTypePublic && !self.showTeacherOnly) {
        self.showLatestMessageBtn.hidden = NO;
    }
    
    if (self.type==PLVChatroomTypePublic && model.speakContent) {
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

- (void)refreshClick:(UIRefreshControl *)refreshControl {
    [refreshControl endRefreshing];
    const NSUInteger length = 21;
    if (self.moreMessageHistory) {
        __weak typeof(self)weakSelf = self;
        [PLVLiveAPI requestChatRoomHistoryWithRoomId:self.roomId startIndex:self.startIndex endIndex:self.startIndex+length completion:^(NSArray *historyList) {
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
            [PLVUtils showChatroomMessage:@"历史记录获取失败！" addedToView:self.view];
        }];
    }else {
        [PLVUtils showChatroomMessage:@"没有更多数据了！" addedToView:self.view];
    }
}

- (BOOL)emitChatroomMessageWithObject:(PLVSocketChatRoomObject *)object {
    // 关闭房间、禁言只对聊天室发言有效
    if (self.type==PLVChatroomTypePublic && object.eventType==PLVSocketChatRoomEventType_SPEAK) {
        if (self.isClosed) {
            [PLVUtils showChatroomMessage:[NSString stringWithFormat:@"消息发送失败！%ld", (long)PLVChatroomErrorCodeRoomClose] addedToView:self.view];
            return NO;
        }
        if (self.type == PLVChatroomTypePublic && self.socketUser.isBanned) { // only log.
            NSLog(@"消息发送失败！%ld", (long)PLVChatroomErrorCodeBanned);
            return YES;
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatroom:emitSocketObject:)]) {
        [self.delegate chatroom:self emitSocketObject:object];
        return YES;
    }else {
        return NO;
    }
}

- (void)loadMoreMessages {
    [self scrollsToBottom:YES];
}

- (void)scrollsToBottom:(BOOL)animated {
    NSIndexPath *lastIndexPath = [self lastIndexPathForChatroomData];
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
    }else {
        [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (NSIndexPath *)lastIndexPathForChatroomData {
    if (self.type == PLVChatroomTypePublic && self.showTeacherOnly) {
        return [NSIndexPath indexPathForRow:self.teacherData.count-1 inSection:0];
    }else {
        return [NSIndexPath indexPathForRow:self.chatroomData.count-1 inSection:0];
    }
}

- (void)handleChatroomMessageHistory:(NSArray *)messageArr {
    if (messageArr && messageArr.count) {
        for (NSDictionary *messageDict in messageArr) {
            PLVSocketChatRoomObject *chatroomObject;
            NSString *msgSource = messageDict[@"msgSource"];
            if (msgSource) {
                if ([msgSource isEqualToString:@"chatImg"]) { // 图片
                    NSDictionary *imageDict = @{ @"EVENT"  : @"CHAT_IMG",
                                                 @"values" : @[messageDict[@"content"]],
                                                 @"user"   : messageDict[@"user"]};
                    chatroomObject = [PLVSocketChatRoomObject socketObjectWithJsonDict:imageDict];
                } // redpaper（红包）、get_redpaper（领红包）
            } else {
                NSString *uid = [NSString stringWithFormat:@"%@",messageDict[@"user"][@"uid"]];
                if ([uid isEqualToString:@"1"] || [uid isEqualToString:@"1"]) {
                    // uid = 1，打赏消息；uid = 2，自定义消息
                }else { // speak message
                    NSDictionary *speakDict = @{ @"EVENT"  : @"SPEAK",
                                                 @"values" : @[messageDict[@"content"]],
                                                 @"user"   : messageDict[@"user"] };
                    chatroomObject = [PLVSocketChatRoomObject socketObjectWithJsonDict:speakDict];
                }
            }
            if (chatroomObject) {
                PLVChatroomModel *model = [PLVChatroomModel modelWithObject:chatroomObject];
                [self.chatroomData insertObject:model atIndex:0];
                if (self.type==PLVChatroomTypePublic && model.isTeacher) {
                    [self.teacherData insertObject:model atIndex:0];
                }
            }
        }
    }
}

//- (CGSize)preferredContentSize {
//    // Force the table view to calculate its height
//    [self.tableView layoutIfNeeded];
//    return self.tableView.contentSize;
//}

#pragma mark - Interaction
- (void)showMarqueeWithMessage:(NSString *)message {
    [self.marqueeView setHidden:NO];
    
    UIFont *font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:message font:font];
    
    [self.marquee setAttributedText:attributedStr];
    [self.marquee restartLabel];
    
    NSTimeInterval duration = self.marquee.scrollDuration * 3;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shutdownMarqueeView) object:nil];
    [self performSelector:@selector(shutdownMarqueeView) withObject:nil afterDelay:duration];
}

- (void)shutdownMarqueeView {
    [self.marquee shutdownLabel];
    [self.marqueeView setHidden:YES];
}

// show once
//- (void)showMarqueeWithMessage:(NSString *)message {
//    NSTimeInterval duration = 8.0;
//    UIView *marqueeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
//    marqueeView.backgroundColor = [UIColor colorWithRed:57/255.0 green:56/255.0 blue:66/255.0 alpha:0.65];
//    [self.view addSubview:marqueeView];
//
//    UIFont *font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
//    NSMutableAttributedString *attributedStr = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:message font:font];
//    MarqueeLabel *marquee = [[MarqueeLabel alloc] initWithFrame:marqueeView.bounds duration:duration andFadeLength:0];
//    marquee.attributedText = attributedStr;
//    marquee.textColor = [UIColor whiteColor];
//    marquee.leadingBuffer = CGRectGetWidth(self.view.bounds);
//    [marqueeView addSubview:marquee];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration*3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [marqueeView removeFromSuperview];
//    });
//}

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
                [PLVUtils showChatroomMessage:@"昵称字符串不超过20个字符！" addedToView:weakSelf.view];
            }else {
                PLVSocketChatRoomObject *newNickname = [PLVSocketChatRoomObject chatRoomObjectForNewNickNameWithLoginObject:self.socketUser nickName:textField.text];
                [weakSelf emitChatroomMessageWithObject:newNickname];
            }
        }else {
            [PLVUtils showChatroomMessage:@"设置昵称不能为空！" addedToView:weakSelf.view];
        }
    }]];
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

#pragma mark - <UITableViewDataSource>
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.type == PLVChatroomTypePublic && self.showTeacherOnly) {
        return self.teacherData.count;
    }else {
        return self.chatroomData.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.type == PLVChatroomTypePublic && self.showTeacherOnly) {
        PLVChatroomModel *model = self.teacherData[indexPath.row];
        return [model cellFromModelWithTableView:tableView];
    }else {
        PLVChatroomModel *model = self.chatroomData[indexPath.row];
        return [model cellFromModelWithTableView:tableView];
    }
}

//-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    PLVChatroomModel *model = self.chatroomData[indexPath.row];
//    NSString *indentify = [PLVChatroomCell indentifyWithModel:model];
//    PLVChatroomCell *cell = [tableView dequeueReusableCellWithIdentifier:indentify];
//    if (!cell){
//        cell = [[PLVChatroomCell alloc] initWithModel:model identifier:indentify];
//    } else{
//        [cell setModel:nil];
//    }
//}

#pragma mark - <UITableViewDelegate>
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //return UITableViewAutomaticDimension;
    if (self.type == PLVChatroomTypePublic && self.showTeacherOnly) {
        PLVChatroomModel *model = self.teacherData[indexPath.row];
        return model.cellHeight;
    }else {
        PLVChatroomModel *model = self.chatroomData[indexPath.row];
        return model.cellHeight;
    }
}

//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    PLVChatroomModel *model = self.chatroomData[indexPath.row];
//    return model.cellHeight;
//}

#pragma mark - <UIScrollViewDelegate>
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.type == PLVChatroomTypePublic) {
        CGFloat viewHeight = CGRectGetHeight(scrollView.bounds);
        CGFloat contentHeight = scrollView.contentSize.height;
        CGFloat contentOffsetY = scrollView.contentOffset.y;
        CGFloat bottomOffset = contentHeight - contentOffsetY;
        //NSLog(@"%.1lf,%.1lf,%.1lf,%.1lf",viewHeight,contentHeight,contentOffsetY,bottomOffset);
        if (contentHeight != _contentHeight) {
            _contentHeight = contentHeight;
            if (_loadMoreMessage) {
                [scrollView setContentOffset:CGPointMake(0, contentHeight-viewHeight) animated:YES];
            }
        }
        if (bottomOffset < viewHeight+1) { // tolerance
            _loadMoreMessage = NO;
            self.scrollsToBottom = YES;
            self.showLatestMessageBtn.hidden = YES;
        }else {
            self.scrollsToBottom = NO;
        }
    }
}

#pragma mark - <PLVTextInputViewDelegate>
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
    if (self.type == PLVChatroomTypePublic) {
        PLVSocketChatRoomObject *mySpeak = [PLVSocketChatRoomObject chatRoomObjectForSpeakEventTypeWithRoomId:self.socketUser.roomId content:text];
        BOOL success = [self emitChatroomMessageWithObject:mySpeak];
        if (success)
            model = [PLVChatroomModel modelWithObject:mySpeak];
    }else {
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
    if (!self.socketUser) return;
    PLVSocketChatRoomObject *sendFlower = [PLVSocketChatRoomObject chatRoomObjectForLikesEventTypeWithRoomId:self.socketUser.roomId nickName:self.socketUser.nickName];
    [self emitChatroomMessageWithObject:sendFlower];
}

- (void)textInputView:(PLVTextInputView *)inputView onlyTeacher:(BOOL)on {
    [PLVUtils showChatroomMessage:on?@"只看讲师":@"查看所有人" addedToView:self.view];
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

@end
