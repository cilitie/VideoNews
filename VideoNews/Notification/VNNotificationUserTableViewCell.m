//
//  VNNotificationUserTableViewCell.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-12.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNotificationUserTableViewCell.h"

@interface VNNotificationUserTableViewCell ()

- (IBAction)tapThumbnail:(id)sender;

@end

@implementation VNNotificationUserTableViewCell

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
    if (self.message) {
        [self.thumbnail setImageWithURL:[NSURL URLWithString:self.message.sender.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        [self.thumbnail.layer setCornerRadius:CGRectGetHeight([self.thumbnail bounds]) / 2];
        self.thumbnail.layer.masksToBounds = YES;
        self.nameLabel.text = self.message.sender.name;
        self.timeLabel.text= [VNUtility strFromTimeStampSince1970:[self.message.time doubleValue]];
    }
}

- (IBAction)tapThumbnail:(UITapGestureRecognizer *)sender {
    if (self.tapHandler) {
        self.tapHandler();
    }
}
@end
