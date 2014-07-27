//
//  VNCustomizedActionSheet.m
//  VideoNews
//
//  Created by zhangxue on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCustomizedActionSheet.h"
#import "UIImageView+LBBlurredImage.h"
#import "VNAppDelegate.h"

@interface VNCustomizedActionSheet ()

@property (nonatomic, strong) UIView *actionSheetView;

@end

@implementation VNCustomizedActionSheet

@synthesize delegate, superView;

#define IPHONE_HEIGHT              [UIScreen mainScreen].bounds.size.height
#define ACTION_SHEET_HEIGHT        182

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        __weak VNCustomizedActionSheet *weakSelf = self;
        

            dispatch_async(dispatch_get_main_queue(), ^{
                
                @autoreleasepool {
                    UIImage *backgroundImage = [weakSelf imageFromView:weakSelf.superView atFrame:CGRectMake(0, 0, 320, IPHONE_HEIGHT)];
                    
                    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, IPHONE_HEIGHT)];
                    [imageView setImageToBlur:backgroundImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:^(NSError *error) {
                    }];
                    backgroundImage = nil;
                    
                    [weakSelf insertSubview:imageView atIndex:0];
                    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, IPHONE_HEIGHT)];
                    v.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
                
                    [weakSelf insertSubview:v atIndex:1];
                }
            });

        _actionSheetView = [[UIView alloc] initWithFrame:CGRectMake(0, IPHONE_HEIGHT, 320, ACTION_SHEET_HEIGHT)];
        _actionSheetView.backgroundColor = [UIColor clearColor];
        
        UIView *actionBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, ACTION_SHEET_HEIGHT - 49)];
        actionBgView.backgroundColor = [UIColor blackColor];
        
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 37)];
        titleLbl.text = @"选择视频";
        titleLbl.textColor = [UIColor whiteColor];
        titleLbl.backgroundColor = [UIColor clearColor];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
        [actionBgView addSubview:titleLbl];
        
        
        UIButton *draftBtn = [[UIButton alloc] initWithFrame:CGRectMake(8, 36, 74, 74)];
        [draftBtn setTitle:@"Draft" forState:UIControlStateNormal];
        draftBtn.backgroundColor = [UIColor greenColor];
        [draftBtn addTarget:self action:@selector(doOpenDraftList) forControlEvents:UIControlEventTouchUpInside];
        draftBtn.showsTouchWhenHighlighted = YES;
        [actionBgView addSubview:draftBtn];
        
        
        UIButton *cameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(123, 36, 74, 74)];
        [cameraBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
        [cameraBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateSelected];
        cameraBtn.backgroundColor = [UIColor clearColor];
        [cameraBtn addTarget:self action:@selector(doOpenCamera) forControlEvents:UIControlEventTouchUpInside];
        cameraBtn.showsTouchWhenHighlighted = YES;
        [actionBgView addSubview:cameraBtn];
        
        UIButton *albumBtn = [[UIButton alloc] initWithFrame:CGRectMake(238, 36, 74, 74)];
        [albumBtn setImage:[UIImage imageNamed:@"album"] forState:UIControlStateNormal];
        [albumBtn setImage:[UIImage imageNamed:@"album"] forState:UIControlStateSelected];
        albumBtn.backgroundColor = [UIColor clearColor];
        [albumBtn addTarget:self action:@selector(doOpenAlbum) forControlEvents:UIControlEventTouchUpInside];
        albumBtn.showsTouchWhenHighlighted = YES;
        [actionBgView addSubview:albumBtn];
        
        [_actionSheetView addSubview:actionBgView];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, ACTION_SHEET_HEIGHT - 49, 320, 49)];
        imgView.image = [UIImage imageNamed:@"bottomBar"];
        [_actionSheetView addSubview:imgView];

        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(125, ACTION_SHEET_HEIGHT - 49, 70, 49)];
        [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        cancelBtn.backgroundColor = [UIColor darkGrayColor];
        [cancelBtn addTarget:self action:@selector(dismissActionSheet) forControlEvents:UIControlEventTouchUpInside];
        cancelBtn.showsTouchWhenHighlighted = YES;
        [_actionSheetView addSubview:cancelBtn];
        
        [self addSubview:_actionSheetView];
    }
    return self;
}

- (UIImage *)imageFromView:(UIView *) theView   atFrame:(CGRect)r
{
    UIGraphicsBeginImageContext(theView.frame.size);
    [theView drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    theView.layer.contents = nil;
    return  theImage;
}

- (void)show
{
    VNAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:self];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.actionSheetView.frame = CGRectMake(0, IPHONE_HEIGHT - ACTION_SHEET_HEIGHT, 320, ACTION_SHEET_HEIGHT);
    } ];
}

/**
 *  @description:draft button did pressed.
 */
- (void) doOpenDraftList
{
    
    [UIView animateWithDuration:0.2f animations:^{
        _actionSheetView.frame = CGRectMake(0, IPHONE_HEIGHT, 320, 160);
    } completion:^(BOOL finish){
        if ([self shouldPerforDelegateSelector:@selector(draftBtnDidPressed)]) {
            [delegate draftBtnDidPressed];
        }
        [self removeFromSuperview];

    }];
}

/**
 *  @description : start video recording.
 */
- (void)doOpenCamera
{
    [UIView animateWithDuration:0.2f animations:^{
        _actionSheetView.frame = CGRectMake(0, IPHONE_HEIGHT, 320, 160);
    } completion:^(BOOL finish){
        if ([self shouldPerforDelegateSelector:@selector(cameraBtnDidPressed)]) {
            [delegate cameraBtnDidPressed];
        }
        [self removeFromSuperview];
        
    }];
}

/**
 *  @description: open photo album and select a video file.
 */
- (void)doOpenAlbum
{
    [UIView animateWithDuration:0.2f animations:^{
        _actionSheetView.frame = CGRectMake(0, IPHONE_HEIGHT, 320, 160);
    } completion:^(BOOL finish){
        if ([self shouldPerforDelegateSelector:@selector(albumBtnDidPressed)]) {
            [delegate albumBtnDidPressed];
        }
        [self removeFromSuperview];
        
    }];
}

- (void)dismissActionSheet
{
    [UIView animateWithDuration:0.2f animations:^{
        _actionSheetView.frame = CGRectMake(0, IPHONE_HEIGHT, 320, 160);
    } completion:^(BOOL finish){
        if ([self shouldPerforDelegateSelector:@selector(cancelBtnClicked)]) {
            [delegate cancelBtnClicked];
        }
        [self removeFromSuperview];
        
    }];
}
//
//- (void)dismissActionSheetWithCompletionHandler:(CompletionHandlerBlock)block{
//    
//    [UIView animateWithDuration:0.2f animations:^{
//        _actionSheetView.frame = CGRectMake(0, IPHONE_HEIGHT, 320, 160);
//    } completion:block];
//}

/**
 *  @description: do see if delegate is still alive && the delegate method does exist.
 *
 *  @param sel : input selector
 *
 *  @return : weather the selector should be performed.
 */
- (BOOL)shouldPerforDelegateSelector:(SEL)sel
{
    if (delegate && [delegate respondsToSelector:sel]) {
        return YES;
    }else {
        NSLog(@"delegate function miss【%@】",NSStringFromSelector(sel));
        return NO;
    }
}

- (void)dealloc
{
}

@end
