//
//  VNUploadVideoProgressView.m
//  VideoNews
//
//  Created by zhangxue on 14-8-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUploadVideoProgressView.h"

#define kProgressBarHeight  20.0f
#define kProgressBarWidth	320.0f

@implementation VNUploadVideoProgressView
@synthesize progress;

- (id)init
{
	return [self initWithFrame: CGRectZero] ;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame: frame] ;
	if (self)
	{
		self.backgroundColor = [UIColor clearColor] ;
		if (frame.size.width == 0.0f)
			frame.size.width = kProgressBarWidth ;
        self.alpha = 0;
	}
	return self ;
}

- (void)dealloc
{
}

- (void)show
{
    [UIView animateWithDuration:0.2f animations:^{
        self.alpha = 1;
    }];
}

- (void)hide
{
    [UIView animateWithDuration:0.2f animations:^{
        self.alpha = 0;
    }];
}

- (void)setProgress:(float)theProgress
{
	// make sure the user does not try to set the progress outside of the bounds
	if (theProgress > 1.0f)
		theProgress = 1.0f ;
	if (theProgress < 0.0f)
		theProgress = 0.0f ;
	
	progress = theProgress ;
    
	[self setNeedsDisplay] ;
}

- (void)setFrame:(CGRect)frame
{
	// we set the height ourselves since it is fixed
	frame.size.height = kProgressBarHeight ;
	[super setFrame: frame] ;
}

- (void)setBounds:(CGRect)bounds
{
	// we set the height ourselves since it is fixed
	bounds.size.height = kProgressBarHeight ;
	[super setBounds: bounds] ;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext() ;
	
	// save the context
	CGContextSaveGState(context) ;
	
	// allow antialiasing
	CGContextSetAllowsAntialiasing(context, TRUE) ;
    
	// make sure the filled rounded rectangle is not smaller than 2 times the radius
	rect.size.width *= progress ;
    
	[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7] setFill] ;
	
	CGContextBeginPath(context) ;
    
    CGContextMoveToPoint(context, CGRectGetMinX(rect), 0) ;
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), 0);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), 0);
	CGContextClosePath(context) ;
	CGContextFillPath(context) ;

	// restore the context
	CGContextRestoreGState(context) ;
}

@end
