//
//  VNProfileVideoTableViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProfileVideoTableViewCell.h"

@interface VNProfileVideoTableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *videoImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *favouriteLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeightLC;

@end

@implementation VNProfileVideoTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
