//
//  VNNotificationUserTableViewCell.h
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-12.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNNotificationUserTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@end
