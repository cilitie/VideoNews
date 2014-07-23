//
//  VNProgressViewForAlbum.m
//  VideoNews
//
//  Created by zhangxue on 14-7-23.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProgressViewForAlbum.h"

@interface VNProgressViewForAlbum()

@property (nonatomic, assign)CGFloat progress;

@end

@implementation VNProgressViewForAlbum

@synthesize delegate;


#define kProgressBarHeight  8.0f
#define kProgressBarWidth	320.0f

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setThumbImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    }
    return self;
}

- (void)setValue:(float)value
{
    [super setValue:value];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext() ;
	
	// save the context
	CGContextSaveGState(context) ;
	
	// allow antialiasing
	CGContextSetAllowsAntialiasing(context, TRUE) ;
    
    // draw the empty rounded rectangle (shown for the "unfilled" portions of the progress
    
	[[UIColor blackColor] setFill] ;
	
	CGContextBeginPath(context) ;
    CGContextMoveToPoint(context, CGRectGetMinX(rect), 0) ;
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), 0);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), 0);
    CGContextClosePath(context) ;
	CGContextFillPath(context) ;
    
    //draw tipping point.
    [[UIColor lightGrayColor] setFill];
    
    CGFloat x = rect.size.width * 5.0 / self.maximumValue;
    
    CGContextBeginPath(context) ;
    CGContextMoveToPoint(context, x - 1, 0) ;
    CGContextAddLineToPoint(context, x + 1, 0);
    CGContextAddLineToPoint(context, x + 1, kProgressBarHeight);
    CGContextAddLineToPoint(context, x - 1, kProgressBarHeight);
    CGContextAddLineToPoint(context, x - 1, 0);
    CGContextClosePath(context) ;
	CGContextFillPath(context) ;
    
	// make sure the filled rounded rectangle is not smaller than 2 times the radius
	rect.size.width *= self.value / self.maximumValue;
    
	[[UIColor colorWithRed:170/255.0 green:64/255.0 blue:144/255.0 alpha:1] setFill] ;
	
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
