//
//  VNMineProfileHeaderView.m
//  VideoNews
//
//  Created by liuyi on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNMineProfileHeaderView.h"

@interface VNMineProfileHeaderView ()

- (IBAction)edit:(id)sender;
- (IBAction)tap:(UITapGestureRecognizer *)sender;

@end


@implementation VNMineProfileHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)edit:(id)sender {
    if (self.editHandler) {
        self.editHandler();
    }
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self];
    NSUInteger index = 0;
    if (CGRectContainsPoint(CGRectMake(0, 94, 80, 50), point)) {
        index = 0;
    }
    if (CGRectContainsPoint(CGRectMake(80, 94, 80, 50), point)) {
        index = 1;
    }
    if (CGRectContainsPoint(CGRectMake(80*2, 94, 80, 50), point)) {
        index = 2;
    }
    if (CGRectContainsPoint(CGRectMake(80*3, 94, 80, 50), point)) {
        index = 3;
    }
    if (self.tabHandler) {
        self.tabHandler(index);
    }
}

@end
