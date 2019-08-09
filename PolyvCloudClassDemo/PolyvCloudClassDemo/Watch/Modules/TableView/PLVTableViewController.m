//
//  PLVTableViewController.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/31.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVTableViewController.h"
#import <Masonry/Masonry.h>

@interface PLVTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIButton *showLatestMessageBtn;

@end

@implementation PLVTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollsToBottom = YES;
    self.dataArray = [NSMutableArray array];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 0.0;
    self.tableView.estimatedSectionHeaderHeight = 0.0;
    self.tableView.estimatedSectionFooterHeight = 0.0;
    [self.view addSubview:self.tableView];
}

#pragma mark - Public

- (void)reloadData {
    [self.tableView reloadData];
}

- (void)scrollsToBottom:(BOOL)animated {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    if (offsetY < 0.0) {
        offsetY = 0.0;
    }
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:animated];
}

- (void)scrollToRowAtIndex:(NSUInteger)index atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    if (index < self.dataArray.count) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:scrollPosition animated:animated];
    }
}

- (void)addLatestMessageButton {
    self.showLatestMessageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.showLatestMessageBtn.layer.cornerRadius = 15.0;
    self.showLatestMessageBtn.layer.masksToBounds = YES;
    [self.showLatestMessageBtn setTitle:@"有更多新消息，点击查看" forState:UIControlStateNormal];
    [self.showLatestMessageBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    if (@available(iOS 8.2, *)) {
        [self.showLatestMessageBtn.titleLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightMedium]];
    } else {
        [self.showLatestMessageBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
    }
    self.showLatestMessageBtn.backgroundColor = [UIColor colorWithRed:90/255.0 green:200/255.0 blue:250/255.0 alpha:1];
    self.showLatestMessageBtn.hidden = YES;
    [self.showLatestMessageBtn addTarget:self action:@selector(loadMoreMessageBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.showLatestMessageBtn];
    self.showLatestMessageBtn.hidden = YES;
    
    [self.showLatestMessageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(185, 30));
        make.bottom.equalTo(self.tableView.mas_bottom).offset(-10);
    }];
}

- (void)loadMoreMessageBtnAction {
    [self scrollsToBottom:YES];
}

- (void)showLatestMessageButton {
    if (self.showLatestMessageBtn && self.dataArray.count) {
        self.showLatestMessageBtn.hidden = NO;
    }
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat viewHeight = CGRectGetHeight(scrollView.bounds);
    CGFloat bottomOffset = scrollView.contentSize.height - scrollView.contentOffset.y;
    if (bottomOffset < viewHeight + 1.0) {
        self.scrollsToBottom = YES;
        self.showLatestMessageBtn.hidden = YES;
    } else {
        self.scrollsToBottom = NO;
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s",__FUNCTION__);
    if (indexPath.row < self.dataArray.count) {
        PLVCellModel *model = (PLVCellModel *)self.dataArray[indexPath.row];
        PLVBaseCell *cell = [model makeCellWithTableView:tableView];
        [cell setModel:model];
        [cell setDelegate:self];
        return cell;
    } else {
        return [[UITableViewCell alloc] init];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s",__FUNCTION__);
    [(PLVBaseCell *)cell layoutCell];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s",__FUNCTION__);
    [(PLVBaseCell *)cell setModel:nil];
    [(PLVBaseCell *)cell setDelegate:nil];
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.dataArray.count) {
        PLVCellModel *model = (PLVCellModel *)self.dataArray[indexPath.row];
        return model.cellHeight;
    } else {
        return 0.0;
    }
}

@end
