//
//  VNCameraOverlayView.m
//  VideoNews
//
//  Created by zhangxue on 14-7-17.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCameraOverlayView.h"

@interface VNCameraOverlayView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *progressSliderView;
@property (nonatomic, strong) UIButton *torchBtn;

@property (nonatomic, strong) UIButton *submitBtn;
@end

@implementation VNCameraOverlayView

@synthesize delegate;

#pragma mark - Initialization

- (UIView *)progressSliderView
{
    if (!_progressSliderView) {
        _progressSliderView = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 320, 10)];
        _progressSliderView.backgroundColor = [UIColor orangeColor];
        _progressSliderView.userInteractionEnabled = NO;
    }
    return _progressSliderView;
}

- (UIButton *)torchBtn
{
    if (!_torchBtn) {
        _torchBtn = [[UIButton alloc] initWithFrame:CGRectMake(195, 0, 60, 44)];
        [_torchBtn setTitle:@"Off" forState:UIControlStateNormal];
        [_torchBtn setTitle:@"On" forState:UIControlStateSelected];
        _torchBtn.backgroundColor = [UIColor orangeColor];
        [_torchBtn addTarget:self action:@selector(doChangeTorchStatus:) forControlEvents:UIControlEventTouchUpInside];
        _torchBtn.showsTouchWhenHighlighted = YES;
        _torchBtn.selected = NO;
    }
    return _torchBtn;
}

- (UIButton *)submitBtn
{
    if (!_submitBtn) {
        //album and submit button
        _submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(230, 45, 90, 90)];
        [_submitBtn setTitle:@"Album" forState:UIControlStateNormal];
        [_submitBtn setTitle:@"Submit" forState:UIControlStateSelected];
        _submitBtn.backgroundColor = [UIColor blueColor];
        [_submitBtn addTarget:self action:@selector(doOpenPhotoAlbumOrProcessSubmit:) forControlEvents:UIControlEventTouchUpInside];
        _submitBtn.showsTouchWhenHighlighted = YES;
        _submitBtn.enabled = NO;
        
    }
    return _submitBtn;
}

#pragma mark - ViewLifeCycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self buildOverlayViewAndControls];
        
        //shield original pinch gesture.
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(doPinch)];
        pinchGesture.delegate = self;
        [self addGestureRecognizer:pinchGesture];
    }
    return self;
}

- (void)doPinch
{}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)buildOverlayViewAndControls
{
    //top base view initialization.
    UIView *topBaseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    topBaseView.backgroundColor = [UIColor blackColor];
    
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [closeBtn setTitle:@"Close" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor greenColor];
    [closeBtn addTarget:self action:@selector(doClosePickerCtl) forControlEvents:UIControlEventTouchUpInside];
    closeBtn.showsTouchWhenHighlighted = YES;
    [topBaseView addSubview:closeBtn];
    
    [topBaseView addSubview:self.torchBtn];
    
    UIButton *changeCameraDeviceBtn = [[UIButton alloc] initWithFrame:CGRectMake(260, 0, 60, 44)];
    [changeCameraDeviceBtn setTitle:@"Back" forState:UIControlStateNormal];
    [changeCameraDeviceBtn setTitle:@"Front" forState:UIControlStateSelected];
    changeCameraDeviceBtn.backgroundColor = [UIColor yellowColor];
    [changeCameraDeviceBtn addTarget:self action:@selector(doChangeCameraDevice:) forControlEvents:UIControlEventTouchUpInside];
    changeCameraDeviceBtn.showsTouchWhenHighlighted = YES;
    changeCameraDeviceBtn.selected = NO;
    [topBaseView addSubview:changeCameraDeviceBtn];
    
    [self addSubview:topBaseView];
    
    //bottom base view initialization
    UIView *bottomBaseView = [[UIView alloc] initWithFrame:CGRectMake(0, 385, 320, 183)];
    bottomBaseView.backgroundColor = [UIColor blackColor];
    
    [bottomBaseView addSubview:self.progressSliderView];
    
    UIButton *delBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 45, 90, 90)];
    [delBtn setTitle:@"Back" forState:UIControlStateNormal];
    [delBtn setTitle:@"Del" forState:UIControlStateSelected];
    delBtn.backgroundColor = [UIColor yellowColor];
    [delBtn addTarget:self action:@selector(doDeleteCurrentVideo:) forControlEvents:UIControlEventTouchUpInside];
    delBtn.showsTouchWhenHighlighted = YES;
    delBtn.selected = NO;
    delBtn.enabled = NO;
    [bottomBaseView addSubview:delBtn];
    
    UIButton *takeVideoBtn = [[UIButton alloc] initWithFrame:CGRectMake(105, 45, 110, 90)];
    [takeVideoBtn setTitle:@"Go" forState:UIControlStateNormal];
    [takeVideoBtn setTitle:@"On" forState:UIControlStateSelected];
    takeVideoBtn.backgroundColor = [UIColor redColor];
    [takeVideoBtn addTarget:self action:@selector(doStartVideoRecord:) forControlEvents:UIControlEventTouchDown];
    [takeVideoBtn addTarget:self action:@selector(doEndVideoRecord:) forControlEvents:UIControlEventTouchUpInside];
    takeVideoBtn.showsTouchWhenHighlighted = YES;
    takeVideoBtn.selected = NO;
    [bottomBaseView addSubview:takeVideoBtn];
    
    [bottomBaseView addSubview:self.submitBtn];
    
    [self addSubview:bottomBaseView];
}

- (void)setTorchBtnHidden:(BOOL)hidden
{
    self.torchBtn.hidden = hidden;
}

- (void)setAlbumAndSubmitBtnStatus:(BOOL)enabled
{
//    if (self.currSubmitBtnStatus != st) {
//        switch (st) {
//            case SubmitBtnStatusAlbum:
//                NSLog(@"切换到相册");
//                break;
//            case SubmitBtnStatusDisabled:
//                NSLog(@"时间还不够");
//                break;
//            case SubmitBtnStatusEnabled:
//                NSLog(@"时间够了够了够了");
//                break;
//            default:
//                break;
//        }
//        self.currSubmitBtnStatus = st;
//    }
    self.submitBtn.enabled = enabled;
}

#pragma mark - UserInteractionMethods

/**
 *  @description: close current UIImagePickerController
 *  ask user for sure(if yes, delete current video).
 */
- (void)doClosePickerCtl
{
    if ([self shouldPerforDelegateSelector:@selector(doCloseCurrentController)]) {
        
        [delegate doCloseCurrentController];
    }
}

/**
 *  @description: do change current torch status
 *
 *  @param sender: input button, use it to get current btn selection state.
 */
- (void)doChangeTorchStatus:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if ([self shouldPerforDelegateSelector:@selector(doChangeTorchStatusTo:)]) {
        
        [delegate doChangeTorchStatusTo:sender.selected];
    }
}

/**
 *  @description: do change current camera device(rear & front).
 *
 *  @param sender input button, use it to get current btn selection state.
 */
- (void)doChangeCameraDevice:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if ([self shouldPerforDelegateSelector:@selector(doChangeDeviceTo:)]) {
        
        [delegate doChangeDeviceTo:!sender.selected];
    }
}

/**
 *  @description: delete current video, first set status to del, then delete the video file
 *
 *  @param sender: input button
 */
- (void)doDeleteCurrentVideo:(UIButton *)sender
{
    if (!sender.selected ) {
        //并且当前已经开始录制  =+++++++
        
        sender.selected = YES;
        
        //处理progress slider
    }else {
        
        if ([self shouldPerforDelegateSelector:@selector(doDeleteCurrentVideo)]) {
            
            [delegate doDeleteCurrentVideo];
            sender.selected = NO;
        }
    }
}

/**
 *  @description: startVideoRecord
 *
 *  @param sender: input button
 */
- (void)doStartVideoRecord:(UIButton *)sender
{
    if ([self shouldPerforDelegateSelector:@selector(doStartNewVideoRecord)]) {
        
        [delegate doStartNewVideoRecord];
    }
}

/**
 *  @description: end current video record
 *
 *  @param sender: input button
 */
- (void)doEndVideoRecord:(UIButton *)sender
{
    if ([self shouldPerforDelegateSelector:@selector(doEndCurVideo)]) {
        
        [delegate doEndCurVideo];
    }
}

/**
 *  @description: if the video record has not been started yet, open the photo album, or if the video longer than a certain time period, submit the video.
 *
 *  @param sender: input button
 */
- (void)doOpenPhotoAlbumOrProcessSubmit:(UIButton *)sender
{
    //判断当前进度
//    if () {
        //open photo album (long long ago, it's needed)
//    }else if (){
    //submit the whole video.
    if ([self shouldPerforDelegateSelector:@selector(doSubmitWholeVideo)]) {
        
        [delegate doSubmitWholeVideo];
    }
//}
}

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

@end
