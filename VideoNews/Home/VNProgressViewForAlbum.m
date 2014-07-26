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
        
        UIImage *sliderLeftTrackImage = [[UIImage imageNamed:@"blank"] stretchableImageWithLeftCapWidth:0 topCapHeight: 0];
        UIImage *sliderRightTrackImage = [[UIImage imageNamed:@"blank"] stretchableImageWithLeftCapWidth:0 topCapHeight: 0];
        [self setMinimumTrackImage: sliderLeftTrackImage forState: UIControlStateNormal];
        [self setMaximumTrackImage: sliderRightTrackImage forState: UIControlStateNormal];
        
    }
    return self;
}

//- (void)setValue:(float)value
//{
//    [super setValue:value];
//    NSLog(@"set value.....:%f",value);
//    [self setNeedsDisplay];
//}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext() ;
	
	// save the context
	CGContextSaveGState(context) ;
	
	// allow antialiasing
	CGContextSetAllowsAntialiasing(context, TRUE) ;
    
    // draw the empty rounded rectangle (shown for the "unfilled" portions of the progress
    
	[[UIColor colorWithRGBValue:0x222127] setFill] ;
	
	CGContextBeginPath(context) ;
    CGContextMoveToPoint(context, CGRectGetMinX(rect), 0) ;
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), 0);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), 0);
    CGContextClosePath(context) ;
	CGContextFillPath(context) ;
    
	// make sure the filled rounded rectangle is not smaller than 2 times the radius
    CGFloat x = rect.size.width * self.value / self.maximumValue;
    
	[[UIColor redColor] setFill] ;
	
	CGContextBeginPath(context) ;
    
    CGContextMoveToPoint(context, 0, 0) ;
    CGContextAddLineToPoint(context, x, 0);
    CGContextAddLineToPoint(context, x, kProgressBarHeight);
    CGContextAddLineToPoint(context, 0, kProgressBarHeight);
    CGContextAddLineToPoint(context, 0, 0);
	CGContextClosePath(context) ;
	CGContextFillPath(context) ;
    
    //draw tipping point.
    [[UIColor whiteColor] setFill];
    x = rect.size.width * 5.0 / self.maximumValue;
    
    CGContextBeginPath(context) ;
    CGContextMoveToPoint(context, x - 1, 0) ;
    CGContextAddLineToPoint(context, x + 1, 0);
    CGContextAddLineToPoint(context, x + 1, kProgressBarHeight);
    CGContextAddLineToPoint(context, x - 1, kProgressBarHeight);
    CGContextAddLineToPoint(context, x - 1, 0);
    CGContextClosePath(context) ;
	CGContextFillPath(context) ;

	// restore the context
	CGContextRestoreGState(context) ;
}

@end
