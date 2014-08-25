//
//  GPLoadingButton.m
//  GPLoadingView
//
//  Created by crazypoo on 14/7/29.
//  Copyright (c) 2014年  广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import "GPLoadingButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation GPLoadingButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setView];
        _activityViewArray = [[NSMutableArray alloc] initWithCapacity:0];
        _rotatorColor = [UIColor darkGrayColor];
        _rotatorSize   = 0;
        _rotatorSpeed  = 0;
        _rotatorPadding = 0;
        _defaultTitle = @"";
        _activityTitle = @"";
    }
    return self;
}

-(void)setView
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.width);
    self.layer.cornerRadius = self.frame.size.width / 2;
    [self addTarget:self action:@selector(onTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(onTouchDown) forControlEvents:UIControlEventTouchDown];
}

-(void)onTouchUpInside
{
    if(self.activityViewArray.count < 1) {
        [self startActivity];
    }
    
    self.userInteractionEnabled = false;
    self.titleLabel.alpha = 1.0;
}

-(void)onTouchDown
{
    self.titleLabel.alpha = 0.25;
}

-(void)startActivity
{
    int i;
    for (i = 1; i < 900; ++i) {
        UIView *activityView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
        activityView.layer.cornerRadius = activityView.frame.size.height / 2;
        activityView.backgroundColor = self.rotatorColor;
        activityView.alpha = 1.0 / (i +0.5);
        [self.activityViewArray addObject:activityView];
    }
    for (UIView *view in self.activityViewArray)
    {
        CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        pathAnimation.calculationMode = kCAAnimationLinear;
        pathAnimation.fillMode = kCAFillModeForwards;
        pathAnimation.removedOnCompletion = false;
        pathAnimation.repeatCount = HUGE;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        pathAnimation.duration = 30;
        CGMutablePathRef curvedPath =CGPathCreateMutable();
        
        long index = [self.activityViewArray indexOfObject:view];
        [self insertSubview:view atIndex:index];
        
        CGFloat startAngle = 270.0 - (index * 4.0);
        CGPathAddArc(curvedPath, nil, self.bounds.origin.x + self.frame.size.width / 2, self.bounds.origin.y + self.frame.size.width / 2, self.frame.size.width / 2 + 0, [self degreesToRadians:startAngle], 360, false);
        pathAnimation.path = curvedPath;
        [view.layer addAnimation:pathAnimation forKey:@"myCircleAnimation"];
        
    }
}

-(void)stopActivity
{
    for (UIView *view in self.activityViewArray) {
        [view.layer removeAllAnimations];
        [view removeFromSuperview];
    }
    
    [self.activityViewArray removeAllObjects];
    self.userInteractionEnabled = true;
}

-(CGFloat)degreesToRadians:(CGFloat)degrees
{
    CGFloat result = ((degrees) / 180.0 * M_PI);
    return result;
}

@end
