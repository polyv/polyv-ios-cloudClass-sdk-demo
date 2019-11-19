//
//  PLVChatPlaybackController.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/30.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVChatPlaybackController.h"
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import "PLVTextInputView.h"
#import "PCCUtils.h"
#import "ZNavigationController.h"
#import "ZPickerController.h"
#import "PLVCameraViewController.h"
#import "PLVChatPlaybackModel.h"

@interface PLVChatPlaybackController () <PLVTextInputViewDelegate,PLVCameraViewControllerDelegate, ZPickerControllerDelegate>

@property (nonatomic, strong) NSString *vid;
@property (nonatomic, strong) PLVTextInputView *chatInputView;

@property (nonatomic, strong) NSMutableSet<PLVChatModel *> *uploadImageModel;
@property (nonatomic, assign) NSTimeInterval currentTime;

@end

@implementation PLVChatPlaybackController

- (instancetype)initChatPlaybackControllerWithVid:(NSString *)vid frame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.vid = vid;
        self.view.frame = frame;
    }
    return self;
}

+ (instancetype)chatPlaybackControllerWithVid:(NSString *)vid frame:(CGRect)frame {
    PLVChatPlaybackController *chatPlaybackController = [[PLVChatPlaybackController alloc] initChatPlaybackControllerWithVid:vid frame:frame];
    return chatPlaybackController;
}

- (void)loadSubViews:(UIView *)tapSuperView {
    CGFloat h = [self getInputViewHeight];
    self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight (self.view.bounds) - h);
    self.tableView.backgroundColor = UIColorFromRGB(0xe9ebf5);
    
    self.chatInputView = [[PLVTextInputView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - h, CGRectGetWidth(self.view.bounds), h)];
    self.chatInputView.delegate = self;
    self.chatInputView.tapSuperView = tapSuperView;
    [self.view addSubview:self.chatInputView];
    [self.chatInputView loadViews:PLVTextInputViewTypePlayback enableMore:YES];
    self.chatInputView.originY = self.chatInputView.frame.origin.y;
    
    [self addLatestMessageButton];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.currentTime = 0;
    self.playbackQueue = [NSMutableArray array];
    self.uploadImageModel = [NSMutableSet set];
    
    [self seekToTime:0];
}

#pragma mark -

- (CGFloat)getInputViewHeight {
    CGFloat h = 50.0;
    if (@available(iOS 11.0, *)) {
        CGRect rect = [UIApplication sharedApplication].delegate.window.bounds;
        CGRect layoutFrame = [UIApplication sharedApplication].delegate.window.safeAreaLayoutGuide.layoutFrame;
        h += (rect.size.height - layoutFrame.origin.y - layoutFrame.size.height);
    }
    return h;
}

- (void)scrollToTime:(NSTimeInterval)time {
    //NSLog(@"time: %lf",time);
    if (!self.playbackQueue.count) {
        return;
    }
    if (self.currentTime == time) {
        return;
    }
    self.currentTime = time;
    
    NSMutableArray *tempArr = [NSMutableArray array];
    for (PLVChatPlaybackModel *model in self.playbackQueue) {
        if (model.showTime > ceil(time)) { // 向上取整
            break;
        } else {
            [tempArr addObject:model];
        }
    }
    if (tempArr.count > 0) {
        [self.dataArray addObjectsFromArray:tempArr];
        [self.playbackQueue removeObjectsInArray:tempArr];
    }
    if (self.scrollsToBottom) {
        [self refreshTableView];
        [self scrollsToBottom:YES];
    } else {
        [self showLatestMessageButton];
    }
    // 提前预加载下一时间段回放数据
    if (time > self.startTime + 280) {
        if (self.startTime + 299 < [self.delegate videoDurationTime]) {
            [self prepareToLoad:self.startTime + 300];
        }
    }
}

#pragma mark - Private methods
- (void)tapChatInputView {
    if (self.chatInputView) {
        [self.chatInputView tapAction];
    }
}

#pragma mark - <PLVTextInputViewDelegate>

- (void)textInputView:(PLVTextInputView *)inputView followKeyboardAnimation:(BOOL)flag {
    if ([self.delegate respondsToSelector:@selector(playbackController:followKeyboardAnimation:)]) {
        [self.delegate playbackController:self followKeyboardAnimation:flag];
    }
}

- (void)textInputView:(PLVTextInputView *)inputView didSendText:(NSString *)text {
    NSString *newText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!newText.length) {
        return;
    }
    NSLog(@"%s %@",__FUNCTION__,text);
    NSTimeInterval time = self.delegate.currentPlaybackTime;
    [self addSpeakModel:newText time:time];
    [self sendMesage:newText time:time msgType:@"speak"];
}

- (void)openAlbum:(PLVTextInputView *)inputView {
    [PLVLiveVideoConfig sharedInstance].unableRotate = YES;
    ZPickerController *pickerVC = [[ZPickerController alloc] initWithPickerModer:PickerModerOfNormal];
    pickerVC.delegate = self;
    ZNavigationController *navigationController = [[ZNavigationController alloc] initWithRootViewController:pickerVC];
    [PCCUtils deviceOnInterfaceOrientationMaskPortrait];
    [(UIViewController *)self.delegate presentViewController:navigationController animated:YES completion:nil];
}

- (void)shoot:(PLVTextInputView *)inputView {
    [PLVLiveVideoConfig sharedInstance].unableRotate = YES;
    PLVCameraViewController *cameraVC = [[PLVCameraViewController alloc] init];
    cameraVC.delegate = self;
    [PCCUtils deviceOnInterfaceOrientationMaskPortrait];
    [(UIViewController *)self.delegate presentViewController:cameraVC animated:YES completion:nil];
}

#pragma mark - <PLVCameraViewControllerDelegate>
- (void)cameraViewController:(PLVCameraViewController *)cameraVC uploadImage:(UIImage *)uploadImage {
    [self uploadImage:uploadImage];
}

- (void)dismissCameraViewController:(PLVCameraViewController*)cameraVC {
    [PCCUtils deviceOnInterfaceOrientationMaskPortrait];
    [self tapChatInputView];
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [PLVLiveVideoConfig sharedInstance].unableRotate = NO;
        [weakSelf setNeedsStatusBarAppearanceUpdate];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }];
}

#pragma mark - <ZPickerControllerDelegate>
- (void)pickerController:(ZPickerController*)pVC uploadImage:(UIImage *)uploadImage {
    [self uploadImage:uploadImage];
}

- (void)dismissPickerController:(ZPickerController*)pVC {
    [PCCUtils deviceOnInterfaceOrientationMaskPortrait];
    [self tapChatInputView];
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [PLVLiveVideoConfig sharedInstance].unableRotate = NO;
        [weakSelf setNeedsStatusBarAppearanceUpdate];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }];
}

#pragma mark - <PLVBaseCellProtocol>

- (void)cellCallback:(PLVBaseCell *)cell {
    NSLog(@"%s",__FUNCTION__);
}

#pragma mark Upload Image

- (void)uploadImage:(UIImage *)image {
    NSLog(@"%s",__FUNCTION__);
    NSString *imageId = [NSString stringWithFormat:@"chat_img_iOS_%@", [PLVFdUtil curTimeStamp]];
    NSString *imageName = [NSString stringWithFormat:@"%@.jpeg", imageId];
    NSTimeInterval time = self.delegate.currentPlaybackTime;
    PLVChatModel *imageModel = [self addImageModel:image imgId:imageId time:time];
    if (imageModel) {
        [self.uploadImageModel addObject:imageModel];
    }
    [self uploadImage:image imageId:imageId imageName:imageName time:time];
}

- (void)uploadImage:(UIImage *)image imageId:(NSString *)imageId imageName:(NSString *)imageName time:(NSTimeInterval)time {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI uploadImage:image imageName:imageName progress:^(float fractionCompleted) {
        [weakSelf uploadImageProgress:fractionCompleted withImageId:imageId];
    } success:^(NSDictionary * _Nonnull uploadImageTokenDict, NSString * _Nonnull key, NSString * _Nonnull imageName) {
        [weakSelf uploadImageProgress:1.0 withImageId:imageId];
        
        NSString *imageUrl = [NSString stringWithFormat:@"https://%@/%@", uploadImageTokenDict[@"host"], key];
        NSDictionary *imageDict = @{@"id":imageId,
                                    @"size":@{@"width":@(image.size.width),
                                              @"height":@(image.size.height)},
                                    @"type":@"chatImg",
                                    @"uploadImgUrl":imageUrl,
                                    @"status":@"upLoadingSuccess"};
        [weakSelf sendMesage:imageDict time:time msgType:@"chatImg"];
    } fail:^(NSError * _Nonnull error) {
        NSLog(@"上传图片失败：%@", error.description);
        [weakSelf uploadImageFail:imageId];
    }];
}

- (void)uploadImageProgress:(CGFloat)progress withImageId:(NSString *)imageId {
    __weak typeof(self)weakSelf = self;
    [self.uploadImageModel enumerateObjectsUsingBlock:^(PLVChatModel * _Nonnull obj, BOOL * _Nonnull stop) {
        PLVChatModel *chatModel = (PLVChatModel *)obj;
        if ([chatModel.imageContent.imgId isEqualToString:imageId]) {
            chatModel.imageContent.uploadProgress = progress;
            if (progress == 1.0) {
                chatModel.imageContent.uploadFail = NO;
                [weakSelf.uploadImageModel removeObject:chatModel];
            }
            if (chatModel.cell && [chatModel.cell isKindOfClass:[PLVChatImageCell class]]) {
                [(PLVChatImageCell *)chatModel.cell uploadProgress:progress];
            }
            *stop = YES;
        }
    }];
}

- (void)uploadImageFail:(NSString *)imageId {
    [self.uploadImageModel enumerateObjectsUsingBlock:^(PLVChatModel * _Nonnull obj, BOOL * _Nonnull stop) {
        PLVChatModel *chatModel = (PLVChatModel *)obj;
        if ([chatModel.imageContent.imgId isEqualToString:imageId]) {
            chatModel.imageContent.uploadFail = YES;
            if (chatModel.cell && [chatModel.cell isKindOfClass:[PLVChatImageCell class]]) {
                [(PLVChatImageCell *)chatModel.cell uploadProgress:-1.0];
            }
            *stop = YES;
        }
    }];
}

@end
