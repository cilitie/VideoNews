//
//  BMNavigationController.m
//  BananaNews
//
//  Created by 龚涛 on 12/30/13.
//  Copyright (c) 2013 龚涛. All rights reserved.
//

#import "BMNavigationController.h"
#import <QuartzCore/QuartzCore.h>

#define KEY_WINDOW  [[UIApplication sharedApplication] keyWindow]

@interface BMNavigationController ()
{
    CGPoint startTouch;
    
    UIImageView *lastScreenShotView;
    UIView *blackMask;
}

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) NSMutableArray *screenShotsList;

@property (nonatomic, strong) UIPanGestureRecognizer *recognizer;

@property (nonatomic, assign) BOOL isMoving;

@end

#define IS_IOS7     ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define kSidePanelRightWidth    220.0

@implementation BMNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.screenShotsList = [[NSMutableArray alloc] initWithCapacity:2];
    self.canDragBack = YES;
    
    self.recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(paningGestureReceive:)];
    [self.view addGestureRecognizer:self.recognizer];
    self.recognizer.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (UIInterfaceOrientationPortrait==toInterfaceOrientation);
}

// override the push method
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.screenShotsList addObject:[self capture]];
    
    self.recognizer.enabled = YES;
    
    [super pushViewController:viewController animated:animated];
}

// override the pop method
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    if (2 == self.viewControllers.count) {
        self.recognizer.enabled = NO;
    }
    
    if (animated) {
        _isMoving = YES;
        
        if (!self.backgroundView)
        {
            CGRect frame = self.view.frame;
            
            self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
            [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
            
            blackMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
            blackMask.backgroundColor = [UIColor blackColor];
            blackMask.alpha = 0.6;
            [self.backgroundView addSubview:blackMask];
        }
        
        [self moveViewWithX:0.0];
        
        self.backgroundView.hidden = NO;
        
        if (lastScreenShotView) [lastScreenShotView removeFromSuperview];
        
        UIImage *lastScreenShot = [self.screenShotsList lastObject];
        lastScreenShotView = [[UIImageView alloc] initWithImage:lastScreenShot];
        [self.backgroundView insertSubview:lastScreenShotView belowSubview:blackMask];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self moveViewWithX:320.0];
        } completion:^(BOOL finished) {
            
            [self.screenShotsList removeLastObject];
            [super popViewControllerAnimated:NO];
            CGRect frame = self.view.frame;
            frame.origin.x = 0;
            self.view.frame = frame;
            
            [lastScreenShotView removeFromSuperview];
            lastScreenShotView  = nil;
            [blackMask removeFromSuperview];
            blackMask = nil;
            [self.backgroundView removeFromSuperview];
            self.backgroundView = nil;
            
            _isMoving = NO;
        }];
        
        return self.topViewController;
    }
    else {
        [self.screenShotsList removeLastObject];
        return [super popViewControllerAnimated:NO];
    }
}

#pragma mark - Utility Methods -

// get the current view screen shot
- (UIImage *)capture
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

// set lastScreenShotView 's position and alpha when paning
- (void)moveViewWithX:(float)x
{
    x = x>320?320:x;
    x = x<0?0:x;
    
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    
    blackMask.alpha = 0.4 - (x/800);
    
    frame = self.backgroundView.frame;
    if (IS_IOS7) {
        frame.origin.x = (320.0-kSidePanelRightWidth) * (x/320.0-1.0);
    }
    else {
        frame.origin.x = x - frame.size.width;
    }
    self.backgroundView.frame = frame;
}

#pragma mark - Gesture Recognizer -

- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer
{
    // If the viewControllers has only one vc or disable the interaction, then return.
    if (self.viewControllers.count <= 1 || !self.canDragBack) return;
    
    // we get the touch position by the window's coordinate
    CGPoint touchPoint = [recoginzer locationInView:KEY_WINDOW];
    
    // begin paning, show the backgroundView(last screenshot),if not exist, create it.
    if (recoginzer.state == UIGestureRecognizerStateBegan) {
        
        _isMoving = YES;
        startTouch = touchPoint;
        
        if (!self.backgroundView)
        {
            CGRect frame = self.view.frame;
            
            self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
            [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
            
            blackMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
            blackMask.backgroundColor = [UIColor blackColor];
            blackMask.alpha = 0.6;
            [self.backgroundView addSubview:blackMask];
        }
        
        [self moveViewWithX:0.0];
        
        self.backgroundView.hidden = NO;
        
        if (lastScreenShotView) [lastScreenShotView removeFromSuperview];
        
        UIImage *lastScreenShot = [self.screenShotsList lastObject];
        lastScreenShotView = [[UIImageView alloc] initWithImage:lastScreenShot];
        [self.backgroundView insertSubview:lastScreenShotView belowSubview:blackMask];
        
        //End paning, always check that if it should move right or move left automatically
    }else if (recoginzer.state == UIGestureRecognizerStateEnded){
        
        if (touchPoint.x - startTouch.x > 50)
        {
            [UIView animateWithDuration:0.3 animations:^{
                [self moveViewWithX:320];
            } completion:^(BOOL finished) {
                
                [self popViewControllerAnimated:NO];
                CGRect frame = self.view.frame;
                frame.origin.x = 0;
                self.view.frame = frame;
                
                _isMoving = NO;
            }];
        }
        else
        {
            [UIView animateWithDuration:0.3 animations:^{
                [self moveViewWithX:0];
            } completion:^(BOOL finished) {
                _isMoving = NO;
                self.backgroundView.hidden = YES;
            }];
            
        }
        return;
        
        // cancal panning, alway move to left side automatically
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        
        [UIView animateWithDuration:0.3 animations:^{
            [self moveViewWithX:0];
        } completion:^(BOOL finished) {
            _isMoving = NO;
            self.backgroundView.hidden = YES;
        }];
        
        return;
    }
    
    // it keeps move with touch
    if (_isMoving) {
        [self moveViewWithX:touchPoint.x - startTouch.x];
    }
}


@end
