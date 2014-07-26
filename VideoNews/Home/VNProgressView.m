//
//  VNProgressView.m
//  VideoNews
//
//  Created by zhangxue on 14-7-22.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProgressView.h"

#define kProgressBarHeight  8.0f
#define kProgressBarWidth	320.0f

@interface VNProgressView()

@property (nonatomic, strong) UIImageView *blingRect;
@property (nonatomic, strong) NSTimer *shiningTimer;

@end

@implementation VNProgressView

@synthesize progress ;
@synthesize timePointArr;
@synthesize status;

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
        
//        _blingRect = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kProgressBarHeight, kProgressBarHeight)];
//        _blingRect.backgroundColor = [UIColor orangeColor];
//        [self addSubview:_blingRect];
        
	}
	return self ;
}

- (void)dealloc
{
}

// commented by zhangxue 20140726
//- (void)setTippingPointShining:(BOOL)shine
//{
//    if (shine) {
//        _shiningTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(shineTippingPoint) userInfo:nil repeats:YES];
//        [_shiningTimer fire];
//    }else {
//        
//        [_shiningTimer invalidate];
//        
//        [UIView animateWithDuration:0.2f animations:^{
//            _blingRect.alpha = 1;
//        } completion:^(BOOL finish){
//            _blingRect.hidden = NO;
//        }];
//    }
//}


- (void)shineTippingPoint
{
    if (_blingRect.hidden) {
        _blingRect.hidden = NO;
        [UIView animateWithDuration:0.2f animations:^{
            _blingRect.alpha = 1;
        }];
    }else {
        [UIView animateWithDuration:0.2f animations:^{
            _blingRect.alpha = 0;
        } completion:^(BOOL finish){
            _blingRect.hidden = YES;
        }];
    }
}

- (void)setProgress:(float)theProgress
{
	// make sure the user does not try to set the progress outside of the bounds
	if (theProgress > 1.0f)
		theProgress = 1.0f ;
	if (theProgress < 0.0f)
		theProgress = 0.0f ;
	
	progress = theProgress ;
    
    CGRect rect = _blingRect.frame;
    
    rect.origin.x = progress * self.frame.size.width;
    if (rect.origin.x > kProgressBarWidth - kProgressBarHeight) {
        rect.origin.x = kProgressBarWidth - kProgressBarHeight;
    }
    
    _blingRect.frame = rect;
    
	[self setNeedsDisplay] ;
}

- (void)setStatus:(ProgressViewStatus)sta
{
    status = sta;
    
    [self setNeedsDisplay];
}

- (void)setTimePointArr:(NSArray *)timePArr
{
    timePointArr = timePArr;
    
    CGRect rect = _blingRect.frame;
    
    NSNumber *number = (NSNumber *)[timePointArr lastObject];
    
    rect.origin.x = number.floatValue / 30 * self.frame.size.width + 2;
    

    if (rect.origin.x > kProgressBarWidth - kProgressBarHeight) {
        rect.origin.x = kProgressBarWidth - kProgressBarHeight;
    }
    
    _blingRect.frame = rect;
    [self setNeedsDisplay];
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
    
    
    //draw tipping point.
    [[UIColor whiteColor] setFill];
    
    CGContextBeginPath(context) ;
    CGContextMoveToPoint(context, 53, 0) ;
    CGContextAddLineToPoint(context, 55, 0);
    CGContextAddLineToPoint(context, 55, kProgressBarHeight);
    CGContextAddLineToPoint(context, 53, kProgressBarHeight);
    CGContextAddLineToPoint(context, 53, 0);
    CGContextClosePath(context) ;
	CGContextFillPath(context) ;
    
    
	// draw the inside moving filled rounded rectangle
	
	// make sure the filled rounded rectangle is not smaller than 2 times the radius
	rect.size.width *= progress ;
    
	[[UIColor redColor] setFill] ;
	
	CGContextBeginPath(context) ;
    
    CGContextMoveToPoint(context, CGRectGetMinX(rect), 0) ;
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), 0);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), kProgressBarHeight);
    CGContextAddLineToPoint(context, CGRectGetMinX(rect), 0);
	CGContextClosePath(context) ;
	CGContextFillPath(context) ;
    
    
    if (timePointArr) {
        
        [[UIColor colorWithRGBValue:0x222127] setFill] ;
        
        for (int i = 0; i < timePointArr.count; i++) {
            
            NSNumber *time = [timePointArr objectAtIndex:i];
            
            CGFloat x = time.floatValue / 30 * kProgressBarWidth;
            
            CGContextBeginPath(context) ;
            
            CGContextMoveToPoint(context, x , 0) ;
            CGContextAddLineToPoint(context, x+2, 0);
            CGContextAddLineToPoint(context, x+2, kProgressBarHeight);
            CGContextAddLineToPoint(context, x, kProgressBarHeight);
            CGContextAddLineToPoint(context, x, 0);
            CGContextClosePath(context) ;
            CGContextFillPath(context) ;
        }
    }
    
    if (self.status == ProgressViewStatusEditing) {
        
        [[UIColor yellowColor] setFill] ;
        
        CGFloat x_start,x_end;
        
        if (timePointArr.count == 1) {
            
            NSNumber *time = [timePointArr objectAtIndex:0];
            
            x_end = time.floatValue / 30 * kProgressBarWidth;
            
            
        }else {
            NSNumber *time = [timePointArr objectAtIndex:timePointArr.count - 2];
            
            x_start = time.floatValue / 30 * kProgressBarWidth;
            
            time = [timePointArr objectAtIndex:timePointArr.count - 1];
            
            x_end = time.floatValue / 30 * kProgressBarWidth;
            
        }
        
        CGContextBeginPath(context) ;
        
        CGContextMoveToPoint(context, x_start, 0) ;
        CGContextAddLineToPoint(context, x_end, 0);
        CGContextAddLineToPoint(context, x_end, kProgressBarHeight);
        CGContextAddLineToPoint(context, x_start, kProgressBarHeight);
        CGContextAddLineToPoint(context, x_start, 0);
        CGContextClosePath(context) ;
        CGContextFillPath(context) ;
    }
    
	// restore the context
	CGContextRestoreGState(context) ;
}


@end
