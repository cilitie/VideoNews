//
//  VNVideoFilterListScrollView.m
//  VideoNews
//
//  Created by zhangxue on 14-8-16.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoFilterListScrollView.h"
#define screenH ([[UIScreen mainScreen] bounds].size.height)

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
    float filterY,titleY,titleH,titleFont;
    for (int i = 0; i < numberOfComponents; i++) {
        UIImage *img = [self.dataSource imageForComponentAtIndex:i];
        //NSString *title = [self.dataSource titleForComponentAtIndex:i];
        if (screenH==568) {
            filterY=18;
            titleY=83;
            titleH=10;
            titleFont=9;
        }
        else
        {
            filterY=2;
            titleY=64;
            titleH=8;
            titleFont=7;
        }
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i * 70 + 10, filterY, 60, 60)];
        UILabel *titleLabel=[[UILabel alloc]initWithFrame:CGRectMake(i * 70 + 10, titleY, 60, titleH)];
        titleLabel.text=[self.dataSource titleForComponentAtIndex:i];;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor colorWithRGBValue:0x606366];
        titleLabel.font = [UIFont fontWithName:@"STHeitiSC-Light" size:titleFont];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:titleLabel];
        
        //[btn setTitle:title forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:8];
        btn.backgroundColor = [UIColor colorWithRGBValue:0xCE2426];
        btn.layer.cornerRadius = 30;
        [btn setImage:img forState:UIControlStateNormal];
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