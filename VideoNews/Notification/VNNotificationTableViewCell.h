//
//  VNNotificationTableViewCell.h
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-11.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNNotificationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@end
