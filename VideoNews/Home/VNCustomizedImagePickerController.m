//
//  VNCustomizedImagePickerController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-16.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCustomizedImagePickerController.h"
#import "VNCameraOverlayView.h"
#import <AVFoundation/AVFoundation.h>

@interface VNCustomizedImagePickerController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, VNCameraOverlayViewDelegate>

@property (nonatomic, strong) VNCameraOverlayView *overlayView;

@end

@implementation VNCustomizedImagePickerController

#pragma mark - Initialization

- (VNCameraOverlayView *)overlayView
{
    if (!_overlayView) {
        _overlayView = [[VNCameraOverlayView alloc] initWithFrame:self.view.frame];
        _overlayView.delegate = self;
    }
    return _overlayView;
}

#pragma mark - ViewLifeCycle

- (id)init
{
    self = [super init];
    if (self) {
        self.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.mediaTypes = @[@"public.movie"];
        self.delegate = self;
        self.allowsEditing = YES;
        self.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        self.videoMaximumDuration = 10.0;
        self.showsCameraControls = NO;
        
        self.cameraOverlayView = self.overlayView;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    self.overlayView.delegate = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Methods

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            [device lockForConfiguration:nil];
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)backFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

#pragma mark - VNCameraOverlayViewDelegate

- (void)doCloseCurrentController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doChangeTorchStatusTo:(BOOL)isOn
{
    if (self.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        if (isOn) {
            [[self backFacingCamera] setTorchMode:AVCaptureTorchModeOn];
        }else {
            [[self backFacingCamera] setTorchMode:AVCaptureTorchModeOff];
        }
    }
}

- (void)doChangeDeviceTo:(BOOL)isRear
{
    if (isRear) {
        self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        [self.overlayView setTorchBtnHidden:NO];
    }else {
        self.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        [self.overlayView setTorchBtnHidden:YES];
    }
}

- (void)doDeleteCurrentVideo
{
    //删除当前片段
}

//- (void)doStartNewVideoRecord
//{
//    NSLog(@"start...");
//    //开始新的
//    if ([self startVideoCapture]) {
//
//    }else {
//        NSLog(@"failed to start video capture.");
//    }
//}
//
//- (void)doEndCurVideo
//{
//    NSLog(@"stop...");
//    [self stopVideoCapture];
//}

- (void)doSubmitWholeVideo
{
    //提交video
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"处理XXXXXX逻辑！");
}


@end
