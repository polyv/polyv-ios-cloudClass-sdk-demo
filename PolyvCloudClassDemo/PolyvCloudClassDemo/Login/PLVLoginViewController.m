//
//  PLVLoginViewController.m
//  PolyvCloudSchoolDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//
#import "PLVLoginViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <Masonry/Masonry.h>
#import <PolyvCloudClassSDK/PLVLiveAPI.h>
#import <PolyvCloudClassSDK/PLVLiveConfig.h>
#import <PolyvBusinessSDK/PLVVodVideo.h>
#import "PLVLiveViewController.h"
#import "PLVVodViewController.h"

@interface PLVLoginViewController ()

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *logoImgView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *liveBtn;
@property (nonatomic, weak) IBOutlet UIView *liveSelectView;
@property (nonatomic, weak) IBOutlet UIButton *vodBtn;
@property (nonatomic, weak) IBOutlet UIView *vodSelectView;
@property (nonatomic, weak) IBOutlet UITextField *channelIdTF;
@property (nonatomic, weak) IBOutlet UITextField *appIDTF;
@property (nonatomic, weak) IBOutlet UITextField *userIDTF;
@property (nonatomic, weak) IBOutlet UIView *userLineView;
@property (nonatomic, weak) IBOutlet UITextField *appSecretTF;
@property (nonatomic, weak) IBOutlet UIView *appSecretLineView;
@property (nonatomic, weak) IBOutlet UITextField *vIdTF;
@property (nonatomic, weak) IBOutlet UIButton *loginBtn;

@end

@implementation PLVLoginViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)followKeyboardAnimation:(UIEdgeInsets)contentInsets duration:(NSTimeInterval)duration flag:(BOOL)flag {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:MAX(0.0, duration - 0.1) animations:^{
            weakSelf.logoImgView.hidden = flag;
            weakSelf.titleLabel.hidden = !flag;
            weakSelf.scrollView.contentInset = contentInsets;
            weakSelf.scrollView.scrollIndicatorInsets = contentInsets;
        }];
    });
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self followKeyboardAnimation:UIEdgeInsetsMake(-110.0, 0.0, 110.0, 0.0) duration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] flag:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self followKeyboardAnimation:UIEdgeInsetsZero duration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] flag:NO];
}

- (BOOL)checkTextField:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (textField.text.length == 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)checkTextFields {
    if (!self.liveSelectView.hidden) {
        if ([self checkTextField:self.channelIdTF] || [self checkTextField:self.appIDTF] || [self checkTextField:self.userIDTF] || [self checkTextField:self.appSecretTF]) {
            self.loginBtn.enabled = NO;
            self.loginBtn.alpha = 0.4;
        } else {
            self.loginBtn.enabled = YES;
            self.loginBtn.alpha = 1.0;
        }
    } else {
        if ([self checkTextField:self.vIdTF] || [self checkTextField:self.appIDTF] || [self checkTextField:self.userIDTF]) {
            self.loginBtn.enabled = NO;
            self.loginBtn.alpha = 0.4;
        } else {
            self.loginBtn.enabled = YES;
            self.loginBtn.alpha = 1.0;
        }
    }
}

- (void)tapAction {
    [self.view endEditing:YES];
}

//使用了私有的实现修改UITextField里clearButton的图片
- (void)replaceClearButtonOfTextField:(UITextField *)textField {
    UIButton *clearButton = [textField valueForKey:@"_clearButton"];
    [clearButton setImage:[UIImage imageNamed:@"plv_clear.png"] forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
    
    for (UIView *textField in self.view.subviews) {
        if ([textField isKindOfClass:UITextField.class]) {
            [self replaceClearButtonOfTextField:(UITextField *)textField];
        }
    }
    
    self.liveSelectView.hidden = YES;
    [self switchLive:self.liveBtn];
    self.loginBtn.layer.cornerRadius = self.loginBtn.bounds.size.height * 0.5;
}

- (void)switchScenes:(BOOL)flag y:(CGFloat)y {
    self.liveSelectView.hidden = flag;
    self.vodSelectView.hidden = !flag;
    self.channelIdTF.hidden = flag;
    self.userIDTF.hidden = flag;
    self.userLineView.hidden = flag;
    self.appSecretTF.hidden = flag;
    self.appSecretLineView.hidden = flag;
    self.vIdTF.hidden = !flag;
    
    __weak typeof(self) weakSelf = self;
    [self.loginBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.loginBtn.superview);
        make.top.equalTo(weakSelf.loginBtn.superview.mas_top).offset(y);
        make.width.mas_equalTo(320.0);
        make.height.mas_equalTo(48.0);
    }];
}

- (IBAction)switchLive:(UIButton *)sender {
    if (self.liveSelectView.hidden) {
        [self switchScenes:NO y:460.0];
        NSArray *liveLoginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"liveLoginInfo"];
        if (liveLoginInfo) {
            self.channelIdTF.text = liveLoginInfo[0];
            self.appIDTF.text = liveLoginInfo[1];
            self.userIDTF.text = liveLoginInfo[2];
            self.appSecretTF.text = liveLoginInfo[3];
        } else {
            PLVLiveConfig *liveConfig = [PLVLiveConfig sharedInstance];
            self.appIDTF.text = liveConfig.appId;
            self.userIDTF.text = liveConfig.userId;
            self.appSecretTF.text = liveConfig.appSecret;
        }
        [self checkTextFields];
    }
}

- (IBAction)switchVod:(UIButton *)sender {
    if (self.vodSelectView.hidden) {
        [self switchScenes:YES y:365.0];
        
        NSArray *vodLoginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"vodLoginInfo"];
        if (vodLoginInfo) {
            self.vIdTF.text = vodLoginInfo[0];
            self.appIDTF.text = vodLoginInfo[1];
        } else {
            PLVLiveConfig *liveConfig = [PLVLiveConfig sharedInstance];
            self.vIdTF.text = liveConfig.vodId;
            self.appIDTF.text = liveConfig.appId;
        }
        [self checkTextFields];
    }
}

- (void)presentAlertViewController:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)loginButtonClick:(UIButton *)sender {
    [self tapAction];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud.label setText:@"登录中..."];
    __weak typeof(self) weakSelf = self;
    if (!self.liveSelectView.hidden) {
        [[NSUserDefaults standardUserDefaults] setObject:@[self.channelIdTF.text, self.appIDTF.text, self.userIDTF.text, self.appSecretTF.text] forKey:@"liveLoginInfo"];
        
        [PLVLiveAPI verifyPermissionWithChannelId:self.channelIdTF.text.integerValue vid:nil appId:self.appIDTF.text userId:self.userIDTF.text appSecret:self.appSecretTF.text completion:^{
            PLVLiveConfig *liveConfig = [PLVLiveConfig sharedInstance];
            liveConfig.appId = self.appIDTF.text;
            liveConfig.userId = self.userIDTF.text;
            liveConfig.appSecret = self.appSecretTF.text;
            [PLVLiveAPI loadChannelInfoRepeatedlyWithUserId:liveConfig.userId channelId:self.channelIdTF.text.integerValue completion:^(PLVLiveChannel *channel) {
                [hud hideAnimated:YES];
                PLVLiveViewController *liveVC = [PLVLiveViewController new];
                liveVC.channel = channel;
                [weakSelf presentViewController:liveVC animated:YES completion:nil];
            } failure:^(NSError *error) {
                [hud hideAnimated:YES];
                [weakSelf presentAlertViewController:error.localizedDescription];
            }];
        } failure:^(NSError *error) {
            [hud hideAnimated:YES];
            [weakSelf presentAlertViewController:error.localizedDescription];
        }];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@[self.vIdTF.text, self.appIDTF.text] forKey:@"vodLoginInfo"];
        
        [PLVLiveAPI verifyPermissionWithChannelId:0 vid:self.vIdTF.text appId:self.appIDTF.text userId:self.userIDTF.text appSecret:nil completion:^{
            [PLVVodVideo requestVideoWithVid:self.vIdTF.text completion:^(PLVVodVideo *video) {
                [hud hideAnimated:YES];
                PLVVodViewController *vodVC = [PLVVodViewController new];
                vodVC.vodVideo = video;
                [weakSelf presentViewController:vodVC animated:YES completion:nil];
            } fail:^(NSError *error) {
                [hud hideAnimated:YES];
                [weakSelf presentAlertViewController:error.localizedDescription];
            }];
        } failure:^(NSError *error) {
            [hud hideAnimated:YES];
            [weakSelf presentAlertViewController:error.localizedDescription];
        }];
    }
}

- (IBAction)textEditChanged:(id)sender {
    [self checkTextFields];
}

#pragma mark - view controls
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {//登录窗口只支持竖屏方向
    return UIInterfaceOrientationMaskPortrait;
}

@end
