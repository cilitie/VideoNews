//
//  VNAlbumVideoEditController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-23.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNAlbumVideoEditController.h"
#import "VNAVPlayerPlayView.h"
#import <AVFoundation/AVFoundation.h>
#import "VNVideoFramesView.h"
#import "VNProgressViewForAlbum.h"
#import "VNVideoCoverSettingController.h"
#import <MBProgressHUD.h>

@interface VNAlbumVideoEditController ()

@property (nonatomic, strong) UIScrollView *videoScrollView;
@property (nonatomic, strong) VNAVPlayerPlayView *videoPlayView;     //播放视频的view
@property (nonatomic ,strong) AVPlayer *videoPlayer;                  //播放视频player

@property (nonatomic, strong) VNVideoFramesView *videoFramesView;    //缩略图

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CGFloat timeScale;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) UIImageView *playBtnImg;

@property (nonatomic, strong) id mTimeObserver;

@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, assign) VNVideoOrientation orientation;
@end

@implementation VNAlbumVideoEditController

#define TEMP_VIDEO_NAME_PREFIX @"VN_Video_"
#define screenH ([[UIScreen mainScreen] bounds].size.height)

#pragma mark - Initialization

- (MBProgressHUD *)hud
{
    if (!_hud) {
        _hud = [[MBProgressHUD alloc] init];
        _hud.minSize = CGSizeMake(100, 100);
        _hud.labelText = @"正在合成视频，请稍后";
    }
    return _hud;
}

#pragma mark - ViewLifeCycle

- (id)initWithVideoPath:(NSString *)videoP andSize:(CGSize)s andScale:(CGFloat)scale andOrientation:(VNVideoOrientation)ori
{
    self = [super init];
    if (self) {

        self.view.backgroundColor = [UIColor colorWithRGBValue:0xE1E1E1];
        
        //initialize top bar view.
        UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
        topView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
        
        UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 44)];
        [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [backBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
        [backBtn addTarget:self action:@selector(doPopBack) forControlEvents:UIControlEventTouchUpInside];
        [topView addSubview:backBtn];
        
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 44)];
        titleLbl.backgroundColor = [UIColor clearColor];
        titleLbl.text = @"编辑视频";
        titleLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
        [topView addSubview:titleLbl];
        
        UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(260, 20, 60, 44)];
        [submitBtn setImage:[UIImage imageNamed:@"video_next"] forState:UIControlStateNormal];
        [submitBtn setImage:[UIImage imageNamed:@"video_next"] forState:UIControlStateSelected];
        [submitBtn addTarget:self action:@selector(doSubmit) forControlEvents:UIControlEventTouchUpInside];
        [topView addSubview:submitBtn];
        
        [self.view addSubview:topView];
     
        self.videoPath = videoP;
        self.size = CGSizeMake(s.width, s.height);
        self.timeScale = scale;
        
        self.isPlaying = NO;
        
        self.orientation = ori;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak VNAlbumVideoEditController *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        CGFloat width, height, width2, height2;
        
        if (weakSelf.size.height > weakSelf.size.width) {
            width = 320;
            width2 = 320;
            height = 320 * weakSelf.size.height / weakSelf.size.width;
            height2 = (height > 320)?height:320;
        }else if (weakSelf.size.width > weakSelf.size.height) {
            width = 320 * weakSelf.size.width / weakSelf.size.height;
            width2 = (width > 320)?width:320;
            height = 320;
            height2 = 320;
        }else {
            width = 320;
            width2 = 320;
            height = 320;
            height2 = 320;
        }
        
        weakSelf.videoPlayView = [[VNAVPlayerPlayView alloc] initWithFrame:CGRectMake(0, 0, width2, height2)];
        weakSelf.videoPlayView.backgroundColor = [UIColor lightGrayColor];
        
        weakSelf.videoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, (screenH - 64 - 360) / 2 + 64, 320, 320)];
        weakSelf.videoScrollView.backgroundColor = [UIColor clearColor];
        weakSelf.videoScrollView.showsVerticalScrollIndicator = NO;
        weakSelf.videoScrollView.bounces = NO;
        weakSelf.videoScrollView.contentSize = CGSizeMake(width2, height2);
        if (height2 > 320 || width2 > 320) {
            [weakSelf.videoScrollView scrollRectToVisible:CGRectMake((width - 320) / 2, (height - 320)/2 , 320, 320) animated:NO];
        }
        
        [weakSelf.view addSubview:weakSelf.videoScrollView];
        [weakSelf.videoScrollView addSubview:weakSelf.videoPlayView];
        
        VNProgressViewForAlbum *progressView = [[VNProgressViewForAlbum alloc] initWithFrame:CGRectMake(0, (screenH - 64 - 360) / 2 + 384, 320, 10)];
        [progressView addTarget:weakSelf action:@selector(progressValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        [weakSelf playVideo];
        
        //generate images of video
        weakSelf.videoFramesView = [[VNVideoFramesView alloc] initWithFrame:CGRectMake(0, (screenH - 64 - 360) / 2 + 392, 320, 30) andVideoPath:self.videoPath];
        weakSelf.videoFramesView.backgroundColor = [UIColor clearColor];
        [weakSelf.videoFramesView hideDisplayImageView];
        weakSelf.videoFramesView.userInteractionEnabled = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSURL *videoURL = [NSURL fileURLWithPath:weakSelf.videoPath];
            AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
            float currVideoDuration = anAsset.duration.value / anAsset.duration.timescale;
                        
            progressView.maximumValue = currVideoDuration;
            progressView.value = currVideoDuration;
            weakSelf.duration = currVideoDuration;
            [weakSelf.view addSubview:weakSelf.videoFramesView];
            [weakSelf.view addSubview:progressView];
            
            weakSelf.playBtnImg = [[UIImageView alloc] initWithFrame:CGRectMake(130, (screenH - 64 - 360) / 2 + 194, 60, 60)];
            weakSelf.playBtnImg.backgroundColor = [UIColor clearColor];
            weakSelf.playBtnImg.image = [UIImage imageNamed:@"video_play"];
//            [weakSelf.playBtn setImage:[UIImage imageNamed:@"video_play"] forState:UIControlStateNormal];
//            [weakSelf.playBtn setImage:[UIImage imageNamed:@"blank"] forState:UIControlStateSelected];
//            [weakSelf.playBtn addTarget:weakSelf action:@selector(playTheVideo:) forControlEvents:UIControlEventTouchUpInside];
            [weakSelf.view addSubview:weakSelf.playBtnImg];
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
            [weakSelf.videoScrollView addGestureRecognizer:tapGesture];
            
            [weakSelf.view addSubview:self.hud];

        });
        
    });
    
}

- (void)handleTap:(UITapGestureRecognizer *)reg
{
    if (reg.state == UIGestureRecognizerStateEnded) {
        [self playTheVideo:!self.isPlaying];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.videoPlayer) {
        self.isPlaying = NO;
        [self.videoPlayer pause];
    }
}

- (void)dealloc
{
    NSLog(@"dalloc......:%s",__FUNCTION__);
    [self.videoPlayer removeObserver:self forKeyPath:@"status"];
    [self.videoPlayer removeTimeObserver:_mTimeObserver];
}

#pragma mark - User & Interaction Methods

- (void)doPopBack
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;

- (void)playVideo
{
    
    NSURL *videoUrl = [NSURL fileURLWithPath:self.videoPath];
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    AVPlayerItem * newPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    self.videoPlayer = [AVPlayer playerWithPlayerItem:newPlayerItem];
    [self.videoPlayer addObserver:self forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    
    __weak VNAlbumVideoEditController *weakSelf = self;
    _mTimeObserver = [self.videoPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time){
        CGFloat currentSecond = weakSelf.videoPlayer.currentTime.value / weakSelf.videoPlayer.currentTime.timescale;// 计算当前在第几秒
        if (currentSecond >= weakSelf.duration) {
            weakSelf.isPlaying = NO;
            [weakSelf.videoPlayer pause];
            [weakSelf.playBtnImg setImage:[UIImage imageNamed:@"video_play"]];
            [weakSelf.videoPlayer seekToTime:kCMTimeZero];
        }
    }];
    
}

- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (_videoPlayer.status == AVPlayerStatusReadyToPlay) {
        
        [(AVPlayerLayer *)[self.videoPlayView layer] setPlayer:_videoPlayer];
    }
}

- (void)progressValueChanged:(VNProgressViewForAlbum *)slider
{
    if (slider.value >= 5) {
        CMTime time = CMTimeMakeWithSeconds(slider.value, self.timeScale);
        [_videoPlayer seekToTime:time];
        [slider setNeedsDisplay];
    }else {
        slider.value = 5;
    }
    self.duration = slider.value;
}

- (void)playTheVideo:(BOOL)select
{
    
    if (select) {
        self.isPlaying = YES;
        [_videoPlayer play];
        [self.playBtnImg setImage:[UIImage imageNamed:@"blank"]];
    }else {
        self.isPlaying = NO;
        [_videoPlayer pause];
        [self.playBtnImg setImage:[UIImage imageNamed:@"video_play"]];
    }
}

- (void)doSubmit
{
    
    [self.hud show:YES];
    
    __weak VNAlbumVideoEditController *weakSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
        
        AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                
        //create a video composition and preset some settings
        AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        CGFloat width = MIN(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.height);
        videoComposition.renderSize = CGSizeMake(width, width);
        
        //create a video instruction
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(30, asset.duration.timescale));
        
        AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    
        CGAffineTransform finalTransform;
        
        switch (self.orientation) {
            case VNVideoOrientationLeft:
            {
                CGFloat diffX = weakSelf.videoScrollView.contentOffset.x * clipVideoTrack.naturalSize.width / weakSelf.videoScrollView.contentSize.width;
                CGFloat diffY = weakSelf.videoScrollView.contentOffset.y * clipVideoTrack.naturalSize.height / weakSelf.videoScrollView.contentSize.height;
                
                CGAffineTransform t1 = CGAffineTransformMakeTranslation(-diffX, -diffY);
                finalTransform = t1;
            }
                break;
            case VNVideoOrientationRight:
            {
                CGFloat diffX =  (weakSelf.videoScrollView.contentSize.width - weakSelf.videoScrollView.contentOffset.x )/ weakSelf.videoScrollView.contentSize.width * clipVideoTrack.naturalSize.width ;
                
                CGAffineTransform t1 = CGAffineTransformMakeTranslation(diffX, clipVideoTrack.naturalSize.height);
                finalTransform = CGAffineTransformRotate(t1, M_PI);
            }
                break;
            case VNVideoOrientationPortrait:
            {
                CGFloat diff;
                if (clipVideoTrack.naturalSize.width != clipVideoTrack.naturalSize.height) {
                    diff = -  weakSelf.videoScrollView.contentOffset.y * clipVideoTrack.naturalSize.height / 320;
                }else {
                    diff = 0;
                }
                
                CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, diff);
                finalTransform = CGAffineTransformRotate(t1, M_PI_2);
            }
                break;
            case VNVideoOrientationUpsideDown:
            {
                CGFloat diff;
                if (clipVideoTrack.naturalSize.width != clipVideoTrack.naturalSize.height) {
                    diff = (weakSelf.videoScrollView.contentSize.height + 320 - weakSelf.videoScrollView.contentOffset.y) * clipVideoTrack.naturalSize.height / weakSelf.videoScrollView.contentSize.height;
                }else {
                    diff = 0;
                }
                CGAffineTransform t1 = CGAffineTransformMakeTranslation(0, diff);
                finalTransform = CGAffineTransformRotate(t1, -M_PI_2);
            }
                break;
            default:
                break;
        }
        
        [transformer setTransform:finalTransform atTime:kCMTimeZero];
        
        //add the transformer layer instructions, then add to video composition
        instruction.layerInstructions = [NSArray arrayWithObject:transformer];
        videoComposition.instructions = [NSArray arrayWithObject: instruction];
        
        //Create an Export Path to store the cropped video
        NSString *cropPath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Cropped.mp4",TEMP_VIDEO_NAME_PREFIX]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSFileManager defaultManager] removeItemAtPath:cropPath error:nil];
        });
        
        NSURL *exportUrl = [NSURL fileURLWithPath:cropPath];
        
        //Export
        AVAssetExportSession *finalExporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality] ;
        finalExporter.videoComposition = videoComposition;
        finalExporter.outputURL = exportUrl;
        finalExporter.outputFileType = AVFileTypeMPEG4;
        
        CMTime duration = CMTimeMakeWithSeconds(self.duration, self.timeScale);
        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, duration);
        finalExporter.timeRange = range;
        
        [finalExporter exportAsynchronouslyWithCompletionHandler:^
         {
             dispatch_async(dispatch_get_main_queue(), ^{

                 [weakSelf.hud hide:YES];
                 
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

- (void) pushToCoverSettingCtl
{
    NSString *combinedPath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Cropped.mp4",TEMP_VIDEO_NAME_PREFIX]];
    VNVideoCoverSettingController *coverSettingCtl = [[VNVideoCoverSettingController alloc] init];
    coverSettingCtl.videoPath = combinedPath;
    [self.navigationController pushViewController:coverSettingCtl animated:YES];
}


@end
