//
//  VNVideoFilterListScrollView.m
//  VideoNews
//
//  Created by zhangxue on 14-8-16.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoFilterListScrollView.h"

@implementation VNVideoFilterListScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)loadData
{
    NSInteger numberOfComponents = [self.dataSource numberOfComponentsInFilterList];
    for (int i = 0; i < numberOfComponents; i++) {
        UIImage *img = [self.dataSource imageForComponentAtIndex:i];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i * 100, 10, 80, 80)];
        [btn setImage:img forState:UIControlStateNormal];
        btn.tag = 9000+i;
        [btn addTarget:self action:@selector(didSelectIndex:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    self.contentSize = CGSizeMake(100 * numberOfComponents, 100);
}

- (void)didSelectIndex:(UIButton *)sender
{
    NSInteger index = sender.tag - 9000;
    [self.delegate didSelectComponentAtIndex:index];
}

@end