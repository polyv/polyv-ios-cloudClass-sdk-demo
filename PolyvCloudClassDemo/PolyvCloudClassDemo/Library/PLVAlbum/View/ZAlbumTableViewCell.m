//
//  ZAlbumTableViewCell.m
//  zPic
//
//  Created by zykhbl on 2017/7/22.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "ZAlbumTableViewCell.h"
#import "ZPicDefine.h"
#import "MyTool.h"

@implementation ZAlbumTableViewCell

@synthesize imgView;
@synthesize nameLabel;
@synthesize countLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = BgClearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void)setup {
    CGRect imgRect = CGRectMake(0.0, 2.0, self.frame.size.height - 4.0, self.frame.size.height - 4.0);
    if (self.imgView == nil) {
        self.imgView = [[UIImageView alloc] initWithFrame:imgRect];
        self.imgView.clipsToBounds = YES;
        self.imgView.contentMode = UIViewContentModeScaleAspectFill;
        self.imgView.backgroundColor = BgClearColor;
        [self addSubview:self.imgView];
    }
    
    CGRect nameRect = CGRectMake(imgRect.origin.x + imgRect.size.height + 5.0, (self.frame.size.height - 30.0) * 0.5 - 8.0, 200.0, 30.0);
    if (self.nameLabel == nil) {
        self.nameLabel = [MyTool createUILabel:nameRect fontOfSize:15.0 textColor:WhiteColor backgroundColor:BgClearColor textAlignment:NSTextAlignmentLeft inView:self];
    }
    
    CGRect countRect = CGRectMake(nameRect.origin.x, nameRect.origin.y + 25.0, 200.0, 20.0);
    if (self.countLabel == nil) {
        self.countLabel = [MyTool createUILabel:countRect fontOfSize:10.0 textColor:LightGrayColor backgroundColor:BgClearColor textAlignment:NSTextAlignmentLeft inView:self];
    }
    
    CGRect lineRect = CGRectMake(0.0, self.frame.size.height - 1.0, self.frame.size.width, 1.0);
    [MyTool createLineView:self rect:lineRect];
}

@end
