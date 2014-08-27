//
//  VNVideoCoverSettingViewController.m
//  VideoNews
//
//  Created by zhangxue on 14-8-15.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoCoverSettingViewController.h"
#import "VNVideoFramesView.h"
#import <AVFoundation/AVFoundation.h>

@interface VNVideoCoverSettingViewController () <VNVideoFramesViewDelegate>

@property (nonatomic, strong) UIImageView *videoCoverImgView;        //封面展示
@property (nonatomic, strong) VNVideoFramesView *videoFramesView;    //缩略图

@property (nonatomic, assign) CGFloat coverTime;

@end

#define screenH ([[UIScreen mainScreen] bounds].size.height)

@implementation VNVideoCoverSettingViewController

#pragma mark - Initialization

- (UIImageView *)videoCoverImgView
{
    if (!_videoCoverImgView) {

        _videoCoverImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 87, 320, 320)];
        _videoCoverImgView.backgroundColor = [UIColor clearColor];
    }
    return _videoCoverImgView;
}


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
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 44)];
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = @"设置封面";
    titleLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
    [topView addSubview:titleLbl];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 44)];
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(doPopBack) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:backBtn];
    
    UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(260, 20, 60, 44)];
//    [submitBtn setImage:[UIImage imageNamed:@"video_next"] forState:UIControlStateNormal];
//    [submitBtn setImage:[UIImage imageNamed:@"video_next"] forState:UIControlStateSelected];
    [submitBtn setTitle:@"完成" forState:UIControlStateNormal];
    [submitBtn setTitle:@"完成" forState:UIControlStateSelected];
    [submitBtn setTitleColor:[UIColor colorWithRGBValue:0xCE2426] forState:UIControlStateNormal];
    [submitBtn setTitleColor:[UIColor colorWithRGBValue:0xCE2426] forState:UIControlStateSelected];
    [submitBtn addTarget:self action:@selector(doSubmit) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:submitBtn];
    
    [self.view addSubview:topView];
    
    //video cover view
    [self.view addSubview:self.videoCoverImgView];

    UILabel *descLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 432, 320, 30)];
    descLbl.backgroundColor = [UIColor clearColor];
    descLbl.text = @"滑动可选择封面";
    descLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:14];
    descLbl.textColor = [UIColor colorWithRGBValue:0x606366];
    descLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:descLbl];
    
    _videoFramesView = [[VNVideoFramesView alloc] initWithFrame:CGRectMake(0, 475, 320, 42) andVideoPath:self.videoPath];
    _videoFramesView.delegate = self;
    _videoFramesView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_videoFramesView];
    
    self.coverTime = 0;
    
    [self setVideoCoverWithTime:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)dealloc
{
    NSLog(@"dealloc....:%s",__FUNCTION__);
}

#pragma mark - UserInteractionMethods

- (void)doPopBack
{
    //没有设置，回去直接dismiss 所以设置时间很长10000,不会达到
    [[NSNotificationCenter defaultCenter] postNotificationName:VNVideoCoverDidChangedNotification object:nil userInfo:@{@"coverImg":self.videoCoverImgView.image, @"coverTime":[NSNumber numberWithFloat:10000]}];
}

- (void)doSubmit
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VNVideoCoverDidChangedNotification object:nil userInfo:@{@"coverImg":self.videoCoverImgView.image, @"coverTime":[NSNumber numberWithFloat:self.coverTime]}];
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
    
    imageGenerator.maximumSize = CGSizeMake(320, 320);
    
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

#pragma mark - VNVideoFramesViewDelegate

- (void)didSelecteTime:(CGFloat)time
{
    [self setVideoCoverWithTime:time];
}

@end
