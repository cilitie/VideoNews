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
        self.showsHorizontalScrollIndicator = NO;
    }
    return self;
}

- (void)loadData
{
    NSInteger numberOfComponents = [self.dataSource numberOfComponentsInFilterList];
    for (int i = 0; i < numberOfComponents; i++) {
//        UIImage *img = [self.dataSource imageForComponentAtIndex:i];
        NSString *title = [self.dataSource titleForComponentAtIndex:i];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i * 70 + 10, 10, 60, 60)];
        [btn setTitle:title forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:8];
        btn.backgroundColor = [UIColor colorWithRGBValue:0xCE2426];
        btn.layer.cornerRadius = 30;
//        [btn setImage:img forState:UIControlStateNormal];
        btn.tag = 9000+i;
        [btn addTarget:self action:@selector(didSelectIndex:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    self.contentSize = CGSizeMake(70 * numberOfComponents, 70);
}

- (void)didSelectIndex:(UIButton *)sender
{
    NSInteger index = sender.tag - 9000;
    [self.delegate didSelectComponentAtIndex:index];
}

@end