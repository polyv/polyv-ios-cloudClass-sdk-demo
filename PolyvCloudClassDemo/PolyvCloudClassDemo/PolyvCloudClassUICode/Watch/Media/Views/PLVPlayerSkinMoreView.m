//
//  PLVPlayerSkinMoreView.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/6/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVPlayerSkinMoreView.h"
#import <Masonry/Masonry.h>
#import "PCCUtils.h"

#define CellVH 48.0

@protocol PLVMoreCellViewDelegate;

/// 更多弹窗中每行视图
@interface PLVMoreCellView : UIView

/// delegate
@property (nonatomic, weak) id<PLVMoreCellViewDelegate> delegate;

@property (nonatomic, strong) UILabel * titleLb;
@property (nonatomic, strong) NSMutableArray <UIButton *>* btnArr;
@property (nonatomic, strong) NSArray <NSString *>* btnSelectedTextArr; // 选中状态下文本，适用于无需根据回调的文本变更
@property (nonatomic, strong) UIView * lineV;
@property (nonatomic, strong) UIButton * curBtn;
@property (nonatomic, assign) BOOL selectedMode; // 按钮选中模式 YES-选中状态下点击触发回调 NO-选中状态下点击不触发回调

/// 创建按钮
- (void)createBtnsWithStrArr:(NSArray <NSString *>*)btnStrArr;
/// 指定当前选中的按钮，不触发回调
- (void)changeCurBtnTo:(UIButton *)btn;

@end

@protocol PLVMoreCellViewDelegate <NSObject>

@optional

/// 按钮被点击
- (void)moreCellView:(PLVMoreCellView *)cellView btnClick:(UIButton *)btn;

@end



@interface PLVPlayerSkinMoreView ()<PLVMoreCellViewDelegate>

@property (nonatomic, strong) UIView * bgV;

@property (nonatomic, strong) PLVMoreCellView * audioCellV;
@property (nonatomic, strong) PLVMoreCellView * lineCellV;
@property (nonatomic, strong) PLVMoreCellView * codeRateCellV;
@property (nonatomic, strong) PLVMoreCellView * speedCellV;
@property (nonatomic, strong) UIButton * backBtn;
@property (nonatomic, assign) CGFloat lineCellHeight;

@end

@implementation PLVPlayerSkinMoreView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self createUI];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)layoutSubviews{
    float sw = [UIScreen mainScreen].bounds.size.width;
    float sh = [UIScreen mainScreen].bounds.size.height;
    BOOL hor = sw >= sh ? YES : NO;

    float lrPadding = 28;
    if (sw == 320) { lrPadding = 10; }
    
    if (hor) {
        self.backBtn.hidden = YES;
    }else{
        self.backBtn.hidden = NO;
    }
    
    [self.bgV mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (hor) {
            make.top.bottom.offset(0);
            make.left.mas_equalTo(self.mas_centerX).offset(0);
            make.right.offset(0);
        }else{
            make.edges.offset(0);
        }
    }];
    
    if (self.type == PLVPlayerSkinMoreViewTypeNormalLive ||
        self.type == PLVPlayerSkinMoreViewTypeCloudClassLive) {
        self.speedCellV.hidden = YES;
        
        [self.audioCellV mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(lrPadding);
            make.right.offset(-lrPadding);
            make.height.offset(CellVH);
            if (hor) {
                make.top.offset(56);
            }else{
                make.bottom.mas_equalTo(self.lineCellV.mas_top).offset(0);
            }
        }];
        
        [self layoutLineCellV];
        
        [self.codeRateCellV mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(lrPadding);
            make.right.offset(-lrPadding);
            make.height.offset(CellVH);
            make.top.mas_equalTo(self.lineCellV.mas_bottom).offset(0);
        }];
        
    }else if (self.type == PLVPlayerSkinMoreViewTypeNormalVod ||
              self.type == PLVPlayerSkinMoreViewTypeCloudClassVod){
        self.audioCellV.hidden = YES;
        self.lineCellV.hidden = YES;
        self.codeRateCellV.hidden = YES;
        
        [self.speedCellV mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(lrPadding);
            make.right.offset(-lrPadding);
            make.height.offset(CellVH * 2);
            if (hor) {
                make.top.offset(40);
            }else{
                make.centerY.offset(0);
            }
        }];
        
    }
    [self refreshCellViewLine];
}

- (void)layoutLineCellV {
    float sw = [UIScreen mainScreen].bounds.size.width;
    float sh = [UIScreen mainScreen].bounds.size.height;
    BOOL hor = sw >= sh ? YES : NO;
    
    float lrPadding = 28;
    if (sw == 320) { lrPadding = 10; }
    
    [self.lineCellV mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(lrPadding);
        make.right.offset(-lrPadding);
        make.height.offset(self.lineCellHeight);
        if (hor) {
            make.top.mas_equalTo(self.audioCellV.mas_bottom).offset(0);
        }else{
            make.centerY.offset(0);
        }
    }];
}

#pragma mark - ----------------- < Private Method > -----------------
- (void)createUI{
    
    self.alpha = 0;
    self.clipsToBounds = YES;
    self.userInteractionEnabled = NO;
    
    [self addSubview:self.bgV];
    [self addSubview:self.backBtn];

    self.audioCellV = [self createCellView:@"模式" btnStr:@[@"仅听声音"]];
    self.audioCellV.selectedMode = YES;
    
    self.lineCellV = [self createCellView:@"线路" btnStr:@[@"线路1",@"线路2"]];
    self.lineCellV.hidden = YES;

    self.codeRateCellV = [self createCellView:@"清晰度" btnStr:@[]];
    self.codeRateCellV.hidden = YES;
    self.codeRateCellV.lineV.hidden = YES;
    
    self.speedCellV = [self createCellView:@"倍速" btnStr:@[@"1 X",@"1.25 X",@"1.5 X",@"2 X"]];
    self.speedCellV.lineV.hidden = YES;
    [self.speedCellV changeCurBtnTo:self.speedCellV.btnArr.firstObject];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.with.offset(44);
        make.right.offset(-8);
        make.top.offset(0);
    }];
    
}

- (UIView *)bgV{
    if (_bgV == nil) {
        _bgV = [[UIView alloc]init];
        _bgV.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7];
    }
    return _bgV;
}

- (UIButton *)backBtn{
    if (_backBtn == nil) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[PCCUtils getPlayerSkinImage:@"plv_input_back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (PLVMoreCellView *)createCellView:(NSString *)titleStr btnStr:(NSArray <NSString *>*)btnStr{
    PLVMoreCellView * cellV = [[PLVMoreCellView alloc]initWithFrame:CGRectZero];
    cellV.delegate = self;
    cellV.titleLb.text = titleStr;
    [cellV createBtnsWithStrArr:btnStr];
    [self.bgV addSubview:cellV];
    return cellV;
}

#pragma mark - ----------------- < PLVMoreCellViewDelegate > -----------------
- (void)moreCellView:(PLVMoreCellView *)cellView btnClick:(UIButton *)btn{
    if (cellView == self.audioCellV) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerSkinMoreView:switchAudioMode:)]) {
            [self.delegate playerSkinMoreView:self switchAudioMode:btn.selected];
        }
    } else if (cellView == self.lineCellV){
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerSkinMoreView:line:)]) {
            _curLine = [btn.titleLabel.text substringFromIndex:2].integerValue - 1;
            [self.delegate playerSkinMoreView:self line:self.curLine];
        }
    } else if (cellView == self.codeRateCellV){
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerSkinMoreView:codeRate:)]) {
            [self.delegate playerSkinMoreView:self codeRate:btn.titleLabel.text];
        }
    } else if (cellView == self.speedCellV){
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerSkinMoreView:speed:)]) {
            CGFloat speed = [[btn.titleLabel.text substringToIndex:btn.titleLabel.text.length - 2] floatValue];
            [self.delegate playerSkinMoreView:self speed:speed];
        }
    }
    [self hide];
}


#pragma mark - ----------------- < Event > -----------------
- (void)tapAction{
    [self hide];
}

- (void)backBtnClick:(UIButton *)btn{
    [self hide];
}


#pragma mark - ----------------- < Public Method > -----------------
- (void)setLines:(NSUInteger)lines {
    _lines = lines;
    self.lineCellHeight = _lines <= 1 ? 0.0 : CellVH;
    self.lineCellV.hidden = _lines <= 1;
    [self layoutLineCellV];
}

- (void)setCurLine:(NSInteger)curLine {
    NSUInteger index = 0;
    for (UIButton *btn in self.lineCellV.btnArr) {
        if (index == curLine) {
            _curLine = curLine;
            [self.lineCellV changeCurBtnTo:btn];
            break;
        }
        index++;
    }
}

- (void)setCodeRateItems:(NSMutableArray<NSString *> *)codeRateItems{
    _codeRateItems = codeRateItems;
    if (_codeRateItems == nil || _codeRateItems.count == 0) {
        self.codeRateCellV.hidden = YES;
    } else {
        self.codeRateCellV.hidden = NO;
        [self.codeRateCellV createBtnsWithStrArr:codeRateItems];
    }
    [self refreshCellViewLine];
}

- (void)setCurCodeRate:(NSString *)curCodeRate{
    if (curCodeRate == nil || ![curCodeRate isKindOfClass:[NSString class]] || curCodeRate.length == 0) {
        return;
    }
    
    for (UIButton * btn in self.codeRateCellV.btnArr) {
        if ([btn.titleLabel.text isEqualToString:curCodeRate]) {
            _curCodeRate = curCodeRate;
            [self.codeRateCellV changeCurBtnTo:btn];
            break;
        }
    }
}

- (void)show{
    [UIView animateWithDuration:0.33 animations:^{
        self.alpha = 1;
        self.userInteractionEnabled = YES;
    }];
}

- (void)hide{
    [UIView animateWithDuration:0.15 animations:^{
        self.alpha = 0;
        self.userInteractionEnabled = NO;
    }];
}

- (void)showAudioModeBtn:(BOOL)show{
    self.audioCellV.hidden = !show;
    [self refreshCellViewLine];
}

- (void)modifyModeBtnSelected:(BOOL)selected{
    self.audioCellV.btnArr.firstObject.selected = selected;
    if (selected) {
        [self.audioCellV.btnArr.firstObject setTitle:@"播放画面" forState:UIControlStateNormal];
        // 该模式下隐藏码率切换
        self.codeRateCellV.hidden = YES;
    }else{
        [self.audioCellV.btnArr.firstObject setTitle:@"仅听声音" forState:UIControlStateNormal];
        // 该模式下显示码率切换
        if (_curCodeRate && _curCodeRate.length > 0) {
            self.codeRateCellV.hidden = NO;
        }
    }
    
    [self refreshCellViewLine];
}

- (void)refreshCellViewLine{
    BOOL audioCellVLineHidden = self.audioCellV.hidden == NO && self.codeRateCellV.hidden == YES;
    self.audioCellV.lineV.hidden = audioCellVLineHidden;
}

@end



/// 更多弹窗中每行视图
@implementation PLVMoreCellView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.btnArr = [[NSMutableArray alloc]init];
        [self createUI];
    }
    return self;
}

#pragma mark - ----------------- < Private Method > -----------------
- (void)createUI{
    
    // add
    [self addSubview:self.titleLb];
    [self addSubview:self.lineV];
    
    // layout
    [self.titleLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(12);
        make.centerY.mas_equalTo(self.mas_top).offset(CellVH / 2.0);
        make.height.offset(20);
        make.width.offset(40);
    }];

    [self.lineV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(0);
        make.left.right.offset(0);
        make.height.offset(1);
    }];

}

- (UIButton *)createBtnWithText:(NSString *)text{
    
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:text forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    
    [btn.layer setMasksToBounds:YES];
    [btn.layer setCornerRadius:13.0];
    [btn.layer setBorderWidth:1.0];
    btn.layer.borderColor = [UIColor clearColor].CGColor;
    
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (void)changeBtnSelected:(UIButton *)btn selected:(BOOL)selected{
    if (!btn) { return; }
    
    if (selected) {
        btn.selected = YES;
        btn.layer.borderColor = [UIColor whiteColor].CGColor;
    }else{
        btn.selected = NO;
        btn.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

#pragma mark - ----------------- < Getter > -----------------
- (UILabel *)titleLb{
    if (_titleLb == nil) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _titleLb.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.5];
        _titleLb.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLb;
}

- (UIView *)lineV{
    if (_lineV == nil) {
        _lineV = [[UIView alloc]init];
        _lineV.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.1];
    }
    return _lineV;
}

#pragma mark - ----------------- < Public Method > -----------------
- (void)createBtnsWithStrArr:(NSArray <NSString *>*)btnStrArr{
    if (self.btnArr.count > 0) {
        for (UIButton * oriBtn in self.btnArr) {
            [oriBtn removeFromSuperview];
        }
        self.btnArr = [[NSMutableArray alloc]init];
        self.curBtn = nil;
    }
    
    float padding = 20;
    if ([UIScreen mainScreen].bounds.size.width == 320) { padding = 10; }

    for (int i = 0; i < btnStrArr.count; i++) {
        NSString * btnStr = btnStrArr[i];
        
        UIButton * btn = [self createBtnWithText:btnStr];
        [self addSubview:btn];
        [self.btnArr addObject:btn];
        
        float row = i / 3.0;
        int idxInRow = i % 3;
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            if (row >= 1) {
                make.centerY.mas_equalTo(self.mas_centerY).offset(CellVH / 2.0);
            }else{
                make.centerY.mas_equalTo(self.mas_top).offset(CellVH / 2.0);
            }
            make.height.offset(26);
            make.width.offset(64);
            make.left.mas_equalTo(self.titleLb.mas_right).offset(36 + (padding + 64) * idxInRow);
        }];
    }
}

- (void)setBtnSelectedTextArr:(NSArray<NSString *> *)btnSelectedTextArr{
    if (btnSelectedTextArr.count != self.btnArr.count) { return; }
    for (int i = 0; i < self.btnArr.count; i++) {
        UIButton * btn = self.btnArr[i];
        NSString * btnSelectedStr = btnSelectedTextArr[i];
        [btn setTitle:btnSelectedStr forState:UIControlStateSelected];
    }
    _btnSelectedTextArr = btnSelectedTextArr;
}

- (void)changeCurBtnTo:(UIButton *)btn{
    if (self.curBtn == btn) { return; }
    [self changeBtnSelected:self.curBtn selected:NO];
    self.curBtn = btn;
    [self changeBtnSelected:self.curBtn selected:YES];
}

#pragma mark - ----------------- < Event > -----------------
- (void)btnClick:(UIButton *)btn{
    if (self.selectedMode) {
        btn.selected = !btn.selected;
        if (self.delegate && [self.delegate respondsToSelector:@selector(moreCellView:btnClick:)]) {
            [self.delegate moreCellView:self btnClick:btn];
        }
    }else{
        if (self.curBtn != btn) {
            [self changeCurBtnTo:btn];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(moreCellView:btnClick:)]) {
                [self.delegate moreCellView:self btnClick:self.curBtn];
            }
        }
    }
}

@end
