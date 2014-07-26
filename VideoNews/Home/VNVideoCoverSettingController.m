//
//  VNVideoCoverSettingController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-20.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoCoverSettingController.h"
#import <AVFoundation/AVFoundation.h>
#import "VNAVPlayerPlayView.h"
#import "ColorUtils.h"
#import "VNVideoFramesView.h"
#import "VNVideoShareViewController.h"

@interface VNVideoCoverSettingController () <VNVideoFramesViewDelegate>

@property (nonatomic, strong) VNAVPlayerPlayView *videoPlayView;     //播放视频的view
@property (nonatomic ,strong) AVPlayer *videoPlayer;                  //播放视频player
@property (nonatomic, strong) AVPlayerItem *videoPlayerItem;

@property (nonatomic, strong) UIImageView *videoCoverImgView;        //封面展示
@property (nonatomic, strong) VNVideoFramesView *videoFramesView;    //缩略图

@property (nonatomic, assign) BOOL isVolumePositive;              //声音是否打开

@end

@implementation VNVideoCoverSettingController

@synthesize videoPath;

#pragma mark - Initialization

- (UIView *)videoPlayView
{
    if (!_videoPlayView) {
        _videoPlayView = [[VNAVPlayerPlayView alloc] initWithFrame:CGRectMake(0, 64, 320, 320)];
        _videoPlayView.backgroundColor = [UIColor lightGrayColor];
    }
    return _videoPlayView;
}

- (UIImageView *)videoCoverImgView
{
    if (!_videoCoverImgView) {
        _videoCoverImgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 395, 130, 130)];
        _videoCoverImgView.backgroundColor = [UIColor clearColor];
    }
    return _videoCoverImgView;
}

#pragma mark - ViewLifeCycle

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#define TEMP_VIDEO_NAME_PREFIX @"VN_Video_"
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //initialize top bar view.
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    topView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 45, 44)];
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(doPopBack) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:backBtn];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 44)];
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = @"设置封面";
    titleLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
    [topView addSubview:titleLbl];
    
    UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(275, 20, 45, 44)];
    [submitBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [submitBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [submitBtn addTarget:self action:@selector(doSubmit) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:submitBtn];
    
    [self.view addSubview:topView];
    
    //add video play view.
    [self.view addSubview:self.videoPlayView];

    //video cover view
    [self.view addSubview:self.videoCoverImgView];
    
    self.isVolumePositive = YES;
    
    //generate images of video
    _videoFramesView = [[VNVideoFramesView alloc] initWithFrame:CGRectMake(0, 535, 320, 30) andVideoPath:self.videoPath];
    _videoFramesView.delegate = self;
    _videoFramesView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_videoFramesView];
    
    UIButton *soundBtn = [[UIButton alloc] initWithFrame:CGRectMake(265, 400, 30, 30)];
    soundBtn.backgroundColor = [UIColor blackColor];
    [soundBtn setTitle:@"ON" forState:UIControlStateNormal];
    [soundBtn setTitle:@"OFF" forState:UIControlStateSelected];
    [soundBtn addTarget:self action:@selector(soundSetting:) forControlEvents:UIControlEventTouchUpInside];
    soundBtn.selected = NO;   //on-sound off-nosound
    [self.view addSubview:soundBtn];
    
    [self setVideoCoverWithTime:0];

    [self playVideoWithSound:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)dealloc
{
    
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

#pragma mark - User & Interaction Methods

- (void)doPopBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)soundSetting:(UIButton *)sender
{
    NSURL *videoUrl = [NSURL fileURLWithPath:self.videoPath];
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =    [AVMutableAudioMixInputParameters audioMixInputParameters];
        if (sender.selected) {
            //set volume to 1.0
            [audioInputParams setVolume:1.0 atTime:kCMTimeZero];
            self.isVolumePositive = YES;
        }else {
            //set volume to 0.. disable sound.
            [audioInputParams setVolume:0.0 atTime:kCMTimeZero];
            self.isVolumePositive = NO;
        }
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioZeroMix = [AVMutableAudioMix audioMix];
    [audioZeroMix setInputParameters:allAudioParams];
    
    [self.videoPlayerItem setAudioMix:audioZeroMix];
    
    sender.selected = !sender.selected;
}

//observe for player start.
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (_videoPlayer.status == AVPlayerStatusReadyToPlay) {

        [(AVPlayerLayer *)[self.videoPlayView layer] setPlayer:_videoPlayer];
        [_videoPlayer play];
    }
}

//observe for player stop, replay.
- (void)playerItemDidReachEnd:(AVPlayerItem *)playerItem
{
    [_videoPlayer seekToTime:kCMTimeZero];
    [_videoPlayer play];
}

//play a video.
- (void)playVideoWithSound:(BOOL)soundEnable
{
    __weak VNVideoCoverSettingController *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSURL *videoUrl = [NSURL fileURLWithPath:weakSelf.videoPath];
        AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
        
        weakSelf.videoPlayerItem = [AVPlayerItem playerItemWithAsset:asset];

        [[NSNotificationCenter defaultCenter] addObserver:weakSelf
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:_videoPlayerItem];
        
        weakSelf.videoPlayer = [AVPlayer playerWithPlayerItem:_videoPlayerItem];
        [weakSelf.videoPlayer addObserver:weakSelf forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    });
}

/**
 *  @description: generate cover image at certain time.
 *
 *  @param time, input time(secs).
 */
- (void)setVideoCoverWithTime:(CGFloat)time
{
    
    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    imageGenerator.maximumSize = CGSizeMake(260, 260);
    
    CMTime timeFrame = CMTimeMakeWithSeconds(time , myAsset.duration.timescale);

    // First image
    NSError *error;
    CMTime actualTime;
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:timeFrame actualTime:&actualTime error:&error];
    if (halfWayImage != NULL) {

        UIImage *img = [UIImage imageWithCGImage:halfWayImage];
        self.videoCoverImgView.image = img;
        [_videoFramesView setThumbCoverImage:img];
        CGImageRelease(halfWayImage);
    }
}

- (void)doSubmit
{

    if (self.isVolumePositive) {
        
        VNVideoShareViewController *shareViewCtl = [[VNVideoShareViewController alloc] initWithVideoPath:self.videoPath andCoverImage:self.videoCoverImgView.image];
        [self.navigationController pushViewController:shareViewCtl animated:YES];
        
    }else {
        
        NSString *filePath = [[VNUtility getNSCachePath:@"VideoFiles"] stringByAppendingPathComponent:@"VN_Video_share.mov"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        
        AVMutableComposition *composition = [AVMutableComposition
                                             composition];
        
        AVURLAsset * sourceAsset = [[AVURLAsset alloc] initWithURL:[NSURL
                                                                    fileURLWithPath:self.videoPath] options:nil];
        
        AVMutableCompositionTrack *compositionVideoTrack = [composition
                                                            addMutableTrackWithMediaType:AVMediaTypeVideo
                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        
        BOOL ok = NO;
        
        AVAssetTrack * sourceVideoTrack = [[sourceAsset
                                            tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CMTimeRange x = CMTimeRangeMake(kCMTimeZero, [sourceAsset
                                                      duration]);
        
        ok = [compositionVideoTrack insertTimeRange:x ofTrack:sourceVideoTrack
                                             atTime:kCMTimeZero error:nil];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                           initWithAsset:composition
                                           presetName:AVAssetExportPresetHighestQuality];
        
        exporter.outputURL = [NSURL fileURLWithPath:filePath];
        
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        __weak VNVideoCoverSettingController *weakSelf = self;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                switch ([exporter status]) {
                    case AVAssetExportSessionStatusFailed:
                    {
                        NSLog(@"111111Export failed: %@", [[exporter error] localizedDescription]);
                    }
                        break;
                    case AVAssetExportSessionStatusCancelled:
                    {
                        NSLog(@"111111Export canceled");
                    }
                        break;
                    default:
                    {
                        VNVideoShareViewController *shareViewCtl = [[VNVideoShareViewController alloc] initWithVideoPath:weakSelf.videoPath andCoverImage:weakSelf.videoCoverImgView.image];
                        [weakSelf.navigationController pushViewController:shareViewCtl animated:YES];
                    }
                        break;
                }
            });
        }];
    }
}

#pragma mark - VNVideoFramesViewDelegate

- (void)didSelecteTime:(CGFloat)time
{
    [self setVideoCoverWithTime:time];
}

@end
