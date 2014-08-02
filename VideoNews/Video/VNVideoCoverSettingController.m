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
#import "VNAudioListController.h"
#import <MBProgressHUD.h>

@interface VNVideoCoverSettingController () <VNVideoFramesViewDelegate, VNAudioListDelegate>

@property (nonatomic, strong) VNAVPlayerPlayView *videoPlayView;     //播放视频的view
@property (nonatomic ,strong) AVPlayer *videoPlayer;                  //播放视频player
@property (nonatomic, strong) AVPlayerItem *videoPlayerItem;

@property (nonatomic, strong) UIImageView *videoCoverImgView;        //封面展示
@property (nonatomic, strong) VNVideoFramesView *videoFramesView;    //缩略图

@property (nonatomic, assign) BOOL isVolumePositive;              //声音是否打开

@property (nonatomic, copy) NSString *audioPath;

@property (nonatomic, assign) CGFloat coverTime;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;           //音频播放器

@property (nonatomic, strong) MBProgressHUD *hud;                   //提示

@end

@implementation VNVideoCoverSettingController

@synthesize videoPath;

#define TEMP_VIDEO_NAME_PREFIX @"VN_Video_"
#define screenH ([[UIScreen mainScreen] bounds].size.height)

static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;

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
        CGFloat coverY,coverH;
        if (screenH == 568) {
            coverY = 395;
            coverH = 130;
        }else {
            coverY = 395;
            coverH = 50;
        }
        _videoCoverImgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, coverY, coverH, coverH)];
        _videoCoverImgView.backgroundColor = [UIColor clearColor];
    }
    return _videoCoverImgView;
}

- (MBProgressHUD *)hud
{
    if (!_hud) {
        _hud = [[MBProgressHUD alloc] init];
        _hud.minSize = CGSizeMake(100, 100);
        _hud.labelText = @"生成视频...";
    }
    return _hud;
}

#pragma mark - ViewLifeCycle

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    titleLbl.text = @"设置封面";
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
    
    //add video play view.
    [self.view addSubview:self.videoPlayView];

    //video cover view
    [self.view addSubview:self.videoCoverImgView];
    
    self.isVolumePositive = YES;
    self.audioPath = nil;
    //generate images of video
    
    CGFloat framesY,framesH, btnY, lblY;
    if (screenH == 568) {
        framesY = 535;
        framesH = 30;
        btnY = 400;
        lblY = 435;
    }else {
        framesY = 450;
        framesH = 26;
        btnY = 395;
        lblY = 430;
    }
    
    _videoFramesView = [[VNVideoFramesView alloc] initWithFrame:CGRectMake(0, framesY, 320, framesH) andVideoPath:self.videoPath];
    _videoFramesView.delegate = self;
    _videoFramesView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_videoFramesView];
    
    UIButton *addMusicBtn = [[UIButton alloc] initWithFrame:CGRectMake(185, btnY, 30, 30)];
    addMusicBtn.backgroundColor = [UIColor clearColor];
    [addMusicBtn setImage:[UIImage imageNamed:@"video_music"] forState:UIControlStateNormal];
    [addMusicBtn setImage:[UIImage imageNamed:@"video_music"] forState:UIControlStateSelected];
    [addMusicBtn addTarget:self action:@selector(selectMusic) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addMusicBtn];
    
    UILabel *addMusicLbl = [[UILabel alloc] initWithFrame:CGRectMake(160, lblY, 80, 20)];
    addMusicLbl.backgroundColor = [UIColor clearColor];
    addMusicLbl.textColor = [UIColor colorWithRGBValue:0x606366];
    addMusicLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:10];
    addMusicLbl.textAlignment = NSTextAlignmentCenter;
    addMusicLbl.text = @"添加音乐";
    [self.view addSubview:addMusicLbl];
    
    UIButton *soundBtn = [[UIButton alloc] initWithFrame:CGRectMake(265, btnY, 30, 30)];
    soundBtn.backgroundColor = [UIColor clearColor];
    [soundBtn setImage:[UIImage imageNamed:@"audio_on"] forState:UIControlStateNormal];
    [soundBtn setImage:[UIImage imageNamed:@"audio_off"] forState:UIControlStateSelected];
    [soundBtn addTarget:self action:@selector(soundSetting:) forControlEvents:UIControlEventTouchUpInside];
    soundBtn.selected = NO;   //on-sound off-nosound
    [self.view addSubview:soundBtn];
    
    UILabel *soundLbl = [[UILabel alloc] initWithFrame:CGRectMake(240, lblY, 80, 20)];
    soundLbl.backgroundColor = [UIColor clearColor];
    soundLbl.textColor = [UIColor colorWithRGBValue:0x606366];
    soundLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:10];
    soundLbl.textAlignment = NSTextAlignmentCenter;
    soundLbl.text = @"原声关闭";
    [self.view addSubview:soundLbl];
    
    [self setVideoCoverWithTime:0];

    [self playVideoWithSound:YES];
    
    [self.view addSubview:_hud];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.videoPlayer) {
        [self.videoPlayer play];
    }
    if (self.audioPlayer) {
        [self.audioPlayer play];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.videoPlayer) {
        [self.videoPlayer pause];
    }
    if (self.audioPlayer) {
        [_audioPlayer pause];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)dealloc
{
    NSLog(@"dealloc......:%s",__FUNCTION__);
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
    [self clearTempVideo];
    
    [self.videoPlayer removeObserver:self forKeyPath:@"status"];
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 *  @description: clear temp videos in temp directory.
 */
- (void)clearTempVideo
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *videoFilePath = [VNUtility getNSCachePath:@"VideoFiles/Temp"];
    
    NSArray *arr = [fm contentsOfDirectoryAtPath:videoFilePath error:nil];
    
    for (NSString *dir in arr) {
        [fm removeItemAtPath:[videoFilePath stringByAppendingPathComponent:dir] error:nil];
    }
    
}

/**
 *  @description: select music.
 */
- (void)selectMusic
{
    VNAudioListController *audioListCtl = [[VNAudioListController alloc] init];
    audioListCtl.delegate = self;
    audioListCtl.onSelectionAudioPath = self.audioPath;
    [self presentViewController:audioListCtl animated:YES completion:nil];
}

/**
 *  @description: turn on/off the original audio
 *
 *  @param sender : input button
 */
- (void)soundSetting:(UIButton *)sender
{
    NSURL *videoUrl = [NSURL fileURLWithPath:self.videoPath];
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {

        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
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
    [_audioPlayer stop];
    _audioPlayer.currentTime = 0;
    [_audioPlayer play];
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
    
    self.coverTime = time;
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

    if (self.isVolumePositive && !self.audioPath) {
        
        VNVideoShareViewController *shareViewCtl = [[VNVideoShareViewController alloc] initWithVideoPath:self.videoPath andCoverImage:self.videoCoverImgView.image];
        shareViewCtl.fromDraft = NO;
        shareViewCtl.coverTime = self.coverTime;
        [self.navigationController pushViewController:shareViewCtl animated:YES];
        
    }else {
        
        [self.hud show:YES];
        
        NSString *filePath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:@"VN_Video_share.mp4"];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
        });
        
        AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
        
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        
        if (self.isVolumePositive) {
            AVURLAsset* audioAssetUser = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
            AVMutableCompositionTrack *compositionCommentaryTrack2 = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                                 preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionCommentaryTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                                 ofTrack:[[audioAssetUser tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                                  atTime:kCMTimeZero error:nil];
        }

        
        if (self.audioPath) {
            
            AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:self.audioPath] options:nil];
            
            AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                                ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                                 atTime:kCMTimeZero error:nil];
        }
        
    
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                       ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                        atTime:kCMTimeZero error:nil];
        
        AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                              presetName:AVAssetExportPresetHighestQuality];
        
        NSURL *exportUrl = [NSURL fileURLWithPath:filePath];
        
        _assetExport.outputFileType = AVFileTypeMPEG4;
        _assetExport.outputURL = exportUrl;
        _assetExport.shouldOptimizeForNetworkUse = YES;
        
        __weak VNVideoCoverSettingController *weakSelf = self;
        
        [_assetExport exportAsynchronouslyWithCompletionHandler:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [weakSelf.hud hide:YES];
                
                switch ([_assetExport status]) {
                    case AVAssetExportSessionStatusFailed:
                    {
                        NSLog(@"111111Export failed: %@", [[_assetExport error] localizedDescription]);
                    }
                        break;
                    case AVAssetExportSessionStatusCancelled:
                    {
                        NSLog(@"111111Export canceled");
                    }
                        break;
                    default:
                    {
                        
                        VNVideoShareViewController *shareViewCtl = [[VNVideoShareViewController alloc] initWithVideoPath:filePath andCoverImage:weakSelf.videoCoverImgView.image];
                        shareViewCtl.fromDraft = NO;
                        shareViewCtl.coverTime = self.coverTime;
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

#pragma mark - VNAudioListDelegate

- (void)didSelectedAudioAtFilePath:(NSString *)filePath
{
    self.audioPath = filePath;
    
    //replay video.
    [_videoPlayer seekToTime:kCMTimeZero];
    [_videoPlayer play];
    
    if (!filePath) {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }else {
        NSError *error;
        NSURL *audioFileUrl = [NSURL fileURLWithPath:self.audioPath];
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:&error];
        
        if (!audioFileUrl || error) {
            NSLog(@"音频读取出错了。。。");
        }else {
            [_audioPlayer play];
        }
    }
}

@end
