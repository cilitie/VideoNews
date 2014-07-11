//
//  VNUserResultCollectionViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-11.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUserResultCollectionViewCell.h"

@implementation VNUserResultCollectionViewCell

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.layer.cornerRadius = 10.0;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)awakeFromNib {
    self.thumbnailImgView.layer.cornerRadius = 10.0;
    self.thumbnailImgView.layer.masksToBounds = YES;
    
    self.fansBgView.layer.cornerRadius = 10.0;
    self.fansBgView.layer.masksToBounds = YES;
    
    self.followBtn.layer.cornerRadius = 10.0;
    self.followBtn.layer.masksToBounds = YES;
    self.followBtn.layer.borderWidth = 1.0;
    self.followBtn.layer.borderColor = [[UIColor colorWithRGBValue:0xcacaca] CGColor];
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
