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
#import "VNTabBarViewController.h"

@interface VNCustomizedActionSheet () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *draftBtn;
@property (nonatomic, strong) UIButton *cameraBtn;
@property (nonatomic, strong) UIButton *albumBtn;

@end

@implementation VNCustomizedActionSheet

@synthesize delegate, superView;

#define IPHONE_HEIGHT              [UIScreen mainScreen].bounds.size.height
#define ACTION_SHEET_HEIGHT        216

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
                }
            });

        UIView *actionSheetView = [[UIView alloc] initWithFrame:CGRectMake(0, IPHONE_HEIGHT - ACTION_SHEET_HEIGHT, 320, ACTION_SHEET_HEIGHT)];
        actionSheetView.backgroundColor = [UIColor clearColor];
        
        UIView *actionBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, ACTION_SHEET_HEIGHT - 49)];
        actionBgView.backgroundColor = [UIColor blackColor];
        
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 37)];
        titleLbl.text = @"选择视频";
        titleLbl.textColor = [UIColor colorWithRed:177/255.0 green:177/255.0 blue:177/255.0 alpha:1];
        titleLbl.backgroundColor = [UIColor clearColor];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
        [actionBgView addSubview:titleLbl];
        
        
        _draftBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 61, 50, 50)];
        [_draftBtn setImage:[UIImage imageNamed:@"video_draft"] forState:UIControlStateNormal];
        [_draftBtn setImage:[UIImage imageNamed:@"video_draft"] forState:UIControlStateSelected];
        _draftBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _draftBtn.backgroundColor = [UIColor clearColor];
        [_draftBtn addTarget:self action:@selector(doOpenDraftList) forControlEvents:UIControlEventTouchUpInside];
        _draftBtn.showsTouchWhenHighlighted = YES;
        _draftBtn.alpha = 0;
        [actionBgView addSubview:_draftBtn];
        
        
        _cameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(135, 61, 50, 50)];
        [_cameraBtn setImage:[UIImage imageNamed:@"video_camera"] forState:UIControlStateNormal];
        [_cameraBtn setImage:[UIImage imageNamed:@"video_camera"] forState:UIControlStateSelected];
        _cameraBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _cameraBtn.backgroundColor = [UIColor clearColor];
        [_cameraBtn addTarget:self action:@selector(doOpenCamera) forControlEvents:UIControlEventTouchUpInside];
        _cameraBtn.showsTouchWhenHighlighted = YES;
        _cameraBtn.alpha = 0;
        [actionBgView addSubview:_cameraBtn];
        
        _albumBtn = [[UIButton alloc] initWithFrame:CGRectMake(250, 61, 50, 50)];
        [_albumBtn setImage:[UIImage imageNamed:@"video_album"] forState:UIControlStateNormal];
        [_albumBtn setImage:[UIImage imageNamed:@"video_album"] forState:UIControlStateSelected];
        _albumBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _albumBtn.backgroundColor = [UIColor clearColor];
        [_albumBtn addTarget:self action:@selector(doOpenAlbum) forControlEvents:UIControlEventTouchUpInside];
        _albumBtn.showsTouchWhenHighlighted = YES;
        _albumBtn.alpha = 0;
        [actionBgView addSubview:_albumBtn];
        
        UILabel *draftLbl = [[UILabel alloc] initWithFrame:CGRectMake(1.5, 130, 87, 20)];
        draftLbl.backgroundColor = [UIColor clearColor];
        draftLbl.textColor = [UIColor colorWithRed:177/255.0 green:177/255.0 blue:177/255.0 alpha:1];
        draftLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:12];
        draftLbl.textAlignment = NSTextAlignmentCenter;
        draftLbl.text = @"草稿";
        [actionBgView addSubview:draftLbl];
        
        UILabel *cameraLbl = [[UILabel alloc] initWithFrame:CGRectMake(116.5, 130, 87, 20)];
        cameraLbl.backgroundColor = [UIColor clearColor];
        cameraLbl.textColor = [UIColor colorWithRed:177/255.0 green:177/255.0 blue:177/255.0 alpha:1];
        cameraLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:12];
        cameraLbl.textAlignment = NSTextAlignmentCenter;
        cameraLbl.text = @"相机";
        [actionBgView addSubview:cameraLbl];
        
        UILabel *albumLbl = [[UILabel alloc] initWithFrame:CGRectMake(231.5, 130, 87, 20)];
        albumLbl.backgroundColor = [UIColor clearColor];
        albumLbl.textColor = [UIColor colorWithRed:177/255.0 green:177/255.0 blue:177/255.0 alpha:1];
        albumLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:12];
        albumLbl.textAlignment = NSTextAlignmentCenter;
        albumLbl.text = @"相册";
        [actionBgView addSubview:albumLbl];
        
        [actionSheetView addSubview:actionBgView];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, ACTION_SHEET_HEIGHT - 49, 320, 49)];
        imgView.image = [UIImage imageNamed:@"bottomBar"];
        [actionSheetView addSubview:imgView];

        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(125, ACTION_SHEET_HEIGHT - 49, 70, 49)];
        [cancelBtn setImage:[UIImage imageNamed:@"camera_close"] forState:UIControlStateNormal];
        [cancelBtn setImage:[UIImage imageNamed:@"camera_close"] forState:UIControlStateSelected];
        cancelBtn.backgroundColor = [UIColor colorWithRed:48/255.0 green:48/255.0 blue:48/255.0 alpha:1];
        [cancelBtn addTarget:self action:@selector(dismissActionSheet) forControlEvents:UIControlEventTouchUpInside];
        cancelBtn.showsTouchWhenHighlighted = YES;
        [actionSheetView addSubview:cancelBtn];
        
        [self addSubview:actionSheetView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tapGesture.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tapGesture];
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
    
    VNAppDelegate *appDelegate = (VNAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:self];

    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, IPHONE_HEIGHT - ACTION_SHEET_HEIGHT)];
    v.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    v.alpha = 0;
    [self insertSubview:v atIndex:1];
    
    __weak VNCustomizedActionSheet *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:.2f animations:^{
            weakSelf.draftBtn.frame = CGRectMake(1.5, 42.5, 87, 87);
            weakSelf.draftBtn.alpha = 1;
            weakSelf.cameraBtn.frame = CGRectMake(116.5, 42.5, 87, 87);
            weakSelf.cameraBtn.alpha = 1;
            weakSelf.albumBtn.frame = CGRectMake(231.5, 42.5, 87, 87);
            weakSelf.albumBtn.alpha = 1;
            v.alpha = 1;
            
        } ];
    });
}

/**
 *  @description:draft button did pressed.
 */
- (void) doOpenDraftList
{
    
    if ([self shouldPerforDelegateSelector:@selector(draftBtnDidPressed)]) {
        [delegate draftBtnDidPressed];
    }
    [self removeFromSuperview];
}

/**
 *  @description : start video recording.
 */
- (void)doOpenCamera
{
    if ([self shouldPerforDelegateSelector:@selector(cameraBtnDidPressed)]) {
        [delegate cameraBtnDidPressed];
    }
    [self removeFromSuperview];
}

/**
 *  @description: open photo album and select a video file.
 */
- (void)doOpenAlbum
{
    if ([self shouldPerforDelegateSelector:@selector(albumBtnDidPressed)]) {
        [delegate albumBtnDidPressed];
    }
    [self removeFromSuperview];
}

- (void)dismissActionSheet
{
    if ([self shouldPerforDelegateSelector:@selector(cancelBtnClicked)]) {
        [delegate cancelBtnClicked];
    }
    [self removeFromSuperview];
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

#pragma mark - UIGestureRecognizerDelegate

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    CGFloat locationX, locationY;
    
    locationX = [gesture locationInView:self].x;
    locationY = [gesture locationInView:self].y;
    
    if (locationY < IPHONE_HEIGHT - ACTION_SHEET_HEIGHT) {
        [self removeFromSuperview];
        return;
    }
    
    if (locationY > IPHONE_HEIGHT - 49) {
        
        VNAppDelegate *appDelegate = (VNAppDelegate *)[[UIApplication sharedApplication] delegate];
        VNTabBarViewController *tabbarCtl = (VNTabBarViewController *)appDelegate.window.rootViewController;

        if (locationX <= 64) {
            //tabbar index 0
            tabbarCtl.selectedIndex = 0;
        }else if (locationX > 64 && locationX <= 128) {
            //tabbar index 1
            tabbarCtl.selectedIndex = 1;
        }else if (locationX > 128 && locationX <= 192) {
            //tabbar index 2
        }else if (locationX > 192 && locationX <= 256) {
            //tabbar index 3
            tabbarCtl.selectedIndex = 3;
        }else if (locationX > 256 && locationX <= 320) {
            //tabbar index 4
            tabbarCtl.selectedIndex = 4;
        }
        
        [self removeFromSuperview];
    }
}

@end
