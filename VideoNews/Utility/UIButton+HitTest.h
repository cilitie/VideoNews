//
//  UIButton+HitTest.h
//  newsmap
//
//  Created by liuyi on 14-6-4.
//  Copyright (c) 2014年 Chinaso Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (HitTest)

@property (assign, nonatomic) UIEdgeInsets hitTestEdgeInsets;
- (void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets;

@end
