//
//  VNVideoFramesView.m
//  VideoNews
//
//  Created by zhangxue on 14-7-20.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoFramesView.h"
#import <AVFoundation/AVFoundation.h>

@interface VNVideoFramesView() <UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, strong) UIImageView *showImgView;    //正在展示的缩略图

@end

@implementation VNVideoFramesView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame andVideoPath:(NSString *)videoPath
{
    self = [super initWithFrame:frame];
    if (self) {
        _videoPath = videoPath;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
        
        _showImgView = [[UIImageView alloc] initWithFrame:CGRectMake(-3, -3, 26, 36)];
        _showImgView.backgroundColor = [UIColor clearColor];
        _showImgView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _showImgView.layer.borderWidth = 1.5;
        _showImgView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:_showImgView];
        
        [self generateImagesOfVideo];
    }
    return self;
}

- (void)setThumbCoverImage:(UIImage *)img
{
    _showImgView.image = img;
}

/**
 *  @description: generate frames of video.
 */
- (void)generateImagesOfVideo
{
    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.maximumSize = CGSizeMake(60, 60);
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    int picWidth = 21;
    int picHeight = 30;
    
    CGFloat durationSeconds = CMTimeGetSeconds([myAsset duration]);
    self.duration = durationSeconds;
    
    int picsCnt = ceil(320 / picWidth) + 1;
    
    NSMutableArray *allTimes = [[NSMutableArray alloc] init];
    
    int time4Pic = 0;
    NSError *error;
    CMTime actualTime;
    
    //generate frames.
    for (int i=0, ii = 0; i< picsCnt; i++){
        
        time4Pic = i * picWidth;
        
        CMTime timeFrame = CMTimeMakeWithSeconds(durationSeconds * time4Pic / 320, myAsset.duration.timescale);
        
        [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
        
        CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:timeFrame actualTime:&actualTime error:&error];
        
        UIImage *videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
        
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        
        CGRect currentFrame = tmp.frame;
        currentFrame.origin.x = ii * picWidth;
        currentFrame.size.width = picWidth;
        currentFrame.size.height = picHeight;

        tmp.frame = currentFrame;
        
        ii++;
        
        __weak VNVideoFramesView *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf addSubview:tmp];
            [weakSelf bringSubviewToFront:_showImgView];
        });
        
        CGImageRelease(halfWayImage);
    }
    
}

- (void) handlePan:(UIPanGestureRecognizer *)gesture
{
    CGFloat x = [gesture locationInView:self].x;
    
    //adjust the frame of showimageview
    CGRect frame = _showImgView.frame;
    if (x < 0) {
        frame.origin.x = 0;
    }else {
        frame.origin.x = x;
    }
    
    if (x > self.frame.size.width - 21) {
        frame.origin.x = self.frame.size.width - 21;
    }else {
        frame.origin.x = x;
    }
    _showImgView.frame = frame;
    
    if (delegate && [delegate respondsToSelector:@selector(didSelecteTime:)]) {
        [delegate didSelecteTime:x / self.frame.size.width * self.duration];
    }
}

- (void)hideDisplayImageView
{
    _showImgView.hidden = YES;
}

@end
