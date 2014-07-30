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
        [self.autoPlaySwitch addTarget:self action:@selector(switchPlayOption:) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = self.autoPlaySwitch;
    }
    BOOL isAutoPlay = [[[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay] boolValue];
    self.autoPlaySwitch.on = isAutoPlay;
}

- (void)switchPlayOption:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:sender.on] forKey:VNIsWiFiAutoPlay];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
