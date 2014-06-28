//
//  VNCategoryCollectionViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-6-28.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCategoryCollectionViewCell.h"

@implementation VNCategoryCollectionViewCell

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.layer.cornerRadius = 10.0;
        self.layer.masksToBounds = YES;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
