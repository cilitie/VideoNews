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

@interface VNAlbumVideoEditController ()

@property (nonatomic, strong) UIScrollView *videoScrollView;
@property (nonatomic, strong) VNAVPlayerPlayView *videoPlayView;     //播放视频的view
@property (nonatomic ,strong) AVPlayer *videoPlayer;                  //播放视频player

@property (nonatomic, strong) VNVideoFramesView *videoFramesView;    //缩略图

@property (nonatomic, copy) NSString *videoPath;

@end

@implementation VNAlbumVideoEditController

#pragma mark - Initialization

- (UIScrollView *)videoScrollView
{
    if (!_videoScrollView) {
        _videoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, 320, 320)];
        _videoScrollView.backgroundColor = [UIColor clearColor];
        _videoScrollView.showsVerticalScrollIndicator = NO;
    }
    return _videoScrollView;
}

- (UIView *)videoPlayView
{
    if (!_videoPlayView) {
        _videoPlayView = [[VNAVPlayerPlayView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
        _videoPlayView.backgroundColor = [UIColor lightGrayColor];
    }
    return _videoPlayView;
}

#pragma mark - ViewLifeCycle

- (id)initWithVideoPath:(NSString *)videoP
{
    self = [super init];
    if (self) {

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
        titleLbl.text = @"编辑视频";
        titleLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
        [topView addSubview:titleLbl];
        
        [self.view addSubview:topView];
     
        self.videoPath = videoP;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    VNProgressViewForAlbum *progressView = [[VNProgressViewForAlbum alloc] initWithFrame:CGRectMake(0, 384, 320, 10)];
    [progressView addTarget:self action:@selector(progressValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    __weak VNAlbumVideoEditController *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [weakSelf.view addSubview:weakSelf.videoScrollView];
        [weakSelf.videoScrollView addSubview:weakSelf.videoPlayView];
        [weakSelf playVideo];
        
        //generate images of video
        weakSelf.videoFramesView = [[VNVideoFramesView alloc] initWithFrame:CGRectMake(0, 394, 320, 30) andVideoPath:self.videoPath];
        weakSelf.videoFramesView.backgroundColor = [UIColor clearColor];
        [weakSelf.videoFramesView hideDisplayImageView];
        weakSelf.videoFramesView.userInteractionEnabled = NO;
        
        NSURL *videoURL = [NSURL fileURLWithPath:self.videoPath];
        AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        float currVideoDuration = anAsset.duration.value / anAsset.duration.timescale;
        progressView.maximumValue = currVideoDuration;
        progressView.value = currVideoDuration;
        
        [weakSelf.view addSubview:progressView];
        [weakSelf.view addSubview:_videoFramesView];
        
    });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

#pragma mark - User & Interaction Methods

- (void)doPopBack
{
    [self.videoPlayer removeObserver:self forKeyPath:@"status"];
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
    
}

//observe for player start.
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (_videoPlayer.status == AVPlayerStatusReadyToPlay) {
        
        [(AVPlayerLayer *)[self.videoPlayView layer] setPlayer:_videoPlayer];
//        [_videoPlayer play];
    }
}

- (void)progressValueChanged:(VNProgressViewForAlbum *)slider
{
    if (slider.value >= 5) {
        CMTime time = CMTimeMakeWithSeconds(slider.value, 600);
        [_videoPlayer seekToTime:time];
        //    [_videoPlayer pause];
    }else {
        slider.value = 5;
    }
}



@end
