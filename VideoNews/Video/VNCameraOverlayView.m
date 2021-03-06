//
//  VNCameraOverlayView.m
//  VideoNews
//
//  Created by zhangxue on 14-7-17.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCameraOverlayView.h"
#import "VNProgressView.h"

@interface VNCameraOverlayView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *torchBtn;

@property (nonatomic, strong) UIButton *trashBtn;

@property (nonatomic, strong) UIButton *submitBtn;

@property (nonatomic, strong) VNProgressView *progressView;

@property (nonatomic, strong) UILabel *msgLbl;

@end


@implementation VNCameraOverlayView

@synthesize delegate;

#define screenH ([[UIScreen mainScreen] bounds].size.height)

#pragma mark - Initialization

- (UIButton *)torchBtn
{
    if (!_torchBtn) {
        _torchBtn = [[UIButton alloc] initWithFrame:CGRectMake(195, 0, 60, 60)];
        [_torchBtn setImage:[UIImage imageNamed:@"video_flash_off"] forState:UIControlStateNormal];
        [_torchBtn setImage:[UIImage imageNamed:@"video_flash_on"] forState:UIControlStateSelected];
        _torchBtn.backgroundColor = [UIColor clearColor];
        [_torchBtn addTarget:self action:@selector(doChangeTorchStatus:) forControlEvents:UIControlEventTouchUpInside];
        _torchBtn.showsTouchWhenHighlighted = YES;
        _torchBtn.selected = NO;
    }
    return _torchBtn;
}

- (UIButton *)trashBtn
{
    if (!_trashBtn) {
        
        CGFloat y = 12;
        if (screenH == 568) {
            y = 52;
        }
        _trashBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, y, 76, 76)];
        [_trashBtn setImage:[UIImage imageNamed:@"video_back"] forState:UIControlStateNormal];
        [_trashBtn setImage:[UIImage imageNamed:@"video_trash"] forState:UIControlStateSelected];
        _trashBtn.backgroundColor = [UIColor clearColor];
        [_trashBtn addTarget:self action:@selector(doDeleteCurrentVideo:) forControlEvents:UIControlEventTouchUpInside];
        _trashBtn.showsTouchWhenHighlighted = YES;
        _trashBtn.selected = NO;
        _trashBtn.enabled = NO;
    }
    return _trashBtn;
}

- (UIButton *)submitBtn
{
    if (!_submitBtn) {
        //album and submit button
        CGFloat y = 12;
        if (screenH == 568) {
            y = 52;
        }
        _submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(237, y, 76, 76)];
        [_submitBtn setImage:[UIImage imageNamed:@"112-112_yesNOACTIVE@2x"] forState:UIControlStateNormal];
        [_submitBtn setImage:[UIImage imageNamed:@"112-112_yesACTIVE@2x"] forState:UIControlStateSelected];
        [_submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _submitBtn.backgroundColor = [UIColor clearColor];
        [_submitBtn addTarget:self action:@selector(doOpenPhotoAlbumOrProcessSubmit:) forControlEvents:UIControlEventTouchUpInside];
        _submitBtn.showsTouchWhenHighlighted = YES;
        _submitBtn.selected = NO;
    }
    return _submitBtn;
}

- (VNProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[VNProgressView alloc] initWithFrame:CGRectMake(0, 0, 320, 8)];
    }
    return _progressView;
}

- (UILabel *)msgLbl
{
    if (!_msgLbl) {
        _msgLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 64, 320, 320)];
        _msgLbl.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
        _msgLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:20];
        _msgLbl.textColor = [UIColor darkGrayColor];
        _msgLbl.text = @"生成视频...";
        _msgLbl.textAlignment = NSTextAlignmentCenter;
        _msgLbl.alpha = 0;
    }
    return _msgLbl;
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
        
        //long long ago.. use gesture.
//        UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
//        pressGesture.delegate = self;
//        pressGesture.cancelsTouchesInView = NO;
//        [self addGestureRecognizer:pressGesture];
        
        UIButton *takeVideoBtnOnScreen = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, 320, 320)];
        takeVideoBtnOnScreen.backgroundColor = [UIColor clearColor];
        [takeVideoBtnOnScreen addTarget:self action:@selector(doStartVideoRecord:) forControlEvents:UIControlEventTouchDown];
        [takeVideoBtnOnScreen addTarget:self action:@selector(doEndVideoRecord:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:takeVideoBtnOnScreen];
    }
    return self;
}

- (void)dealloc
{

}

- (void)doPinch
{}

//handle long press gesture... if use gesture to interact with user, use it
//- (void)handlePress:(UILongPressGestureRecognizer *)ges
//{
//    if ([ges locationInView:self].y > 64 && [ges locationInView:self].y < 384) {
//        if (ges.state == UIGestureRecognizerStateBegan) {
//            [self doStartVideoRecord:nil];
//        }else if (ges.state == UIGestureRecognizerStateEnded) {
//            [self doEndVideoRecord:nil];
//        }
//    }
//}

//handle long press gesture... not in use now.
//- (void)handleBtnPress:(UILongPressGestureRecognizer *)ges
//{
//    if (ges.state == UIGestureRecognizerStateBegan) {
//        [self doStartVideoRecord:nil];
//    }else if (ges.state == UIGestureRecognizerStateEnded) {
//        [self doEndVideoRecord:nil];
//    }
//}

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
    
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    [closeBtn setImage:[UIImage imageNamed:@"camera_close"] forState:UIControlStateNormal];
    [closeBtn setImage:[UIImage imageNamed:@"camera_close"] forState:UIControlStateSelected];
    closeBtn.backgroundColor = [UIColor clearColor];
    [closeBtn addTarget:self action:@selector(doClosePickerCtl) forControlEvents:UIControlEventTouchUpInside];
    closeBtn.showsTouchWhenHighlighted = YES;
    [topBaseView addSubview:closeBtn];
    
    [topBaseView addSubview:self.torchBtn];
    
    UIButton *changeCameraDeviceBtn = [[UIButton alloc] initWithFrame:CGRectMake(260, 0, 60, 60)];
    [changeCameraDeviceBtn setImage:[UIImage imageNamed:@"flip_camera"] forState:UIControlStateNormal];
    [changeCameraDeviceBtn setImage:[UIImage imageNamed:@"flip_camera"] forState:UIControlStateSelected];
    changeCameraDeviceBtn.backgroundColor = [UIColor clearColor];
    [changeCameraDeviceBtn addTarget:self action:@selector(doChangeCameraDevice:) forControlEvents:UIControlEventTouchUpInside];
    changeCameraDeviceBtn.showsTouchWhenHighlighted = YES;
    changeCameraDeviceBtn.selected = NO;
    [topBaseView addSubview:changeCameraDeviceBtn];
    
    [self addSubview:topBaseView];
    
    UILabel *descLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 343, 320, 42)];
    descLbl.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    descLbl.textColor = [UIColor whiteColor];
    descLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:12];
    descLbl.textAlignment = NSTextAlignmentCenter;
    descLbl.text = @"记录你的生活，分享你的穿搭，按住屏幕任意位置开始拍摄";
    [self addSubview:descLbl];
    
    //bottom base view initialization
    UIView *bottomBaseView = [[UIView alloc] initWithFrame:CGRectMake(0, 385, 320, 183)];
    bottomBaseView.backgroundColor = [UIColor blackColor];
    
    [bottomBaseView addSubview:self.progressView];
    
    [bottomBaseView addSubview:self.trashBtn];
    
    CGFloat y = 5;
    if (screenH == 568) {
        y = 45;
    }
    UIButton *takeVideoBtn = [[UIButton alloc] initWithFrame:CGRectMake(105, y, 110, 90)];
    [takeVideoBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [takeVideoBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateSelected];
    takeVideoBtn.backgroundColor = [UIColor clearColor];
    [takeVideoBtn addTarget:self action:@selector(doStartVideoRecord:) forControlEvents:UIControlEventTouchDown];
    [takeVideoBtn addTarget:self action:@selector(doEndVideoRecord:) forControlEvents:UIControlEventTouchUpInside];
    takeVideoBtn.showsTouchWhenHighlighted = YES;
    takeVideoBtn.selected = NO;
    
    //not in use now.
//    UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleBtnPress:)];
//    pressGesture.delegate = self;
//    pressGesture.cancelsTouchesInView = NO;
//    [takeVideoBtn addGestureRecognizer:pressGesture];
    
    [bottomBaseView addSubview:takeVideoBtn];
    
    [bottomBaseView addSubview:self.submitBtn];
    
    [self addSubview:bottomBaseView];
    
    [self addSubview:self.msgLbl];
    
}

- (void)setTorchBtnHidden:(BOOL)hidden
{
    if (self.torchBtn.selected) {
        self.torchBtn.selected = NO;
    }
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
    self.submitBtn.selected = enabled;
}

#pragma mark - UserInteractionMethods

- (void)showCombiningMsg
{
    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3f animations:^{
        _msgLbl.alpha = 1;
    }];
}

- (void)hideCombiningMsg
{
    self.userInteractionEnabled = YES;
    _msgLbl.alpha = 0;
}

- (void)setTrashBtnEnabled:(BOOL)enable
{
    [self.trashBtn setEnabled:enable];
}

//commented by zhangxue 20140726
//- (void)setProgressViewBlinking:(BOOL)blink
//{
//    [_progressView setTippingPointShining:blink];
//}

- (void)setProgressTimeArr:(NSArray *)timeArr
{
    [_progressView setTimePointArr:timeArr];
}

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
        
        _progressView.status = ProgressViewStatusEditing;
        
        self.submitBtn.enabled = NO;
        
    }else {
        
        //处理progressBar 和 本地video文件
        if ([self shouldPerforDelegateSelector:@selector(doDeleteCurrentVideo)]) {
            
            [delegate doDeleteCurrentVideo];
            sender.selected = NO;
            _progressView.status = ProgressViewStatusNormal;

        }
        
        self.submitBtn.enabled = YES;
    }
}

/**
 *  @description: startVideoRecord
 *
 *  @param sender: input button
 */
- (void)doStartVideoRecord:(UIButton *)sender
{
    _progressView.status = ProgressViewStatusNormal;
    _trashBtn.selected = NO;
    self.submitBtn.enabled = YES;
    
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
    if (sender.selected) {
        if ([self shouldPerforDelegateSelector:@selector(doSubmitWholeVideo)]) {
            
            [delegate doSubmitWholeVideo];
        }
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

- (void)updateProgressViewToPercentage:(CGFloat)per
{
    _progressView.progress = per;
}

@end
