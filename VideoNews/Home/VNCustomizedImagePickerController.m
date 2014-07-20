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
#import <objc/runtime.h>

#import "VNHTTPRequestManager.h"
#import <AFNetworking.h>

#import "VNVideoCoverSettingController.h"

@interface VNCustomizedImagePickerController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, VNCameraOverlayViewDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) VNCameraOverlayView *overlayView;

//an array
@property (nonatomic, strong) NSMutableArray *videoPathArr;
@property (nonatomic, strong) NSMutableArray *videoDurationArr;

@property (nonatomic, assign) CGFloat videoTotalDuration;
@property (nonatomic, assign) NSInteger videoPieceCount;

@property (nonatomic, strong) NSTimer *durationTimer;
@end

@implementation VNCustomizedImagePickerController

#define MIN_VIDEO_DURATION 5.0
#define MAX_VIDEO_DURATION 8.0
#define TEMP_VIDEO_NAME_PREFIX @"VN_Video_"

#pragma mark - Initialization

- (VNCameraOverlayView *)overlayView
{
    if (!_overlayView) {
        _overlayView = [[VNCameraOverlayView alloc] initWithFrame:self.view.frame];
        _overlayView.delegate = self;
    }
    return _overlayView;
}

- (NSMutableArray *)videoPathArr
{
    if (!_videoPathArr){
        _videoPathArr = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _videoPathArr;
}

- (NSMutableArray *)_videoDurationArr
{
    if (!_videoDurationArr) {
        _videoDurationArr = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _videoDurationArr;
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
        self.showsCameraControls = NO;
        self.videoQuality = UIImagePickerControllerQualityTypeHigh;
        
        self.cameraOverlayView = self.overlayView;
        
        self.videoPieceCount = 0;
        self.videoTotalDuration = 0;
    
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    
//    NSData *imgData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"IMG_3699" ofType:@"PNG"]];
//    NSString *dataLength = [NSString stringWithFormat:@"%d",imgData.length];
//    
//    NSDictionary *params = @{@"Authorization":@"OSS qn6qrrqxo2oawuk53otfjbyc:kZoYNv66bsmc10+dcGKw5x2PRrk=",@"Content-Encoding":@"utf-8",@"Content-Disposition":@"attachment",@"filename":@"oss_download.jpg",@"Content-Type":@"image/jpg",@"Expires":[NSDate dateWithTimeIntervalSinceNow:365 * 24 * 60 * 60],@"Content-Length":dataLength};
//    
//    [manager PUT:@"oss-example.oss-cn-hangzhou.aliyuncs.com" parameters:params success:^(AFHTTPRequestOperation *operation, id responseData){
//        
//        
//        NSLog(@"成功了:\n%@",responseData);
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *err) {
//        
//        NSLog(@"error::::%@",err.userInfo);
//        
//    }];
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

- (void)refreshVideoDuration:(NSTimer *)timer
{
    self.videoTotalDuration += 1;
    NSLog(@"video total time...:%f",self.videoTotalDuration);

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
    /*******************************************************************************************/
    // combine video clips
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime startTime = kCMTimeZero;
    
    NSLog(@"video path array:%@",self.videoPathArr);
    //for loop to combine clips into a single video
    for (NSInteger i=0; i < self.videoPathArr.count; i++) {
        
        NSURL *url = [NSURL fileURLWithPath:[self.videoPathArr objectAtIndex:i]];
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        
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
    NSString *tempDir = NSTemporaryDirectory();
    
    NSString *combinedPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Final.MOV",TEMP_VIDEO_NAME_PREFIX]];
    
    [[NSFileManager defaultManager] removeItemAtPath:combinedPath error:nil];

    NSURL *url = [NSURL fileURLWithPath:combinedPath];

    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
    exporter.outputURL = url;
    exporter.outputFileType = [[exporter supportedFileTypes] objectAtIndex:0];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"111111Export failed: %@", [[exporter error] localizedDescription]);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"111111Export canceled");
                break;
            default:
            {
//                UISaveVideoAtPathToSavedPhotosAlbum(combinedPath, self, nil, nil);
                
                
                /*******************************************************************************************/

                //crop the single video
                
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
                NSString *tempDir = NSTemporaryDirectory();
                NSString *combinedPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@FinalCropped.MOV",TEMP_VIDEO_NAME_PREFIX]];
                
                [[NSFileManager defaultManager] removeItemAtPath:combinedPath error:nil];

                NSURL *exportUrl = [NSURL fileURLWithPath:combinedPath];
                
                //Export
                AVAssetExportSession *finalExporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
                finalExporter.videoComposition = videoComposition;
                finalExporter.outputURL = exportUrl;
                finalExporter.outputFileType = AVFileTypeQuickTimeMovie;
                
                [finalExporter exportAsynchronouslyWithCompletionHandler:^
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         //Call when finished
                         switch ([finalExporter status]) {
                             case AVAssetExportSessionStatusFailed:
                                 NSLog(@"Export failed: %@", [[finalExporter error] localizedDescription]);
                                 break;
                             case AVAssetExportSessionStatusCancelled:
                                 NSLog(@"Export canceled");
                                 break;
                             default:
                             {
//                                 UISaveVideoAtPathToSavedPhotosAlbum(combinedPath, self, nil, nil);
                                 
                                 VNVideoCoverSettingController *coverSettingCtl = [[VNVideoCoverSettingController alloc] init];
                                 coverSettingCtl.videoPath = combinedPath;
                                 [self pushViewController:coverSettingCtl animated:YES];
                             }
                                 break;
                         }
                         
                     });
                 }];
            }
                break;
        }
    }];
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
    NSString *tempDir = NSTemporaryDirectory();
    
    NSLog(@"%@",[fm contentsOfDirectoryAtPath:tempDir error:nil]);

    NSArray *arr = [fm contentsOfDirectoryAtPath:tempDir error:nil];
    
    for (NSString *dir in arr) {
        if ([dir hasPrefix:TEMP_VIDEO_NAME_PREFIX]) {
            [fm removeItemAtPath:[tempDir stringByAppendingPathComponent:dir] error:nil];
        }
    }
    
    NSLog(@"%@",[fm contentsOfDirectoryAtPath:tempDir error:nil]);
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

- (void)doStartNewVideoRecord
{
    //开始新的
    if ([self startVideoCapture]) {

        _durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshVideoDuration:) userInfo:nil repeats:YES];

        [_durationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1.]];
    }else {
        NSLog(@"failed to start video capture.");
    }
}

- (void)doEndCurVideo
{
    if (self.videoTotalDuration <= MAX_VIDEO_DURATION) {
        
        if ([_durationTimer isValid]) {
            [_durationTimer invalidate];
            _durationTimer = nil;
        }
        
        [self stopVideoCapture];
    }
}

- (void)doSubmitWholeVideo
{
    if (self.videoTotalDuration >= MIN_VIDEO_DURATION) {
        [self combineAndCropSingleVideo];
    }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.movie"] && picker.sourceType == UIImagePickerControllerSourceTypeCamera){
        
        NSString *tempDir = NSTemporaryDirectory();

        NSString *currVideoPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%d.MOV",TEMP_VIDEO_NAME_PREFIX,self.videoPieceCount]];
        self.videoPieceCount++;
        
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSLog(@"%@", videoURL);

        
        //record videos' path & save current video to temp directory for later use.
        
        __weak VNCustomizedImagePickerController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
            
            if ([videoData writeToFile:currVideoPath atomically:YES]) {
                [weakSelf.videoPathArr addObject:currVideoPath];
                NSLog(@"path arr:%@",weakSelf.videoPathArr);
                
                //get current video file duration.
                //video duration array stores video files' duration data, for process bar
                
                AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
                float currVideoDuration = anAsset.duration.value / anAsset.duration.timescale;
                
                NSLog(@"curr duration ...:%f",currVideoDuration);
                
                [weakSelf.videoDurationArr addObject:[NSNumber numberWithFloat:currVideoDuration]];
                
                NSFileManager *fm = [NSFileManager defaultManager];
                
                NSArray *arr = [fm contentsOfDirectoryAtPath:tempDir error:nil];
                
                NSLog(@"arr...:%@",arr);
                
                if (weakSelf.videoTotalDuration >= MAX_VIDEO_DURATION) {
                    [weakSelf combineAndCropSingleVideo];
                }
            }
        });

    }

}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    void (^clearVideoBlock)(NSInteger) = objc_getAssociatedObject(alertView, @"ClearVideosAlert");
    
    clearVideoBlock(buttonIndex);
    
    objc_removeAssociatedObjects(alertView);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
