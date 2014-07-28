//
//  VNSettingTableViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-28.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNSettingTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeadLC;
@property (strong, nonatomic) UISwitch *autoPlaySwitch;
@property (assign, nonatomic) BOOL isAutoPlay;

- (void)reload;

@end
