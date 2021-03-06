//
//  VNNotificationReplyTableViewCell.h
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-12.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ClickEventHandler)();

@interface VNNotificationReplyTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *replyContentLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIView *contentBgView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *replyContentLabelLC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentBgLC;

@property (strong, nonatomic) VNMessage *message;
@property (copy, nonatomic) ClickEventHandler tapHandler;

- (void)reload;

@end
