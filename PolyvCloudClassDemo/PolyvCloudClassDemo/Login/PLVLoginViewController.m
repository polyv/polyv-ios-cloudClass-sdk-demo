//
//  PLVLoginViewController.m
//  PolyvCloudSchoolDemo
//
//  Created by zykhbl on 2018/8/8.
//  Copyright © 2018年 polyv. All rights reserved.
//
#import "PLVLoginViewController.h"
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <PolyvCloudClassSDK/PLVLiveVideoAPI.h>
#import <PolyvCloudClassSDK/PLVLiveVideoConfig.h>
#import <PolyvBusinessSDK/PLVVodConfig.h>
#import "PLVLiveViewController.h"
#import "PLVVodViewController.h"
#import "PCCUtils.h"

static NSString * const NSUserDefaultKey_VodLoginInfo = @"vodLoginInfo";
static NSString * const NSUserDefaultKey_LiveLoginInfo = @"liveLoginInfo";

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

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    [self addNotification];
    [self addGestureRecognizer];
}

- (void)dealloc {
    [self removeNotification];
}

#pragma mark - init
- (void)initUI {
    for (UIView *textField in self.view.subviews) {
        if ([textField isKindOfClass:UITextField.class]) {
            //使用了私有的实现修改UITextField里clearButton的图片
            UIButton *clearButton = [textField valueForKey:@"_clearButton"];
            [clearButton setImage:[UIImage imageNamed:@"plv_clear.png"] forState:UIControlStateNormal];
        }
    }
    
    self.liveSelectView.hidden = YES;
    [self switchLiveAction:self.liveBtn];
    self.loginBtn.layer.cornerRadius = self.loginBtn.bounds.size.height * 0.5;
}

#pragma mark - UIViewController+UIViewControllerRotation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//登录窗口只支持竖屏方向
}

#pragma mark - Notification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - GestureRecognizer
- (void)addGestureRecognizer {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
}

- (void)tapAction {
    [self.view endEditing:YES];
}

#pragma mark - IBAction
- (IBAction)switchLiveAction:(UIButton *)sender {
    [self switchToLiveUI];
}

- (IBAction)switchVodAction:(UIButton *)sender {
    [self switchToVodUI];
}

- (IBAction)loginButtonClickAction:(UIButton *)sender {
    [self tapAction];
    [self loginRequest];
}

- (IBAction)textEditChangedAction:(id)sender {
    [self refreshLoginBtnUI];
}

#pragma mark - UI control
- (void)refreshLoginBtnUI {
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

- (void)switchToLiveUI {
    if (self.liveSelectView.hidden) {
        [self switchScenes:NO];
        NSArray *liveLoginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:NSUserDefaultKey_LiveLoginInfo];
        if (liveLoginInfo) {
            self.channelIdTF.text = liveLoginInfo[0];
            self.appIDTF.text = liveLoginInfo[1];
            self.userIDTF.text = liveLoginInfo[2];
            self.appSecretTF.text = liveLoginInfo[3];
        } else {
            PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
            self.channelIdTF.text = liveConfig.channelId;
            self.appIDTF.text = liveConfig.appId;
            self.userIDTF.text = liveConfig.userId;
            self.appSecretTF.text = liveConfig.appSecret;
        }
        [self refreshLoginBtnUI];
    }
}

- (void)switchToVodUI {
    if (self.vodSelectView.hidden) {
        [self switchScenes:YES];
        
        NSArray *vodLoginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:NSUserDefaultKey_VodLoginInfo];
        if (vodLoginInfo) {
            self.vIdTF.text = vodLoginInfo[0];
            self.appIDTF.text = vodLoginInfo[1];
        } else {
            PLVVodConfig *vodConfig = [PLVVodConfig sharedInstance];
            PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
            self.vIdTF.text = vodConfig.vodId;
            self.appIDTF.text = liveConfig.appId;
        }
        [self refreshLoginBtnUI];
    }
}

- (void)switchScenes:(BOOL)flag {
    CGFloat y = flag ? 365.0 : 460.0;
    
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

#pragma mark - network request
- (void)loginRequest {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud.label setText:@"登录中..."];
    __weak typeof(self) weakSelf = self;
    if (!self.liveSelectView.hidden) {
        [[NSUserDefaults standardUserDefaults] setObject:@[self.channelIdTF.text, self.appIDTF.text, self.userIDTF.text, self.appSecretTF.text] forKey:NSUserDefaultKey_LiveLoginInfo];
        
        [PLVLiveVideoAPI verifyPermissionWithChannelId:self.channelIdTF.text.integerValue vid:nil appId:self.appIDTF.text userId:self.userIDTF.text appSecret:self.appSecretTF.text completion:^{
            [PLVLiveVideoAPI liveStatus:self.channelIdTF.text completion:^(BOOL liveing, NSString *liveType) {
                [hud hideAnimated:YES];
                [weakSelf presentToLiveViewControllerFromViewController:weakSelf liveing:liveing lievType:liveType];
            } failure:^(NSError *error) {
                [hud hideAnimated:YES];
                [PCCUtils presentAlertViewController:nil message:error.localizedDescription inViewController:weakSelf];
            }];
        } failure:^(NSError *error) {
            [hud hideAnimated:YES];
            [weakSelf presentToAlertViewControllerWithError:error inViewController:weakSelf];
        }];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@[self.vIdTF.text, self.appIDTF.text] forKey:NSUserDefaultKey_VodLoginInfo];
        
        [PLVLiveVideoAPI verifyPermissionWithChannelId:0 vid:self.vIdTF.text appId:self.appIDTF.text userId:self.userIDTF.text appSecret:nil completion:^{
            [PLVLiveVideoAPI getVodType:self.vIdTF.text completion:^(BOOL vodType) {
                [hud hideAnimated:YES];
                [weakSelf presentToVodViewControllerFromViewController:weakSelf vodType:vodType];
            } failure:^(NSError *error) {
                [hud hideAnimated:YES];
                [weakSelf presentToAlertViewControllerWithError:error inViewController:weakSelf];
            }];
        } failure:^(NSError *error) {
            [hud hideAnimated:YES];
            [weakSelf presentToAlertViewControllerWithError:error inViewController:weakSelf];
        }];
    }
}

#pragma mark - present ViewController
- (void)presentToLiveViewControllerFromViewController:(UIViewController *)vc liveing:(BOOL)liveing lievType:(NSString *)liveType {
    //必需先设置 PLVLiveVideoConfig 单例里需要的信息，因为在后面的加载中需要使用
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    liveConfig.channelId = self.channelIdTF.text;
    liveConfig.appId = self.appIDTF.text;
    liveConfig.userId = self.userIDTF.text;
    liveConfig.appSecret = self.appSecretTF.text;
    
    PLVLiveViewController *liveVC = [PLVLiveViewController new];
    liveVC.liveType = [@"ppt" isEqualToString:liveType] ? PLVLiveViewControllerTypeCloudClass : PLVLiveViewControllerTypeLive;
    liveVC.playAD = !liveing;
    [vc presentViewController:liveVC animated:YES completion:nil];
}

- (void)presentToVodViewControllerFromViewController:(UIViewController *)vc vodType:(BOOL)vodType {
    //必需先设置 PLVVodConfig 单例里需要的信息，因为在后面的加载中需要使用
    PLVVodConfig *vodConfig = [PLVVodConfig sharedInstance];
    vodConfig.vodId = self.vIdTF.text;
    vodConfig.appId = self.appIDTF.text;
    
    PLVVodViewController *vodVC = [PLVVodViewController new];
    vodVC.vodType = vodType ? PLVVodViewControllerTypeCloudClass : PLVVodViewControllerTypeLive;
    [vc presentViewController:vodVC animated:YES completion:nil];
}

- (void)presentToAlertViewControllerWithError:(NSError *)error inViewController:(UIViewController *)vc {
    [PCCUtils presentAlertViewController:nil message:error.localizedDescription inViewController:vc];
}

#pragma mark - keyboard control
- (void)keyboardWillShow:(NSNotification *)notification {
    [self followKeyboardAnimation:UIEdgeInsetsMake(-110.0, 0.0, 110.0, 0.0) duration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] flag:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self followKeyboardAnimation:UIEdgeInsetsZero duration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] flag:NO];
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

#pragma mark - textfield input validate
- (BOOL)checkTextField:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (textField.text.length == 0) {
        return YES;
    }
    return NO;
}

@end
