//
//  PLVLiveInfoViewController.m
//  PolyvLiveSDKDemo
//
//  Created by zykhbl(zhangyukun@polyv.net) on 2018/7/18.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVLiveInfoViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "PCCUtils.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define BUTTON_TITLE_COLOR [UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1.0]

static CGFloat kHeaderViewHeight = 100.0;

@interface PLVLiveInfoViewController () <WKNavigationDelegate>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarImgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *liveTimeLabel;
@property (nonatomic, strong) UILabel *liveStatusLabel;
@property (nonatomic, strong) UIButton *publisherBtn;
@property (nonatomic, strong) UIButton *likesBtn;
@property (nonatomic, strong) UIButton *watchesBtn;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, assign) NSInteger watchNumber;

@end

@implementation PLVLiveInfoViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.headerView];
    
    [self.headerView addSubview:self.avatarImgView];
    [self.headerView addSubview:self.titleLabel];
    [self.headerView addSubview:self.liveTimeLabel];
    [self.headerView addSubview:self.liveStatusLabel];
    [self.headerView addSubview:self.publisherBtn];
    [self.headerView addSubview:self.likesBtn];
    [self.headerView addSubview:self.watchesBtn];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 99, SCREEN_WIDTH, 1)];
    lineView.backgroundColor = [UIColor colorWithRed:0xf3/255.0 green:0xf3/255.0 blue:0xf4/255.0 alpha:1.0];
    [self.headerView addSubview:lineView];
    
    [self.view addSubview:self.webView];
    
    [self refreshLiveInfo];
}

- (void)viewDidLayoutSubviews {
    float webViewH = self.view.frame.size.height - kHeaderViewHeight;
    _webView.frame = CGRectMake(0, kHeaderViewHeight, SCREEN_WIDTH, webViewH);
    
    _avatarImgView.frame = CGRectMake(10, 20, 60, 60);
    
    CGFloat titleLabelOriginX = _avatarImgView.frame.origin.x + _avatarImgView.frame.size.width + 10;
    _titleLabel.frame = CGRectMake(titleLabelOriginX, 16, 285, 24);
    _liveTimeLabel.frame = CGRectMake(titleLabelOriginX, 40, 80, 20);
    
    CGFloat liveStatusLabelOriginY = (kHeaderViewHeight - 18)/2.0;
    _liveStatusLabel.frame = CGRectMake(SCREEN_WIDTH - 10 - 50, liveStatusLabelOriginY, 50, 18);
    
    CGRect liveTimeLabelRect = _liveTimeLabel.frame;
    liveTimeLabelRect.size.width = SCREEN_WIDTH - titleLabelOriginX - 10 - _liveStatusLabel.frame.size.width - 10;
    _liveTimeLabel.frame = liveTimeLabelRect;
    
    _publisherBtn.frame = CGRectMake(CGRectGetMaxX(_avatarImgView.frame) + 10, 61, 80, 20);
    _likesBtn.frame = CGRectMake(CGRectGetMaxX(_publisherBtn.frame) + 18, 61, 88, 20);
    _watchesBtn.frame = CGRectMake(CGRectGetMaxX(_likesBtn.frame) + 18, 61, 88, 20);
}

#pragma mark - Getter & Setter

- (UIView *)headerView {
    if (_headerView == nil) {
        _headerView = [[UIView alloc] init];
        _headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, kHeaderViewHeight);
        _headerView.backgroundColor = [UIColor whiteColor];
    }
    return _headerView;
}

- (UIImageView *)avatarImgView {
    if (_avatarImgView == nil) {
        _avatarImgView = [[UIImageView alloc] init];
        _avatarImgView.frame = CGRectMake(10, 20, 60, 60);
    }
    return _avatarImgView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textColor = [UIColor darkTextColor];
        _titleLabel.text = @"直播标题";
    }
    return _titleLabel;
}

- (UILabel *)liveTimeLabel {
    if (_liveTimeLabel == nil) {
        _liveTimeLabel = [[UILabel alloc] init];
        _liveTimeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _liveTimeLabel.font = [UIFont systemFontOfSize:12];
        _liveTimeLabel.textColor = [UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1.0];
        _liveTimeLabel.text = @"直播时间：无";
    }
    return _liveTimeLabel;
}

- (UILabel *)liveStatusLabel {
    if (_liveStatusLabel == nil) {
        _liveStatusLabel = [[UILabel alloc] init];
        _liveStatusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _liveStatusLabel.textAlignment = NSTextAlignmentCenter;
        _liveStatusLabel.font = [UIFont systemFontOfSize:12];
        _liveStatusLabel.textColor = [UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1.0];
        _liveStatusLabel.text = @"无直播";
    }
    return _liveStatusLabel;
}

- (UIButton *)publisherBtn {
    if (_publisherBtn == nil) {
        _publisherBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _publisherBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _publisherBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        _publisherBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        _publisherBtn.titleLabel.text = @"主持人";
        _publisherBtn.userInteractionEnabled = NO;
        [_publisherBtn setImage:[PCCUtils getLiveInfoImage:@"plv_btn_publisher"] forState:UIControlStateNormal];
        [_publisherBtn setTitleColor:BUTTON_TITLE_COLOR forState:UIControlStateNormal];
    }
    return _publisherBtn;
}

- (UIButton *)likesBtn {
    if (_likesBtn == nil) {
        _likesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _likesBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _likesBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        _likesBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        _likesBtn.titleLabel.text = @"0";
        _likesBtn.userInteractionEnabled = NO;
        [_likesBtn setImage:[PCCUtils getLiveInfoImage:@"plv_btn_praise"] forState:UIControlStateNormal];
        [_likesBtn setTitleColor:BUTTON_TITLE_COLOR forState:UIControlStateNormal];
        [_likesBtn addTarget:self action:@selector(likes:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _likesBtn;
}

- (UIButton *)watchesBtn {
    if (_watchesBtn == nil) {
        _watchesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _watchesBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _watchesBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        _watchesBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        _watchesBtn.titleLabel.textColor = [UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1.0];
        _watchesBtn.titleLabel.text = @"0";
        _watchesBtn.userInteractionEnabled = NO;
        [_watchesBtn setImage:[PCCUtils getLiveInfoImage:@"plv_img_watch"] forState:UIControlStateNormal];
        [_watchesBtn setTitleColor:BUTTON_TITLE_COLOR forState:UIControlStateNormal];
        [_watchesBtn addTarget:self action:@selector(watches:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _watchesBtn;
}

- (WKWebView *)webView {
    if (_webView == nil) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, kHeaderViewHeight, SCREEN_WIDTH, 100)];
        _webView.opaque = NO;
        _webView.navigationDelegate = self;
        _webView.hidden = YES;
        _webView.autoresizingMask = UIViewAutoresizingNone;
    }
    return _webView;
}

- (void)setWatchNumber:(NSInteger)watchNumber {
    if (watchNumber < _watchNumber) {
        return;
    }
    _watchNumber = watchNumber;
}

#pragma mark - Action

- (void)likes:(id)sender {
    [self.likesBtn setTitle:[NSString stringWithFormat:@"%ld", (long)self.channelMenuInfo.likes.integerValue] forState:UIControlStateNormal];
}

- (void)watches:(id)sender {
    [self.watchesBtn setTitle:[NSString stringWithFormat:@"%zd", self.watchNumber] forState:UIControlStateNormal];
}

#pragma mark - Public

- (void)increaseWatchNumber {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.watchNumber++;
        [self.watchesBtn setTitle:[NSString stringWithFormat:@"%zd", self.watchNumber] forState:UIControlStateNormal];
    });
}

- (void)updateWatchNumber:(NSInteger)watchNumber {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.watchNumber = watchNumber;
        [self.watchesBtn setTitle:[NSString stringWithFormat:@"%zd", self.watchNumber] forState:UIControlStateNormal];
    });
}

- (void)refreshLiveInfo{
    if (!self.menu || !self.channelMenuInfo) { return; }
    
    if ([@"desc" isEqualToString:self.menu.menuType]) {
        self.titleLabel.text = self.channelMenuInfo.name.length > 13 ? [NSString stringWithFormat:@"%@...", [self.channelMenuInfo.name substringToIndex:13]] : self.channelMenuInfo.name;
        if (self.channelMenuInfo && ![self.channelMenuInfo.coverImage isKindOfClass:[NSNull class]]) {
            [self.avatarImgView sd_setImageWithURL:[NSURL URLWithString:self.channelMenuInfo.coverImage] placeholderImage:[PCCUtils getLiveInfoImage:@"plv_img_defaultUser"]];
        }
        
        [self.publisherBtn setTitle:[NSString stringWithFormat:@" %@", self.channelMenuInfo.publisher] forState:UIControlStateNormal];
        
        if (self.channelMenuInfo.likes.integerValue >= 100000) {
            [self.likesBtn setTitle:[NSString stringWithFormat:@" %0.1fW", self.channelMenuInfo.likes.integerValue / 10000.0] forState:UIControlStateNormal];
        } else {
            [self.likesBtn setTitle:[NSString stringWithFormat:@" %ld", (long)self.channelMenuInfo.likes.integerValue] forState:UIControlStateNormal];
        }
        
        self.watchNumber = self.channelMenuInfo.pageView.integerValue;
        if (self.watchNumber > 100000) {
            [self.watchesBtn setTitle:[NSString stringWithFormat:@" %0.1fW", self.watchNumber / 10000.0] forState:UIControlStateNormal];
        } else {
            [self.watchesBtn setTitle:[NSString stringWithFormat:@" %zd", self.watchNumber] forState:UIControlStateNormal];
        }
        
        self.liveTimeLabel.text = self.channelMenuInfo.startTime != nil ? [NSString stringWithFormat:@"直播时间:%@", self.channelMenuInfo.startTime] : @"直播时间:无";
        self.liveTimeLabel.hidden = self.vod;
        if (!self.liveTimeLabel.hidden) { self.liveTimeLabel.hidden = (self.channelMenuInfo.startTime == nil); }
        
        self.liveStatusLabel.layer.borderWidth = 1.0;
        self.liveStatusLabel.layer.cornerRadius = 3.0;
        self.liveStatusLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        if ([@"live" isEqualToString:self.channelMenuInfo.watchStatus]) {
            self.liveStatusLabel.text = @"直播中";
            self.liveStatusLabel.textColor = [UIColor redColor];
            self.liveStatusLabel.layer.borderColor = [UIColor redColor].CGColor;
        } else if ([@"waiting" isEqualToString:self.channelMenuInfo.watchStatus]) {
            self.liveStatusLabel.text = @"等待中";
            self.liveStatusLabel.textColor = [UIColor colorWithRed:161.0 / 255.0 green:204.0 / 255.0 blue:112.0 / 255.0 alpha:1.0];
            self.liveStatusLabel.layer.borderColor = [UIColor colorWithRed:161.0 / 255.0 green:204.0 / 255.0 blue:112.0 / 255.0 alpha:1.0].CGColor;
        } else {
            self.liveStatusLabel.text = @"暂无直播"; // [@"playback" isEqualToString:self.channelMenuInfo.watchStatus] ? @"回放中" : @"已结束";
            self.liveStatusLabel.textColor = [UIColor colorWithWhite:102.0 / 255.0 alpha:1.0];
            self.liveStatusLabel.layer.borderColor = [UIColor colorWithWhite:102.0 / 255.0 alpha:1.0].CGColor;
            self.liveStatusLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:11];
        }
        self.liveStatusLabel.hidden = self.vod;
        
        if (![self.menu.content isKindOfClass:[NSNull class]] && self.menu.content.length) {
            [self.webView loadHTMLString:[self html] baseURL:[NSURL URLWithString:@""]];
        }
    } else {
        self.headerView.hidden = YES;
        
        if ([@"text" isEqualToString:self.menu.menuType]) {
            if (![self.menu.content isKindOfClass:[NSNull class]] && self.menu.content.length) {
                [self.webView loadHTMLString:[self html] baseURL:[NSURL URLWithString:@""]];
            }
        } else if ([@"iframe" isEqualToString:self.menu.menuType]) {
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.menu.content]]];
        }
    }
}

#pragma mark - Private

- (NSString *)html {
    /// 图片自适应设备宽，边距，禁用双指缩放
    int offset = 10;
    int fontSize = 14;
    NSString *content = [self.menu.content stringByReplacingOccurrencesOfString:@"<img src=\"//" withString:@"<img src=\"https://"];
    return [NSString stringWithFormat:@"<html>\n<body style=\"position:absolute;left:%dpx;right:%dpx;top:%dpx;bottom:%dpx;font-size:%d\"><script type='text/javascript'>window.onload = function(){\nvar $img = document.getElementsByTagName('img');\nfor(var p in  $img){\n $img[p].style.width = '100%%';\n$img[p].style.height ='auto'\n}\n}</script>%@</body></html>", offset, offset, offset, offset, fontSize, content];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation; {
    self.webView.hidden = NO;
    
    /// 禁止双指缩放
    NSString *noScaleJS = @"var script = document.createElement('meta');"
    "script.name = 'viewport';"
    "script.content=\"user-scalable=no,width=device-width,initial-scale=1.0,maximum-scale=1.0\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    [self.webView evaluateJavaScript:noScaleJS completionHandler:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame == nil) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
