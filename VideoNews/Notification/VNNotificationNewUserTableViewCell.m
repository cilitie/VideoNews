//
//  VNNotificationNewUserTableViewCell.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-8-17.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNotificationNewUserTableViewCell.h"
#import "UIButton+AFNetworking.h"
@interface VNNotificationNewUserTableViewCell()

- (IBAction)tapThumbnail:(id)sender;

@end

@implementation VNNotificationNewUserTableViewCell

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
        [self.thumbnailButton setImageForState:UIControlStateNormal withURL:[NSURL URLWithString:self.message.sender.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        //NSLog(@"%@",_message.sender.avatar);
        //[self.thumbnail setImageWithURL:[NSURL URLWithString:self.message.sender.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        [self.thumbnailButton.layer setCornerRadius:CGRectGetHeight([self.thumbnailButton bounds]) / 2];
        self.thumbnailButton.layer.masksToBounds = YES;
        NSString *text=[NSString stringWithFormat:@"%@于%@关注了你",self.message.sender.name,[VNUtility timeFormatToDisplay:[self.message.time doubleValue]]];
        self.contentLabel.text = text;
        //self.timeLabel.text= [VNUtility strFromTimeStampSince1970:[self.message.time doubleValue]];
        //self.timeLabel.text=[VNUtility timeFormatToDisplay:[self.message.time doubleValue]];
        
    }
}

- (IBAction)tapThumbnail:(UITapGestureRecognizer *)sender {
    if (self.tapHandler) {
        self.tapHandler();
    }
}

@end
