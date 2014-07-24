//
//  VNVideoCaptureViewController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-20.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoCaptureViewController.h"
#import "VNCameraOverlayView.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

#import "VNHTTPRequestManager.h"
#import <AFNetworking.h>

#import "VNVideoCoverSettingController.h"

@interface VNVideoCaptureViewController () <AVCaptureFileOutputRecordingDelegate,VNCameraOverlayViewDelegate,UIAlertViewDelegate>


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;

@property (nonatomic, strong) VNCameraOverlayView *overlayView;

@property (nonatomic, strong) NSMutableArray *videoPathArr;
@property (nonatomic, strong) NSMutableArray *videoTimePointArr;

@property (nonatomic, assign) CGFloat videoTotalDuration;
@property (nonatomic, assign) NSInteger videoPieceCount;

@property (nonatomic, strong) NSTimer *durationTimer;

@end

@implementation VNVideoCaptureViewController

#define MIN_VIDEO_DURATION 5.0
#define MAX_VIDEO_DURATION 30.0
#define TEMP_VIDEO_NAME_PREFIX @"VN_Video_"

static NSString *videoFilePath;

#pragma mark - Initialization

- (VNCameraOverlayView *)overlayView
{
    if (!_overlayView) {
        _overlayView = [[VNCameraOverlayView alloc] initWithFrame:self.view.frame];
        _overlayView.delegate = self;
        [_overlayView setProgressViewBlinking:YES];
    }
    return _overlayView;
}

#pragma mark - ViewLifeCycle

- (id)init
{
    self = [super init];
    if (self) {
        
        videoFilePath = [VNUtility getNSCachePath:@"VideoFiles"];

        self.captureSession = [[AVCaptureSession alloc] init];
        [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];

        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [videoDevice lockForConfiguration:nil];
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
        
        self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
        
        [self.captureSession addInput:self.videoInput];
        [self.captureSession addOutput:self.movieOutput];
        
        AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        UIView *aView = self.view;
        previewLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [aView.layer addSublayer:previewLayer];
        
        [self.view addSubview:self.overlayView];
        
        self.videoPieceCount = 0;
        self.videoTotalDuration = 0;
        
        _videoTimePointArr = [NSMutableArray arrayWithCapacity:1];
        _videoPathArr = [NSMutableArray arrayWithCapacity:1];
        
        BOOL _isDir;

        if(![[NSFileManager defaultManager] fileExistsAtPath:videoFilePath isDirectory:&_isDir]){
            if (![[NSFileManager defaultManager] createDirectoryAtPath:videoFilePath withIntermediateDirectories:YES attributes:nil error:nil]) {

            }
        }

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self clearTempVideos];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)dealloc
{
    self.overlayView.delegate = nil;
}

#pragma mark - Methods

- (void)refreshVideoDuration:(NSTimer *)timer
{
    self.videoTotalDuration += 0.1;
    NSLog(@"video total time...:%f",self.videoTotalDuration);
    
    CGFloat percent = self.videoTotalDuration / 30.0 ;
    [_overlayView updateProgressViewToPercentage:percent];
    
    if (self.videoTotalDuration < MIN_VIDEO_DURATION) {
        [self.overlayView setAlbumAndSubmitBtnStatus:NO];
    }else {
        [self.overlayView setAlbumAndSubmitBtnStatus:YES];
    }
    if (self.videoTotalDuration >= MAX_VIDEO_DURATION) {
        
        [self doEndCurVideo];
        
    }
}

/**
 *  @description: combine those video clips in temp directory to a single video,
 *                and then crop them to fit the crop frame.
 */
- (void)combineAndCropSingleVideo
{
    __weak VNVideoCaptureViewController *weakSelf = self;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime startTime = kCMTimeZero;
    
    //for loop to combine clips into a single video
    for (NSInteger i=0; i < weakSelf.videoPathArr.count; i++) {
        
        NSString *pathString = [NSString stringWithString:[weakSelf.videoPathArr objectAtIndex:i]];
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:pathString] options:nil];
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        
        //set the orientation
        if(i == 0)
        {
            [compositionVideoTrack setPreferredTransform:videoTrack.preferredTransform];
        }
        
        BOOL ok;
        ok = [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:videoTrack atTime:startTime error:nil];
        ok = [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:audioTrack atTime:startTime error:nil];
        
        startTime = CMTimeAdd(startTime, [asset duration]);
    }
    
    //export the combined video
    
    NSString *combinedPath = [videoFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Final.mov",TEMP_VIDEO_NAME_PREFIX]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:combinedPath error:nil];
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSURL *url = [NSURL fileURLWithPath:combinedPath];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
        exporter.outputURL = url;
        exporter.outputFileType = [[exporter supportedFileTypes] objectAtIndex:0];
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                switch ([exporter status]) {
                    case AVAssetExportSessionStatusFailed:
                    {
                        [weakSelf.overlayView hideCombiningMsg];
                        NSLog(@"111111Export failed: %@", [[exporter error] localizedDescription]);
                    }
                        break;
                    case AVAssetExportSessionStatusCancelled:
                    {
                        [weakSelf.overlayView hideCombiningMsg];
                        NSLog(@"111111Export canceled");
                    }
                        break;
                    default:
                        [weakSelf cropSingleVideo];
                        
                        break;
                }
            });
        }];

    });
}

- (void)cropSingleVideo
{
    
    /*******************************************************************************************/
    
    //crop the single video
    
    //export the combined video
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSString *combinedPath = [videoFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@1.mov",TEMP_VIDEO_NAME_PREFIX]];
        
        AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:combinedPath] options:nil];
        
        AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        //create a video composition and preset some settings
        AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.frameDuration = CMTimeMake(1, 30);
        //here we are setting its render size to its height x height (Square)
        videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
        
        //create a video instruction
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));
        
        AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
        
        //Here we shift the viewing square up to the TOP of the video so we only see the top
        //CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, 0 );
        
        //Use this code if you want the viewing square to be in the middle of the video
        CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2 );
        
        //Make sure the square is portrait
        CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
        
        CGAffineTransform finalTransform = t2;
        [transformer setTransform:finalTransform atTime:kCMTimeZero];
        
        //add the transformer layer instructions, then add to video composition
        instruction.layerInstructions = [NSArray arrayWithObject:transformer];
        videoComposition.instructions = [NSArray arrayWithObject: instruction];
        
        //Create an Export Path to store the cropped video
        NSString *cropPath = [videoFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@FinalCropped.mp4",TEMP_VIDEO_NAME_PREFIX]];;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSFileManager defaultManager] removeItemAtPath:cropPath error:nil];
        });
        
        NSURL *exportUrl = [NSURL fileURLWithPath:cropPath];
        
        //Export
        AVAssetExportSession *finalExporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality] ;
        finalExporter.videoComposition = videoComposition;
        finalExporter.outputURL = exportUrl;
        finalExporter.outputFileType = AVFileTypeMPEG4;
        
        __weak VNVideoCaptureViewController *weakSelf = self;
        
        [finalExporter exportAsynchronouslyWithCompletionHandler:^
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [weakSelf.overlayView hideCombiningMsg];
                 switch ([finalExporter status]) {
                     case AVAssetExportSessionStatusFailed:
                         NSLog(@"Export failed: %@", [[finalExporter error] localizedDescription]);
                         break;
                     case AVAssetExportSessionStatusCancelled:
                         NSLog(@"Export canceled");
                         break;
                     default:
                         
                         [weakSelf pushToCoverSettingCtl];
                         
                         break;
                 }
             });
         }];
    });
}

#pragma mark - VNCameraOverlayViewDelegate

- (void)doCloseCurrentController
{
    if(self.videoTotalDuration != 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"确定要放弃这段视频么？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        void (^clearVideoBlock)(NSInteger) = ^(NSInteger buttonIndex){
            if (buttonIndex == 0) {
                //do nothing...
            } else {
                [self clearTempVideos];
            }
        };
        objc_setAssociatedObject(alert, @"ClearVideosAlert",
                                 clearVideoBlock, OBJC_ASSOCIATION_COPY);
        
        [alert show];
    }else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

/**
 *  @description: clear temp videos in temp directory.
 */
- (void)clearTempVideos
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSLog(@"%@",[fm contentsOfDirectoryAtPath:videoFilePath error:nil]);
    
    NSArray *arr = [fm contentsOfDirectoryAtPath:videoFilePath error:nil];
    
    for (NSString *dir in arr) {
        if ([dir hasPrefix:TEMP_VIDEO_NAME_PREFIX]) {
            [fm removeItemAtPath:[videoFilePath stringByAppendingPathComponent:dir] error:nil];
        }
    }
    
    NSLog(@"%@",[fm contentsOfDirectoryAtPath:videoFilePath error:nil]);
}

- (void)doChangeTorchStatusTo:(BOOL)isOn
{
    if (isOn) {
        [self.videoInput.device setTorchMode:AVCaptureTorchModeOn];
    }else {
        [self.videoInput.device setTorchMode:AVCaptureTorchModeOff];
    }
}

- (AVCaptureDevice *)backFacingCamera {

    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionBack)
        {
            captureDevice = device;
            break;
        }
    }

    [captureDevice lockForConfiguration:nil];
    
    return captureDevice;
}

- (AVCaptureDevice *)frontFacingCamera {
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

/**
 *  @description: change camera device. (frong or rear.)
 *
 *  @param isRear : declares which kind of camera device to change to.
 */
- (void)doChangeDeviceTo:(BOOL)isRear
{
    [self.captureSession removeInput:self.videoInput];

    if (isRear) {

        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self backFacingCamera] error:nil];
        [self.overlayView setTorchBtnHidden:NO];
    }else {
        
        
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self frontFacingCamera] error:nil];

        [self.overlayView setTorchBtnHidden:YES];
    }
    [self.captureSession addInput:self.videoInput];

}

/**
 *  @description: delecte the newest video clip.
 */
- (void)doDeleteCurrentVideo
{
    //删除当前片段
    
    NSString *currVideoPath = [videoFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%d.mov",TEMP_VIDEO_NAME_PREFIX,self.videoPieceCount]];
    
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:currVideoPath error:&err];
    if (!err) {
        [self.videoTimePointArr removeLastObject];
        
        self.videoTotalDuration = [[self.videoTimePointArr lastObject] floatValue];
        
        self.videoPieceCount--;
        if (self.videoPieceCount == 0) {
            [self.overlayView setTrashBtnEnabled:NO];
        }
        [self.videoPathArr removeLastObject];
        
        [self.overlayView setProgressTimeArr:self.videoTimePointArr];
        
        CGFloat percent = self.videoTotalDuration / 30.0 ;
        
        [_overlayView updateProgressViewToPercentage:percent];

    }
}

/**
 *  @description: begin current video capturing.
 */
- (void)doStartNewVideoRecord
{
    [self.overlayView setProgressViewBlinking:NO];
    
    
    NSString *currVideoPath = [videoFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%d.mov",TEMP_VIDEO_NAME_PREFIX,self.videoPieceCount+1]];
    
    [self.videoPathArr addObject:currVideoPath];

    [self.movieOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:currVideoPath] recordingDelegate:self];
}

/**
 *  @description: end current video capture.
 */
- (void)doEndCurVideo
{
    [self.overlayView setProgressViewBlinking:YES];
    
    if ([_durationTimer isValid]) {
        [_durationTimer invalidate];
        _durationTimer = nil;
    }
    
    [self.movieOutput stopRecording];
    
    if (self.videoTotalDuration >= MAX_VIDEO_DURATION) {
        [self doSubmitWholeVideo];
    }
}

/**
 *  @description: combine and crop video clips.
 */
- (void)doSubmitWholeVideo
{
    if (self.videoTotalDuration >= MIN_VIDEO_DURATION) {
        
        [self.overlayView showCombiningMsg];
        
        if (self.videoPieceCount == 1) {
            [self cropSingleVideo];
        }else {
            [self combineAndCropSingleVideo];
        }
    }
}

- (void) pushToCoverSettingCtl
{
    NSString *combinedPath = [videoFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@FinalCropped.mp4",TEMP_VIDEO_NAME_PREFIX]];
    VNVideoCoverSettingController *coverSettingCtl = [[VNVideoCoverSettingController alloc] init];
    coverSettingCtl.videoPath = combinedPath;
    [self.navigationController pushViewController:coverSettingCtl animated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    void (^clearVideoBlock)(NSInteger) = objc_getAssociatedObject(alertView, @"ClearVideosAlert");
    
    clearVideoBlock(buttonIndex);
    
    objc_removeAssociatedObjects(alertView);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
            recordedSuccessfully = [value boolValue];
        // Logging the problem anyway:
        NSLog(@"A problem occurred while recording: %@", error);
        [self.videoPathArr removeLastObject];
    }
    if (recordedSuccessfully) {
        
        //record videos' path & save current video to temp directory for later use.
        
        self.videoPieceCount++;
        if (self.videoPieceCount > 0)
            [self.overlayView setTrashBtnEnabled:YES];
        
        [self.videoTimePointArr addObject:[NSNumber numberWithFloat:self.videoTotalDuration]];
        
        [self.overlayView setProgressTimeArr:self.videoTimePointArr];
        
        //get current video file duration.
        //video duration array stores video files' duration data, for process bar
        
        if (self.videoTotalDuration >= MAX_VIDEO_DURATION) {
            __weak VNVideoCaptureViewController *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [weakSelf combineAndCropSingleVideo];
            });
            
        }
        
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    
    _durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(refreshVideoDuration:) userInfo:nil repeats:YES];
    
    [_durationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1.]];
}

@end
