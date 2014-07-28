//
//  VNSettingTableViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-28.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNSettingTableViewCell.h"

@implementation VNSettingTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

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
    if (!self.autoPlaySwitch) {
        self.autoPlaySwitch = [[UISwitch alloc] init];
        self.accessoryView = self.autoPlaySwitch;
    }
    self.autoPlaySwitch.on = self.isAutoPlay;
}

@end
