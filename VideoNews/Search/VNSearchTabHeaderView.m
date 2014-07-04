//
//  VNSearchTabHeaderView.m
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNSearchTabHeaderView.h"

@interface VNSearchTabHeaderView ()

@property (weak, nonatomic) IBOutlet UIButton *videoBtn;
@property (weak, nonatomic) IBOutlet UIButton *userBtn;

- (IBAction)click:(id)sender;

@end

@implementation VNSearchTabHeaderView

- (IBAction)click:(id)sender {
    [self tabButtonStatus:sender];
}

- (void)tabButtonStatus:(UIButton *)button {
    if (button.tag == 10) {
        [self.videoBtn setTitleColor:[UIColor colorWithRGBValue:0xffffff] forState:UIControlStateNormal];
        [self.videoBtn setBackgroundColor:[UIColor colorWithRGBValue:0x333333]];
        
        [self.userBtn setTitleColor:[UIColor colorWithRGBValue:0x484848] forState:UIControlStateNormal];
        [self.userBtn setBackgroundColor:[UIColor colorWithRGBValue:0x000000]];
        [[NSNotificationCenter defaultCenter] postNotificationName:VNSearchTypeDidChangeNotification object:[NSNumber numberWithInt:SearchTypeVideo]];
    }
    else if (button.tag == 11) {
        [self.userBtn setTitleColor:[UIColor colorWithRGBValue:0xffffff] forState:UIControlStateNormal];
        [self.userBtn setBackgroundColor:[UIColor colorWithRGBValue:0x333333]];
        
        [self.videoBtn setTitleColor:[UIColor colorWithRGBValue:0x484848] forState:UIControlStateNormal];
        [self.videoBtn setBackgroundColor:[UIColor colorWithRGBValue:0x000000]];
        [[NSNotificationCenter defaultCenter] postNotificationName:VNSearchTypeDidChangeNotification object:[NSNumber numberWithInt:SearchTypeUser]];
    }
}

@end
