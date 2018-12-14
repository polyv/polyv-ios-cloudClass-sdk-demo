//
//  PLVTextInputView.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/9/7.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVTextInputView.h"
#import "objc/runtime.h"
#import <Masonry/Masonry.h>
#import "PLVFaceView.h"
#import "PLVEmojiModel.h"
#import "PLVKeyboardMoreView.h"

#define PLVTextBackedStringAttributeName    @"PLVEmojiText"

static BOOL nickNameSetted = NO;

@interface PLVTextView : UITextView

@property (nonatomic, strong) UIFont *plvFont;
@property (nonatomic, assign) CGRect emojiFrame;
@property (nonatomic, strong) NSDictionary *plvAttributes;
@property (nonatomic, strong) NSAttributedString *emptyContent;
@property (nonatomic, strong) NSAttributedString *placeholderContent;

- (NSString *)plvTextForRange:(NSRange)range;

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrStr;

- (NSAttributedString *)convertTextWithEmoji:(NSString *)text;

@end

@implementation PLVTextView

#pragma mark - public
- (NSString *)plvTextForRange:(NSRange)range {
    NSMutableString *result = [[NSMutableString alloc] init];
    NSString *string = self.attributedText.string;
    [self.attributedText enumerateAttribute:PLVTextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        NSString *backed = value;
        if (backed) {
            for (NSUInteger i = 0; i < range.length; i++) {
                [result appendString:backed];
            }
        } else {
            [result appendString:[string substringWithRange:range]];
        }
    }];
    return result;
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrStr {
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    [content replaceCharactersInRange:range withAttributedString:attrStr];
    self.attributedText = content;
}

- (NSAttributedString *)convertTextWithEmoji:(NSString *)text {
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text attributes:self.plvAttributes];
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\[]{1,5}\\]" options:kNilOptions error:nil];
    NSArray<NSTextCheckingResult *> *matchArray = [regularExpression matchesInString:attributeStr.string options:kNilOptions range:NSMakeRange(0, attributeStr.length)];
    NSUInteger offset = 0;
    for (NSTextCheckingResult *result in matchArray) {
        NSRange range = NSMakeRange(result.range.location - offset, result.range.length);
        NSTextAttachment *attachMent = [[NSTextAttachment alloc] init];
        NSString *imageText = [attributeStr.string substringWithRange:range];
        NSString *imageName = [PLVEmojiModelManager sharedManager].emotionDictionary[imageText];
        attachMent.image = [[PLVEmojiModelManager sharedManager] imageForEmotionPNGName:imageName];
        attachMent.bounds = self.emojiFrame;
        
        NSMutableAttributedString *emojiAttrStr = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachMent]];
        [emojiAttrStr addAttribute:PLVTextBackedStringAttributeName value:imageText range:NSMakeRange(0, emojiAttrStr.length)];
        [emojiAttrStr addAttributes:self.plvAttributes range:NSMakeRange(0, emojiAttrStr.length)];
        [attributeStr replaceCharactersInRange:range withAttributedString:emojiAttrStr];
        offset += result.range.length - emojiAttrStr.length;
    }
    
    return attributeStr;
}

#pragma mark - UIResponder
- (void)cut:(id)sender {
    NSString *string = [self plvTextForRange:self.selectedRange];
    if (string.length) {
        [UIPasteboard generalPasteboard].string = string;
        
        NSRange cursorRange = self.selectedRange;
        [self replaceCharactersInRange:cursorRange withAttributedString:self.emptyContent];
        self.selectedRange = NSMakeRange(cursorRange.location, 0);
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
    }
}

- (void)copy:(id)sender {
    NSString *string = [self plvTextForRange:self.selectedRange];
    if (string.length) {
        [UIPasteboard generalPasteboard].string = string;
    }
}

- (void)paste:(id)sender {
    NSString *string = UIPasteboard.generalPasteboard.string;
    if (string.length) {
        NSAttributedString *attrStr = [self convertTextWithEmoji:string];
        
        NSRange cursorRange = self.selectedRange;
        [self replaceCharactersInRange:cursorRange withAttributedString:attrStr];
        self.selectedRange = NSMakeRange(cursorRange.location + attrStr.length, 0);
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
    }
}

@end

@interface PLVTextInputView () <UITextViewDelegate, DXFaceDelegate, PLVKeyboardMoreViewDelegate>

@property (nonatomic, assign) CGFloat bottomHeight;
@property (nonatomic, assign) CGFloat lastTextViewHeight;
@property (nonatomic, strong) UIButton *userBtn;
@property (nonatomic, strong) PLVTextView *textView;
@property (nonatomic, strong) UIButton *emojiBtn;
@property (nonatomic, strong) UIButton *flowerBtn;
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong) PLVFaceView *faceView;
@property (nonatomic, assign) CGRect faceOriginRect;
@property (nonatomic, strong) PLVKeyboardMoreView *moreView;
@property (nonatomic, assign) CGRect moreOriginRect;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation PLVTextInputView

#pragma mark - life cycle
+ (void)load {//必须，runtime置换UIInputWindowController的supportedInterfaceOrientations方法，防止横屏时，键盘接收到弹出事件崩溃
    Method fromMethod = class_getInstanceMethod(objc_getClass("UIInputWindowController"), @selector(supportedInterfaceOrientations));
    Method toMethod = class_getInstanceMethod([self class], @selector(app_supportedInterfaceOrientations));
    method_exchangeImplementations(fromMethod, toMethod);
}
    
- (UIInterfaceOrientationMask)app_supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public
- (void)loadViews:(PLVTextInputViewType)type enableMore:(BOOL)enableMore {
    if (self.textView == nil) {
        self.backgroundColor = [UIColor colorWithRed:245.0 / 255.0 green:245.0 / 255.0 blue:247.0 / 255.0 alpha:1.0];
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        
        CGRect rect = CGRectMake(48.0, 6.5, self.bounds.size.width - 96.0, 37.0);
        if (type == PLVTextInputViewTypePrivate) {
            rect = CGRectMake(10.0, 6.5, self.bounds.size.width - 20.0, 37.0);
        }
        self.textView = [[PLVTextView alloc] initWithFrame:rect];
        self.textView.delegate = self;
        self.textView.backgroundColor = [UIColor whiteColor];
        self.textView.returnKeyType = UIReturnKeySend;
        self.textView.scrollEnabled = NO;
        self.textView.showsHorizontalScrollIndicator = NO;
        UIEdgeInsets oldTextContainerInset = self.textView.textContainerInset;
        oldTextContainerInset.right = 24.0;
        self.textView.textContainerInset = oldTextContainerInset;
        self.textView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
        self.textView.layer.borderWidth = 0.65f;
        self.textView.layer.cornerRadius = 6.0f;
        if (@available(iOS 11.0, *)) {
            self.textView.textDragInteraction.enabled = NO;
        }
        
        self.textView.plvFont = [UIFont systemFontOfSize:17.0];
        self.textView.emojiFrame = CGRectMake(0.0, self.textView.plvFont.descender, self.textView.plvFont.lineHeight, self.textView.plvFont.lineHeight);
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 2.0;
        paragraphStyle.minimumLineHeight = 19.0;
        paragraphStyle.maximumLineHeight = 30.0;
        self.textView.plvAttributes = @{NSFontAttributeName : self.textView.plvFont, NSParagraphStyleAttributeName : paragraphStyle};
        self.textView.emptyContent = [[NSAttributedString alloc] initWithString:@"" attributes:self.textView.plvAttributes];
        self.textView.placeholderContent = [[NSMutableAttributedString alloc] initWithString:@"我也来聊几句..." attributes:@{NSFontAttributeName : self.textView.plvFont, NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
        
        [self addSubview:self.textView];
        [self placeholderTextView];
        self.bottomHeight = self.bounds.size.height - (self.textView.frame.origin.y * 2.0 + self.textView.frame.size.height);
        self.lastTextViewHeight = ceilf([self.textView sizeThatFits:self.textView.frame.size].height);
        
        UIEdgeInsets emojiMagin = UIEdgeInsetsMake(-1.0, -1.0, self.bottomHeight + 11.0, 15.0);
        if (type < PLVTextInputViewTypePrivate) {
            self.userBtn = [self addButton:@"plv_input_user_normal.png" selectedImgName:@"plv_input_user_select.png" action:@selector(onlyTeacherAction:) inView:self];
            [self remakeConstraints:self.userBtn margin:UIEdgeInsetsMake(-1.0, 10.0, self.bottomHeight + 11.0, -1.0) size:CGSizeMake(28.0, 28.0) baseView:self];
            
            self.flowerBtn = [self addButton:type == PLVTextInputViewTypeNormalPublic ? @"plv_btn_like.png" : @"plv_flower.png" selectedImgName:nil action:@selector(flowerAction:) inView:self];
            [self remakeConstraints:self.flowerBtn margin:UIEdgeInsetsMake(-1.0, -1.0, self.bottomHeight + 11.0, 10.0) size:CGSizeMake(28.0, 28.0) baseView:self];
            
            self.moreBtn = [self addButton:@"plv_more.png" selectedImgName:nil action:@selector(moreAction:) inView:self];
            self.moreBtn.hidden = YES;
            
            emojiMagin = UIEdgeInsetsMake(-1.0, -1.0, self.bottomHeight + 11.0, 53.0);
        }
        
        self.emojiBtn = [self addButton:@"plv_emoji_off" selectedImgName:@"plv_emoji_on" action:@selector(emojiAction:) inView:self];
        self.emojiBtn.alpha = 0.5;
        [self remakeConstraints:self.emojiBtn margin:emojiMagin size:CGSizeMake(28.0, 28.0) baseView:self];
        
        CGFloat faceHeight = 200.0 + self.bottomHeight;
        CGFloat moreHeight = 104.0 + self.bottomHeight;
        if ([@"iPad" isEqualToString:[UIDevice currentDevice].model]) {
            faceHeight += 55.0;
            moreHeight += 55.0;
        }
        self.faceOriginRect = CGRectMake(0.0, self.frame.origin.y + self.frame.size.height, self.bounds.size.width, faceHeight);
        self.faceView = [[PLVFaceView alloc] initWithFrame:self.faceOriginRect];
        self.faceView.delegate = self;
        [self.superview addSubview:self.faceView];
        
        self.moreOriginRect = CGRectMake(0.0, self.frame.origin.y + self.frame.size.height, self.bounds.size.width, moreHeight);
        self.moreView = [[PLVKeyboardMoreView alloc] initWithFrame:self.moreOriginRect];
        self.moreView.delegate = self;
        [self.superview addSubview:self.moreView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    } else if (type < PLVTextInputViewTypePrivate && enableMore) {
        self.textView.frame = CGRectMake(48.0, 7.0, self.bounds.size.width - 134.0, 37.0);
        [self remakeConstraints:self.flowerBtn margin:UIEdgeInsetsMake(-1.0, -1.0, self.bottomHeight + 11.0, 48.0) size:CGSizeMake(28.0, 28.0) baseView:self];
        self.moreBtn.hidden = NO;
        [self remakeConstraints:self.moreBtn margin:UIEdgeInsetsMake(-1.0, -1.0, self.bottomHeight + 11.0, 10.0) size:CGSizeMake(28.0, 28.0) baseView:self];
        [self remakeConstraints:self.emojiBtn margin:UIEdgeInsetsMake(-1.0, -1.0, self.bottomHeight + 11.0, 91.0) size:CGSizeMake(28.0, 28.0) baseView:self];
    }
}

- (void)nickNameSetted:(BOOL)setted {
    nickNameSetted = setted;
}

- (void)tapAction {
    [self.superview removeGestureRecognizer:self.tap];
    self.textView.inputView = nil;
    self.emojiBtn.selected = NO;
    self.moreBtn.selected = NO;
    [self followKeyboardAnimation:@{UIKeyboardAnimationDurationUserInfoKey : @(0.3), UIKeyboardAnimationCurveUserInfoKey : @(UIViewAnimationOptionCurveEaseInOut)} flag:NO];
    [self endEditing:YES];
}

#pragma mark - Action
- (IBAction)onlyTeacherAction:(id)sender {
    self.userBtn.selected = !self.userBtn.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(textInputView:onlyTeacher:)]) {
        [self.delegate textInputView:self onlyTeacher:self.userBtn.selected];
    }
}

- (IBAction)emojiAction:(id)sender {
    if (nickNameSetted) {
        self.emojiBtn.selected = !self.emojiBtn.selected;
        self.moreBtn.selected = NO;
        if(self.emojiBtn.selected) {
            [self.superview addGestureRecognizer:self.tap];
            self.textView.inputView = [[UIView alloc] initWithFrame:CGRectZero];
            [self.textView reloadInputViews];
            if (self.textView.isFirstResponder) {
                [self.textView resignFirstResponder];
            }
            [self followKeyboardAnimation:@{UIKeyboardAnimationDurationUserInfoKey : @(0.3), UIKeyboardAnimationCurveUserInfoKey : @(UIViewAnimationOptionCurveEaseInOut)} flag:NO];
            [self.textView becomeFirstResponder];
        } else {
            self.textView.inputView = nil;
            [self.textView reloadInputViews];
            [self.textView becomeFirstResponder];
        }
    }
    [self nickNameCallback];
}

- (IBAction)flowerAction:(id)sender {
    if (nickNameSetted) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(sendFlower:)]) {
            [self.delegate sendFlower:self];
        }
    }
    [self nickNameCallback];
}

- (IBAction)moreAction:(id)sender {
    if (nickNameSetted) {
        [self.superview addGestureRecognizer:self.tap];
        self.moreBtn.selected = YES;
        [self.textView resignFirstResponder];
        if (self.textView.isFirstResponder && !self.emojiBtn.selected) {
            [self endEditing:YES];
        } else {
            self.emojiBtn.selected = NO;
            self.textView.inputView = nil;
            [self followKeyboardAnimation:@{UIKeyboardAnimationDurationUserInfoKey : @(0.3), UIKeyboardAnimationCurveUserInfoKey : @(UIViewAnimationOptionCurveEaseInOut)} flag:NO];
        }
        [self placeholderTextView];
    }
    [self nickNameCallback];
}

#pragma mark - private
- (UIButton *)addButton:(NSString *)normalImgName selectedImgName:(NSString *)selectedImgName action:(SEL)action inView:(UIView *)view {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (normalImgName) {
        [btn setImage:[UIImage imageNamed:normalImgName] forState:UIControlStateNormal];
    }
    if (selectedImgName) {
        [btn setImage:[UIImage imageNamed:selectedImgName] forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
    return btn;
}

//UIEdgeInsets margin的top, left, bottom, right都为正值，负值代表不计算该边距的约束
- (void)remakeConstraints:(UIView *)view margin:(UIEdgeInsets)margin size:(CGSize)size baseView:(UIView *)baseView {
    [view mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (margin.top >= 0.0) {
            make.top.equalTo(baseView.mas_top).offset(margin.top);
        }
        if (margin.left >= 0.0) {
            make.left.equalTo(baseView.mas_left).offset(margin.left);
        }
        if (margin.bottom >= 0.0) {
            make.bottom.equalTo(baseView.mas_bottom).offset(-margin.bottom);
        }
        if (margin.right >= 0.0) {
            make.right.equalTo(baseView.mas_right).offset(-margin.right);
        }
        make.width.mas_equalTo(size.width);
        make.height.mas_equalTo(size.height);
    }];
}

- (void)followKeyboardAnimation:(BOOL)flag {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textInputView:followKeyboardAnimation:)]) {
        [self.delegate textInputView:self followKeyboardAnimation:flag];
    }
}

- (void)followKeyboardAnimation:(NSDictionary *)userInfo flag:(BOOL)flag {
    __weak typeof(self) weakSelf = self;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    duration = duration < 0.3 ? 0.3 : duration;
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect rect = weakSelf.frame;
        CGRect faceRect = weakSelf.faceView.frame;
        CGRect moreRect = weakSelf.moreView.frame;
        if (flag) {
            CGRect keyBoardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
            CGRect covertRect = [[UIApplication sharedApplication].delegate.window convertRect:keyBoardFrame toView:weakSelf.superview];
            rect.origin.y = covertRect.origin.y - rect.size.height + weakSelf.bottomHeight;
            faceRect.origin.y = weakSelf.faceOriginRect.origin.y;
            moreRect.origin.y = weakSelf.moreOriginRect.origin.y;
        } else {
            if (weakSelf.emojiBtn.selected) {
                faceRect.origin.y = weakSelf.faceOriginRect.origin.y - faceRect.size.height;
                moreRect.origin.y = weakSelf.moreOriginRect.origin.y;
                rect.origin.y = faceRect.origin.y - rect.size.height + weakSelf.bottomHeight;
            } else if (self.moreBtn.selected) {
                faceRect.origin.y = weakSelf.faceOriginRect.origin.y;
                moreRect.origin.y = weakSelf.moreOriginRect.origin.y - moreRect.size.height;
                rect.origin.y = moreRect.origin.y - rect.size.height + weakSelf.bottomHeight;
            } else {
                faceRect.origin.y = weakSelf.faceOriginRect.origin.y;
                moreRect.origin.y = weakSelf.moreOriginRect.origin.y;
                rect.origin.y = faceRect.origin.y - rect.size.height;
            }
        }
        [self followKeyboardAnimation:flag ? flag : weakSelf.emojiBtn.selected];
        
        weakSelf.frame = rect;
        weakSelf.faceView.frame = faceRect;
        weakSelf.moreView.frame = moreRect;
        [weakSelf layoutIfNeeded];
    } completion:nil];
}

- (void)checkSendBtnEnable:(BOOL)enable {
    [self.faceView sendBtnEnable:enable];
    self.textView.enablesReturnKeyAutomatically = !enable;
}

- (void)placeholderTextView {
    if (self.textView.attributedText.length == 0 && !self.emojiBtn.selected) {
        self.textView.attributedText = self.textView.placeholderContent;
        [self checkSendBtnEnable:NO];
    }
}

- (void)nickNameCallback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textInputView:nickNameSetted:)]) {
        [self.delegate textInputView:self nickNameSetted:nickNameSetted];
    }
}

- (void)sendText {
    if (self.textView.attributedText.length > 0 && self.delegate && [self.delegate respondsToSelector:@selector(textInputView: didSendText:)]) {
        [self.delegate textInputView:self didSendText:[self.textView plvTextForRange:NSMakeRange(0, self.textView.attributedText.length)]];
        self.textView.attributedText = self.textView.emptyContent;
        [self textViewDidChange:self.textView];
    }
}

#pragma mark - UIKeyboardNotification
- (void)keyboardWillShow:(NSNotification *)notification {
    //TODO：中文键盘或第三方键盘第一次弹出时会收到两至三次弹出事件通知，现无法区分这种情况，会导致动画效果不连续流畅，暂无解决方案
    if (self.textView.isFirstResponder && !self.emojiBtn.selected && !self.moreBtn.selected) {
        [self.superview addGestureRecognizer:self.tap];
        [self followKeyboardAnimation:notification.userInfo flag:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (self.textView.isFirstResponder) {//必须的判断，当PLVTextInputView多次实例化后，防止多次处理键盘事件的通知
        [self followKeyboardAnimation:notification.userInfo flag:NO];
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self nickNameCallback];
    if (nickNameSetted) {
        if (self.textView.textColor == [UIColor lightGrayColor]) {
            self.textView.textColor = [UIColor blackColor];
            self.textView.attributedText = self.textView.emptyContent;
        }
        [self checkSendBtnEnable:self.textView.attributedText.length > 0];
        self.moreBtn.selected = NO;
        return YES;
    } else {
        return NO;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self placeholderTextView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self sendText];
        [self.textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self checkSendBtnEnable:self.textView.attributedText.length > 0];
    CGFloat height = ceilf([self.textView sizeThatFits:self.textView.frame.size].height);
    if (self.lastTextViewHeight != height) {
        self.lastTextViewHeight = height;
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            [weakSelf.textView setContentOffset:CGPointMake(0.0, 1.0) animated:NO];//必须，防止换行时文字的抖动
            
            CGRect textRect = weakSelf.textView.frame;
            textRect.size.height = height;
            weakSelf.textView.frame = textRect;
            
            CGRect rect = weakSelf.frame;
            CGFloat maxY = rect.origin.y + rect.size.height;
            rect.size.height = textRect.origin.y * 2.0 + textRect.size.height + weakSelf.bottomHeight;
            rect.origin.y = maxY - rect.size.height;
            weakSelf.frame = rect;
            [weakSelf layoutIfNeeded];
        } completion:nil];
    }
}

#pragma mark - DXFaceDelegate
- (void)selectedEmoji:(PLVEmojiModel *)emojiModel {
    NSRange cursorRange = self.textView.selectedRange;
    NSAttributedString *emojiAttrStr = [self.textView convertTextWithEmoji:emojiModel.text];
    [self.textView replaceCharactersInRange:cursorRange withAttributedString:emojiAttrStr];
    self.textView.selectedRange = NSMakeRange(cursorRange.location + emojiAttrStr.length, 0);
    [self textViewDidChange:self.textView];
}

- (void)deleteEvent {
    NSRange cursorRange = self.textView.selectedRange;
    if (self.textView.attributedText.length > 0 && cursorRange.location > 0) {
        [self.textView replaceCharactersInRange:NSMakeRange(cursorRange.location - 1, 1) withAttributedString:self.textView.emptyContent];
         self.textView.selectedRange = NSMakeRange(cursorRange.location - 1, 0);
        [self textViewDidChange:self.textView];
    }
}

- (void)sendEvent {
    [self sendText];
    [self tapAction];
}

#pragma mark -PLVKeyboardMoreViewDelegate
- (void)openAlbum:(PLVKeyboardMoreView *)moreView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(openAlbum:)]) {
        [self.delegate openAlbum:self];
    }
}

- (void)shoot:(PLVKeyboardMoreView *)moreView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(shoot:)]) {
        [self.delegate shoot:self];
    }
}
@end
