//
//  UIButton+HitTest.h
//  newsmap
//
//  Created by liuyi on 14-7-17.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface UIButton (HitTest)

@property (assign, nonatomic) UIEdgeInsets hitTestEdgeInsets;
- (void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets;

@end
