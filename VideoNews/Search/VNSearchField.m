//
//  VNSearchField.m
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNSearchField.h"

@interface VNSearchField ()

@property (strong, nonatomic) UIImageView *logoImg;

@end

@implementation VNSearchField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.borderStyle = UITextBorderStyleRoundedRect;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textAlignment = NSTextAlignmentLeft;
        self.font = [UIFont systemFontOfSize:17];
        self.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.leftViewMode = UITextFieldViewModeAlways;
        _logoImg = [[UIImageView alloc] init];
        _logoImg.frame = CGRectMake(8, 0, 22, 22);
        [_logoImg setImage:[UIImage imageNamed:@"45-45search"]];
        self.leftView = _logoImg;
        self.leftView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 35 ,0);
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    return CGRectMake(8, (bounds.size.height-22)/2, 22, 22);
}

@end
