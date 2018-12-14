/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "PLVFacialView.h"
#import "PLVEmoji.h"
#import "PLVEmojiModel.h"

@interface PLVFacialView ()

@property (nonatomic, strong) NSBundle *emotionBundle;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation PLVFacialView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        PLVEmoji *emoji = [PLVEmoji sharedEmoji];
        
        // 参数配置
        _faces = emoji.allEmojiModels;
        // 参数配置
        PLVEmojiModelManager *emojiManager = [PLVEmojiModelManager sharedManager];
        emojiManager.emotionDictionary = emoji.emotionDictionary;
    }
    return self;
}

//给faces设置位置
-(void)loadFacialView:(int)page size:(CGSize)size {
	int maxRow = 5;
    int maxCol = 6;
    CGFloat itemWidth = self.scrollView.bounds.size.width / maxCol;
    CGFloat itemHeight = self.scrollView.bounds.size.height / maxRow;
    
    // 初始化bundle包
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Emotion" ofType:@"bundle"];
    self.emotionBundle = [NSBundle bundleWithPath:path];

    // 添加表情
    for (int index = 0, row = 0; index < [_faces count]; row++) {
        int page = row / maxRow;
        CGFloat addtionWidth = page * CGRectGetWidth(self.scrollView.bounds);
        int decreaseRow = page * maxRow;
        for (int col = 0; col < maxCol; col++, index ++) {
            if (index < [_faces count]) {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [self.scrollView addSubview:button];
                [button setBackgroundColor:[UIColor clearColor]];
                [button setFrame:CGRectMake(col * itemWidth + addtionWidth, (row-decreaseRow) * itemHeight, itemWidth, itemHeight)];
                button.showsTouchWhenHighlighted = YES;
                button.tag = index;
                [button addTarget:self action:@selector(selected:) forControlEvents:UIControlEventTouchUpInside];
                
                PLVEmojiModel *emojiModel = [_faces objectAtIndex:index];
                [button setImage:[self imageForEmotionPNGName:emojiModel.imagePNG] forState:UIControlStateNormal];
            } else {
                break;
            }
        }
    }
    
    UIButton *delBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    delBtn.layer.cornerRadius = 5.0;
    delBtn.backgroundColor = [UIColor colorWithRed:234.0 / 255.0 green:234.0/ 255.0 blue:234.0/ 255.0 alpha:1.0];
    delBtn.frame = CGRectMake(self.scrollView.frame.origin.x + self.scrollView.frame.size.width, 5.0, itemWidth - 5.0, itemHeight - 5.0);
    [delBtn setImage:[UIImage imageNamed:@"plv_backspace"] forState:UIControlStateNormal];
    [delBtn addTarget:self action:@selector(delBtnTouchBegin:)forControlEvents:UIControlEventTouchDown];
    [delBtn addTarget:self action:@selector(delBtnTouchEnd:)forControlEvents:UIControlEventTouchUpInside];
    [delBtn addTarget:self action:@selector(delBtnTouchEnd:)forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:delBtn];
    
    self.sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendBtn.layer.cornerRadius = 5.0;
    self.sendBtn.enabled = NO;
    self.sendBtn.backgroundColor = [UIColor colorWithRed:234.0 / 255.0 green:234.0/ 255.0 blue:234.0/ 255.0 alpha:1.0];
    self.sendBtn.frame = CGRectMake(delBtn.frame.origin.x, delBtn.frame.origin.y + delBtn.frame.size.height + 10.0, itemWidth - 5.0, itemHeight * 4.0 - 15.0);
    [self.sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendBtn setTitleColor:[UIColor colorWithRed:123.0 / 255.0 green:128.0/ 255.0 blue:135.0/ 255.0 alpha:1.0] forState:UIControlStateDisabled];
    [self.sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [self.sendBtn addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.sendBtn];
}

- (void)delBtnTouchBegin:(id)sender {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)delBtnTouchEnd:(id)sender {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)handleTimer:(id)sender {
    if (_delegate) {
        [_delegate deleteEmoji];
    }
}

- (IBAction)sendAction:(id)sender {
    if (self.delegate) {
        [self.delegate send];
    }
}

- (void)sendBtnEnable:(BOOL)enable {
    self.sendBtn.enabled = enable;
    if (enable) {
        self.sendBtn.backgroundColor = [UIColor colorWithRed:43.0/ 255.0 green:152.0/ 255.0 blue:240.0/ 255.0 alpha:1.0];
    } else {
        self.sendBtn.backgroundColor = [UIColor colorWithRed:234.0 / 255.0 green:234.0/ 255.0 blue:234.0/ 255.0 alpha:1.0];
    }
}

#pragma mark - 重写
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        [self addSubview:_scrollView];
        _scrollView.frame = CGRectMake(0.0, 0.0, self.bounds.size.width * 6.0 / 7.0, self.bounds.size.height);
        _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * 4.0, CGRectGetHeight(self.scrollView.bounds));
        _scrollView.pagingEnabled = YES;
    }
    return _scrollView;
}

-(void)selected:(UIButton *)bt {
    if (_delegate) {
        [_delegate selectedFacialView:[_faces objectAtIndex:bt.tag]];
    }
}

#pragma mark - 自定义方法
- (UIImage *)imageForEmotionPNGName:(NSString *)pngName {
    return [UIImage imageNamed:pngName inBundle:self.emotionBundle compatibleWithTraitCollection:nil];
}

@end
