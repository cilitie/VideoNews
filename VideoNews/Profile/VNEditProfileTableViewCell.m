//
//  VNEditProfileTableViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-25.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNEditProfileTableViewCell.h"

@implementation VNEditProfileTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)reload {
    if (!self.thumbnail) {
        self.titleLabelHeadLC.constant += 58.0;
        self.titleLabelWidthLC.constant += 150.0;
        self.thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(20.0, (CGRectGetHeight(self.bounds)-38.0)/2, 38.0, 38.0)];
        [self addSubview:self.thumbnail];
        [self.contentLabel removeFromSuperview];
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    if (self.thumbnailURLstr) {
        [self.thumbnail setImageWithURL:[NSURL URLWithString:self.thumbnailURLstr] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        [self.thumbnail.layer setCornerRadius:CGRectGetHeight([self.thumbnail bounds]) / 2];
        self.thumbnail.layer.masksToBounds = YES;
    }
}

@end
