//
//  VNCommentTableViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-2.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCommentTableViewCell.h"

@implementation VNCommentTableViewCell

- (void)awakeFromNib {
    [self.replyBtn setHitTestEdgeInsets:UIEdgeInsetsMake(-15.0, -15.0, -15.0, -15.0)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)replyButtonClicked:(UIButton*)sender {
    if([self.delegate respondsToSelector:@selector(replyButtonClicked:)])
   {
       [self.delegate replyButtonClicked:sender];
   }
}

- (IBAction)thumbnailClicked:(UIButton *)sender {
    if([self.delegate respondsToSelector:@selector(thumbnailClicked:)])
    {
        [self.delegate thumbnailClicked:sender];
    }
}

@end
