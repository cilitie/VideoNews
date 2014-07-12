//
//  VNDetailHeaderView.m
//  VideoNews
//
//  Created by liuyi on 14-6-30.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNDetailHeaderView.h"

@interface VNDetailHeaderView ()

- (IBAction)click:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *moreBtn;

@end

@implementation VNDetailHeaderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)click:(id)sender {
    UIButton *button = sender;
    if (button == self.moreBtn) {
        if (self.moreHandler) {
            self.moreHandler();
        }
    }
}

@end
