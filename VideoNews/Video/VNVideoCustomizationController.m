//
//  VNVideoCustomizationController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-20.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoCustomizationController.h"
#import <AVFoundation/AVFoundation.h>
#import "VNAVPlayerPlayView.h"
#import "ColorUtils.h"
#import "VNVideoShareViewController.h"
#import "VNAudioListController.h"
#import <MBProgressHUD.h>
#import "VNVideoFilterListScrollView.h"
#import "GPUImage.h"

@interface VNVideoCustomizationController () <VNAudioListDelegate, VNVideoFilterListScrollViewDelegate, VNVideoFilterListScrollViewDataSource>

@property (nonatomic, strong) VNAVPlayerPlayView *videoPlayView;     //播放视频的view
@property (nonatomic ,strong) AVPlayer *videoPlayer;                  //播放视频player
@property (nonatomic, strong) AVPlayerItem *videoPlayerItem;

@property (nonatomic, assign) BOOL isVolumePositive;              //声音是否打开

@property (nonatomic, copy) NSString *audioPath;

@property (nonatomic, assign) CGFloat coverTime;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;           //音频播放器

@property (nonatomic, strong) MBProgressHUD *hud;                   //提示

//filter related
@property (nonatomic, strong) NSArray *filterTypeArr;               //filter type supported.
@property (nonatomic, strong) GPUImageMovie *movieFile;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filterFirst;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filterLast;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, assign) VNVideoFilterType filterType;
@property (nonatomic, strong) GPUImageView *filterVideoView;

@property (nonatomic, assign) BOOL isFilterOn;                      //是否有滤镜效果

@end

@implementation VNVideoCustomizationController

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

- (MBProgressHUD *)hud
{
    if (!_hud) {
        _hud = [[MBProgressHUD alloc] init];
        _hud.minSize = CGSizeMake(100, 100);
        _hud.labelText = @"生成视频...";
    }
    return _hud;
}

- (GPUImageMovie *)movieFile
{
    if (!_movieFile) {
        _movieFile = [[GPUImageMovie alloc] initWithPlayerItem:self.videoPlayerItem];
        _movieFile.runBenchmark = YES;
        _movieFile.playAtActualSpeed = YES;
    }
    return _movieFile;
}

- (GPUImageView *)filterVideoView
{
    if (!_filterVideoView) {
        _filterVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 64, 320, 320)];
        _filterVideoView.backgroundColor = [UIColor clearColor];
        _filterVideoView.hidden = YES;
    }
    return _filterVideoView;
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
    
    [self.view addSubview:self.filterVideoView];
    
    self.isVolumePositive = YES;
    self.audioPath = nil;
    self.isFilterOn = NO;
    
    self.filterTypeArr = @[[NSNumber numberWithInteger:VNVideoFilterTypeNone],
                           [NSNumber numberWithInteger:VNVideoFilterTypeSepiaTone],
                           [NSNumber numberWithInteger:VNVideoFilterTypeToneCureve],
                           [NSNumber numberWithInteger:VNVideoFilterTypeSoftElegance],
                           [NSNumber numberWithInteger:VNVideoFilterTypeGrayscale],
                           [NSNumber numberWithInteger:VNVideoFilterTypeTiltShift],
                           [NSNumber numberWithInteger:VNVideoFilterTypeVignette],
                           [NSNumber numberWithInteger:VNVideoFilterTypeGaussianSelectiveBlur],
                           [NSNumber numberWithInteger:VNVideoFilterTypeSaturation],
                           [NSNumber numberWithInteger:VNVideoFilterTypeMissEtikate]];
    
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
    
    NSURL *videoUrl = [NSURL fileURLWithPath:self.videoPath];
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    _videoPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_videoPlayerItem];

    [self playVideoWithSound:YES];
        
    VNVideoFilterListScrollView *filterListView = [[VNVideoFilterListScrollView alloc] initWithFrame:CGRectMake(0, 483, 320, 70)];
    filterListView.dataSource = self;
    filterListView.delegate = self;
    [self.view addSubview:filterListView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [filterListView loadData];
    });
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(resumeAVPlayer) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self.view addSubview:self.hud];

}

- (void)resumeAVPlayer
{
    if (self.videoPlayer) {
        [self.videoPlayer play];
    }
    if (self.audioPlayer) {
        [self.audioPlayer play];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    __weak typeof(self) weakSelf = self;
    if (_audioPlayer) [_audioPlayer stop];
    [_videoPlayer seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^ (BOOL finish){
        
        weakSelf.audioPlayer.currentTime = 0;
        if (weakSelf.audioPlayer) [weakSelf.audioPlayer play];
        [weakSelf.videoPlayer play];
        [self setupFilter];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self clearFilter];
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
    [self.videoPlayer removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

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
    [self clearFilter];
    [self clearTempVideo];
    
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
        __weak typeof(self) weakSelf = self;
        [_audioPlayer stop];
        [_videoPlayer seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^ (BOOL finish){
            weakSelf.audioPlayer.currentTime = 0;
            [weakSelf.audioPlayer play];
            [weakSelf.videoPlayer play];
            
            [self setupFilter];
        }];
}

//play a video.
- (void)playVideoWithSound:(BOOL)soundEnable
{
    __weak VNVideoCustomizationController *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        weakSelf.videoPlayer = [AVPlayer playerWithPlayerItem:_videoPlayerItem];
        [weakSelf.videoPlayer addObserver:weakSelf forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    });
}

- (UIImage *)getCoverImageOfTimeZeroWithVideoFilePath:(NSString *)filePath
{

    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    imageGenerator.maximumSize = CGSizeMake(320, 320);
    
    // First image
    NSError *error;
    CMTime actualTime;
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
    if (halfWayImage != NULL) {
        
        UIImage *img = [UIImage imageWithCGImage:halfWayImage];
        CGImageRelease(halfWayImage);
        return img;
    }
    return nil;
}

- (void)doSubmit
{
    __weak typeof(self) weakSelf = self;
    if (_audioPlayer) [_audioPlayer stop];
    [_videoPlayer seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^ (BOOL finish){

        weakSelf.audioPlayer.currentTime = 0;
        if (weakSelf.audioPlayer) [weakSelf.audioPlayer pause];
        [weakSelf.videoPlayer pause];
    }];

    if (self.isVolumePositive && !self.audioPath && !self.isFilterOn) {
        //self audio on && audio file off && no filter
        UIImage *zeroCover = [self getCoverImageOfTimeZeroWithVideoFilePath:self.videoPath];
        VNVideoShareViewController *shareViewCtl = [[VNVideoShareViewController alloc] initWithVideoPath:self.videoPath andCoverImage:zeroCover];
        shareViewCtl.fromDraft = NO;
        shareViewCtl.coverTime = self.coverTime;
        [self.navigationController pushViewController:shareViewCtl animated:YES];
        
    }else {
        
        [self.hud show:YES];
        
        if (!self.isFilterOn) {
            AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
            
            [self combineVideoAndAudioTracks:videoAsset];

        }else {
            //filtered video file path

            [self clearFilter];
            
            _movieFile = nil;
            _filterFirst = nil;
            _filterLast = nil;
            _movieWriter = nil;
            
            _movieFile = [[GPUImageMovie alloc] initWithURL:[NSURL fileURLWithPath:self.videoPath]];
            _movieFile.runBenchmark = YES;
            _movieFile.playAtActualSpeed = NO;
            

            [self setFilterBasedOnType];
            
            [_movieFile addTarget:_filterFirst];
            
            GPUImageView *tempFilterVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 64, 320, 320)];
            [tempFilterVideoView setBackgroundColorRed:0 green:0 blue:0 alpha:0];
            tempFilterVideoView.hidden = YES;
            [self.view addSubview:tempFilterVideoView];
            [_filterLast addTarget:tempFilterVideoView];
            
            // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
            NSString *filterFilePath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:@"VN_Video_filter.mp4"];
            unlink([filterFilePath UTF8String]);
            NSURL *movieURL = [NSURL fileURLWithPath:filterFilePath];
            
            _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(360, 360)];
            [_filterLast addTarget:self.movieWriter];
            
            // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
            
//            _movieWriter.shouldPassthroughAudio = YES;
//            _movieFile.audioEncodingTarget = _movieWriter;
            [_movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];
            
            [_movieWriter startRecording];
            [_movieFile startProcessing];
            
            __weak VNVideoCustomizationController *weakSelf = self;
            
            AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:filterFilePath] options:nil];

            [_movieWriter setCompletionBlock:^{
                [weakSelf.filterLast removeTarget:weakSelf.movieWriter];
                [weakSelf.movieWriter finishRecording];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [tempFilterVideoView removeFromSuperview];
                    [weakSelf combineVideoAndAudioTracks:videoAsset];
                    weakSelf.movieFile = nil;
                    [weakSelf clearFilter];
                });
            }];
            
            [_movieWriter setFailureBlock:^(NSError *err) {
                [tempFilterVideoView removeFromSuperview];
                weakSelf.movieFile = nil;
            }];
        }
    }
}

- (void)combineVideoAndAudioTracks:(AVURLAsset *)videoAsset
{

    NSString *filePath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:@"VN_Video_share.mp4"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    });
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    if (self.isVolumePositive) {
        AVURLAsset* audioAssetUser = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
        
        NSArray *audioArr = [audioAssetUser tracksWithMediaType:AVMediaTypeAudio];
        if (audioArr && audioArr.count > 0) {
            AVMutableCompositionTrack *compositionCommentaryTrack2 = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                                 preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionCommentaryTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                                 ofTrack:[audioArr objectAtIndex:0]
                                                  atTime:kCMTimeZero error:nil];
        }
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
    
    __weak VNVideoCustomizationController *weakSelf = self;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf.hud hide:YES];
            
            switch ([_assetExport status]) {
                case AVAssetExportSessionStatusFailed:
                {
                    NSLog(@"Export failed: %@", [[_assetExport error] localizedDescription]);
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    NSLog(@"Export canceled");
                }
                    break;
                default:
                {

                    UIImage *zeroCover = [weakSelf getCoverImageOfTimeZeroWithVideoFilePath:filePath];
                    VNVideoShareViewController *shareViewCtl = [[VNVideoShareViewController alloc] initWithVideoPath:filePath andCoverImage:zeroCover];
                    shareViewCtl.fromDraft = NO;
                    shareViewCtl.coverTime = self.coverTime;
                    [weakSelf.navigationController pushViewController:shareViewCtl animated:YES];
                    
                }
                    break;
            }
        });
    }];
}

#pragma mark - VNAudioListDelegate

- (void)didSelectedAudioAtFilePath:(NSString *)filePath
{
    self.audioPath = filePath;
    
    //replay video.
    
    __weak typeof(self) weakSelf = self;
    [_videoPlayer seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^ (BOOL finish){
        [weakSelf.videoPlayer pause];
        
        [_videoPlayer play];
        
        if (!filePath) {
            [weakSelf.audioPlayer stop];
            weakSelf.audioPlayer = nil;
        }else {
            NSError *error;
            NSURL *audioFileUrl = [NSURL fileURLWithPath:weakSelf.audioPath];
            weakSelf.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:&error];
            
            if (!audioFileUrl || error) {
                NSLog(@"音频读取出错了。。。");
            }else {
                [weakSelf.audioPlayer play];
            }
        }
        
    }];
}

#pragma mark - UICollectionViewDelegate && UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

#pragma mark - VNVideoFilterListScrollViewDelegate && DataSource

- (NSInteger)numberOfComponentsInFilterList
{
    return [self.filterTypeArr count];
}

- (UIImage *)imageForComponentAtIndex:(NSInteger)index
{
    return [UIImage imageNamed:@"camera"];
}

- (NSString *)titleForComponentAtIndex:(NSInteger)index
{
    VNVideoFilterType filterT = [[self.filterTypeArr objectAtIndex:index] integerValue];

    NSString *title;
    switch (filterT) {
        case VNVideoFilterTypeNone:                   title = @"无";              break;
        case VNVideoFilterTypeSepiaTone:              title = @"sepia tone";      break;
        case VNVideoFilterTypeToneCureve:             title = @"tone curve";      break;
        case VNVideoFilterTypeSoftElegance:           title = @"soft elegance";   break;
        case VNVideoFilterTypeGrayscale:              title = @"grayscale";       break;
        case VNVideoFilterTypeTiltShift:              title = @"tilt shift";      break;
        case VNVideoFilterTypeVignette:               title = @"vignette";        break;
        case VNVideoFilterTypeGaussianSelectiveBlur:  title = @"gaussian";        break;
        case VNVideoFilterTypeSaturation:             title = @"saturation";      break;
        case VNVideoFilterTypeMissEtikate:            title = @"miss etikate";    break;
        default:
            break;
    }
    return title;
}

- (void)didSelectComponentAtIndex:(NSInteger)index
{
    
    self.filterType = [[self.filterTypeArr objectAtIndex:index] integerValue];
    
    [self setupFilter];
}

- (void)setupFilter
{
    if (self.filterType == VNVideoFilterTypeNone) {
        self.isFilterOn = NO;
    }else {
        self.isFilterOn = YES;
    }
    if (_filterFirst || _filterLast) {

        [self clearFilter];
        
        _filterFirst = nil;
        _filterLast = nil;
    }
    
    [self setFilterBasedOnType];
    
    if (self.isFilterOn) {
        
        self.filterVideoView.hidden = NO;

        [self.movieFile addTarget:_filterFirst];
        
        [_filterLast addTarget:self.filterVideoView];
        
        // In addition to displaying to the screen, write out a processed version of the movie to disk
        // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
        NSString *filterFilePath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:@"VN_Video_filter.mp4"];
        unlink([filterFilePath UTF8String]);
        NSURL *movieURL = [NSURL fileURLWithPath:filterFilePath];
        
        _movieWriter = nil;
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(360, 360)];
        [_filterLast addTarget:self.movieWriter];
        
        // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
//        _movieWriter.shouldPassthroughAudio = YES;
//        _movieFile.audioEncodingTarget = _movieWriter;
        [_movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];

        [_movieWriter startRecording];
        [_movieFile startProcessing];

        __weak VNVideoCustomizationController *weakSelf = self;
        
        [_movieWriter setCompletionBlock:^{
            [weakSelf.filterLast removeTarget:weakSelf.movieWriter];
            [weakSelf.movieWriter finishRecording];
        }];
        
        [_movieWriter setFailureBlock:^(NSError *err){
        }];
        
    }else {
        self.filterVideoView.hidden = YES;
    }
}

- (void)clearFilter
{
//    if (_movieWriter) {
//        [self.movieWriter cancelRecording];
//    }
    [self.movieFile removeTarget:_filterFirst];
//    [self.movieFile endProcessing];
//    self.movieFile.audioEncodingTarget = nil;
//
//    [_filter removeAllTargets];
//    
//    _filter = nil;
//    _movieWriter = nil;
}

- (void)setFilterBasedOnType
{
    switch (self.filterType) {
        case VNVideoFilterTypeNone:
        {
        }
            break;
        case VNVideoFilterTypeSepiaTone:
        {
            
            _filterFirst = [[GPUImageSepiaFilter alloc] init];
            [(GPUImageSepiaFilter *)_filterFirst setIntensity:0.8];  //强度
            
            GPUImageToneCurveFilter *tmpFilter = [[GPUImageToneCurveFilter alloc] init];
            [tmpFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.8)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
            
            _filterLast = [[GPUImageTiltShiftFilter alloc] init];
            [(GPUImageTiltShiftFilter *)_filterLast setTopFocusLevel:0.3];
            [(GPUImageTiltShiftFilter *)_filterLast setBottomFocusLevel:0.5];
            
            [_filterFirst addTarget:tmpFilter];
            [tmpFilter addTarget:_filterLast];
        }
            break;
        case VNVideoFilterTypeToneCureve:
        {
            _filterFirst = [[GPUImageToneCurveFilter alloc] init];
            [(GPUImageToneCurveFilter *)_filterFirst setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.8)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
            _filterLast = _filterFirst;
        }
            break;
        case VNVideoFilterTypeSoftElegance:
        {
            _filterFirst = [[GPUImageSoftEleganceFilter alloc] init];
            _filterLast = _filterFirst;
        }
            break;
        case VNVideoFilterTypeGrayscale:
        {
            _filterFirst = [[GPUImageGrayscaleFilter alloc] init];
            _filterLast = _filterFirst;
        }
            break;
        case VNVideoFilterTypeTiltShift:
        {
            _filterFirst = [[GPUImageTiltShiftFilter alloc] init];
            [(GPUImageTiltShiftFilter *)_filterFirst setTopFocusLevel:0.3];
            [(GPUImageTiltShiftFilter *)_filterFirst setBottomFocusLevel:0.5];
            _filterLast = _filterFirst;
        }
            break;
        case VNVideoFilterTypeVignette:
        {
            _filterFirst = [[GPUImageVignetteFilter alloc] init];
            [(GPUImageVignetteFilter *)_filterFirst setVignetteEnd:0.5];
            _filterLast = _filterFirst;
        }
            break;
        case VNVideoFilterTypeGaussianSelectiveBlur:
        {
            _filterFirst = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)_filterFirst setExcludeCircleRadius:40.0/320.0];
            _filterLast = _filterFirst;
        }
            break;
        case VNVideoFilterTypeSaturation:
        {
            _filterFirst = [[GPUImageSaturationFilter alloc] init];
            [(GPUImageSaturationFilter *)_filterFirst setSaturation:2];
            _filterLast = _filterFirst;
        }
            break;
        case VNVideoFilterTypeMissEtikate:
        {
            _filterFirst = [[GPUImageMissEtikateFilter alloc] init];
        }
            break;
        default:
            break;
    }

}

@end
