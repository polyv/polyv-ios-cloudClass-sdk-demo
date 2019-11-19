//
//  PLVBaseCell.m
//  PolyvCloudClassDemo
//
//  Created by ftao on 2019/7/30.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVBaseCell.h"
#import "PLVCellModel.h"

@implementation PLVBaseCell

- (void)setModel:(PLVCellModel *)model {
    model.cell = nil;
    _model = model;
    model.cell = self;
}

+ (NSString *)identifier {
    return NSStringFromClass([self class]);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)layoutCell {
    //[self doesNotRecognizeSelector:_cmd];
}

+ (CGFloat)cellHeightWithModel:(PLVCellModel *)model {
    return 0.0;
}

@end
