//
//  VNNotificationReplyTableViewCell.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-12.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNotificationReplyTableViewCell.h"

@interface VNNotificationReplyTableViewCell ()

- (IBAction)tapThumbnail:(id)sender;

@end

@implementation VNNotificationReplyTableViewCell

- (void)awakeFromNib
{
    self.contentBgView.layer.cornerRadius = 10;
    self.contentBgView.layer.masksToBounds = YES;
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
        
        self.replyContentLabel.text = self.message.reply_text;
        NSDictionary *attribute = @{NSFontAttributeName:self.replyContentLabel.font};
        CGRect rect = [self.replyContentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.replyContentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        self.replyContentLabelLC.constant = CGRectGetHeight(rect);
        
        NSString *contentText = nil;
        if ([self.message.type isEqualToString:@"comment"]) {
            contentText = [NSString stringWithFormat:@"在\"%@\"中回复了你的评论：\n\"%@\"", self.message.news.title, self.message.text];
        }
        else if ([self.message.type isEqualToString:@"news"]) {
            contentText = [NSString stringWithFormat:@"在你的大作\"%@\"中评论了你", self.message.news.title];
        }
        
        self.contentLabel.text = contentText;
        attribute = @{NSFontAttributeName:self.contentLabel.font};
        rect = [self.contentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.contentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        self.contentBgLC.constant = 20 + CGRectGetHeight(rect);
    }
}

- (IBAction)tapThumbnail:(UITapGestureRecognizer *)sender {
    if (self.tapHandler) {
        self.tapHandler();
    }
}

@end
