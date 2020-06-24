//
//  PLVPlayerInputView.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/6/10.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVPlayerInputView.h"

#import "PCCUtils.h"
#import <Masonry/Masonry.h>

#define MAX_STARWORDS_LENGTH 100

@interface PLVPlayerInputView ()<UITextFieldDelegate>

@property (nonatomic, strong) UITextField * textF;
@property (nonatomic, strong) UIButton * sendBtn;
@property (nonatomic, strong) UIButton * backBtn;

@end

@implementation PLVPlayerInputView

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self createUI];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:tap];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews{
    float sw = [UIScreen mainScreen].bounds.size.width;
    float sh = [UIScreen mainScreen].bounds.size.height;
    BOOL hor = sw >= sh ? YES : NO;
    
    if (!hor) {
        [self hide];
    }
}

#pragma mark - ----------------- < Private Method > -----------------
- (void)createUI{
    self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7];
    
    [self addSubview:self.textF];
    [self addSubview:self.sendBtn];
    [self addSubview:self.backBtn];
    
    self.userInteractionEnabled = NO;
    self.alpha = 0;
    
    [self.textF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.height.offset(32);
        make.width.mas_equalTo(self.mas_width).multipliedBy(0.55);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(0);
        } else {
            make.bottom.offset(-26);
        }
    }];
    
    [self.sendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset(64);
        make.height.offset(32);
        make.left.mas_equalTo(self.textF.mas_right).offset(10);
        make.centerY.mas_equalTo(self.textF.mas_centerY).offset(0);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.offset(44);
        if (@available(iOS 11.0, *)) {
            make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(0);
        } else {
            make.right.offset(-40);
        }
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(20);
        } else {
            make.top.offset(20);
        }
    }];

}

#pragma mark Getter
- (UITextField *)textF{
    if (_textF == nil) {
        _textF = [[UITextField alloc]init];
        _textF.textColor = [UIColor whiteColor];
        _textF.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        _textF.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.3];
        _textF.layer.cornerRadius = 17;
        _textF.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 16, 0)];
        _textF.leftViewMode = UITextFieldViewModeAlways;
        _textF.delegate = self;
        [_textF addTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    }
    return _textF;
}

- (UIButton *)sendBtn{
    if (_sendBtn == nil) {
        _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendBtn setTitle:@"发送" forState:UIControlStateNormal];
        _sendBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:13];
        [_sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        _sendBtn.layer.cornerRadius = 16;
        _sendBtn.layer.masksToBounds = YES;
        _sendBtn.enabled = NO;
        [_sendBtn setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.3]];
        [_sendBtn addTarget:self action:@selector(sendBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendBtn;
}

- (UIButton *)backBtn{
    if (_backBtn == nil) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[PCCUtils getPlayerSkinImage:@"plv_input_back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

#pragma mark - ----------------- < Event > -----------------
- (void)tapAction{
    [self hide];
}

- (void)sendBtnClick:(UIButton *)btn{
    if (self.textF.text.length > 0 && self.delegate && [self.delegate respondsToSelector:@selector(playerInputView:didSendText:)]) {
        [self.delegate playerInputView:self didSendText:self.textF.text];
    
        self.textF.text = @"";
        [self hide];
    }
}

- (void)backBtnClick:(UIButton *)btn{
    [self hide];
}

- (void)textFieldDidChange{
    
    NSString *toBeString = _textF.text;
    
    //获取高亮部分
    UITextRange *selectedRange = [_textF markedTextRange];
    UITextPosition *position = [_textF positionFromPosition:selectedRange.start offset:0];
    
    //没有高亮选择的字，则对已输入的文字进行字数统计和限制
    if (!position){
        
        if (toBeString.length > 0) {
            self.sendBtn.enabled = YES;
            [self.sendBtn setBackgroundColor:UIColorFromRGB(0x2196F3)];
        }else{
            self.sendBtn.enabled = NO;
            [self.sendBtn setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.3]];
        }
        
        /*
        if (toBeString.length > MAX_STARWORDS_LENGTH){
            NSRange rangeIndex = [toBeString rangeOfComposedCharacterSequenceAtIndex:MAX_STARWORDS_LENGTH];
            if (rangeIndex.length == 1){
                _textF.text = [toBeString substringToIndex:MAX_STARWORDS_LENGTH];
            }else{
                NSRange rangeRange = [toBeString rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, MAX_STARWORDS_LENGTH)];
                _textF.text = [toBeString substringWithRange:rangeRange];
            }
        }
        */
    
    }
}

- (void)keyboardWasShow:(NSNotification *)noti{
    [UIView animateWithDuration:0.2 animations:^{
        [self.textF mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
            make.height.offset(32);
            make.width.mas_equalTo(self.mas_width).multipliedBy(0.55);
            if (@available(iOS 11.0, *)) {
                make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(26);
            } else {
                make.top.offset(26);
            }
        }];

        [self layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)noti {
    [UIView animateWithDuration:0.1 animations:^{
        [self.textF mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
            make.height.offset(32);
            make.width.mas_equalTo(self.mas_width).multipliedBy(0.55);
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(0);
            } else {
                make.bottom.offset(-26);
            }
        }];
        
        [self layoutIfNeeded];
    }];
}

#pragma mark - ----------------- < Public Method > -----------------
- (void)show{
    self.userInteractionEnabled = YES;
    
    [self.textF becomeFirstResponder];

    [UIView animateWithDuration:0.33 animations:^{
        self.alpha = 1;
    }];
}

- (void)hide{
    self.userInteractionEnabled = NO;
    
    [self.textF resignFirstResponder];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
    }];
}


@end
