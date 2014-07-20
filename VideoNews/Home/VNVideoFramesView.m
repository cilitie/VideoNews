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

@end

@implementation VNVideoFramesView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame andVideoPath:(NSString *)videoPath
{
    self = [super initWithFrame:frame];
    if (self) {
        _videoPath = videoPath;
        
        [self generateImagesOfVideo];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
    }
    return self;
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
    
    int picWidth = 30;
    
    CGFloat durationSeconds = CMTimeGetSeconds([myAsset duration]);
    self.duration = durationSeconds;
    
    int picsCnt = ceil(320 / picWidth) + 1;
    
    NSMutableArray *allTimes = [[NSMutableArray alloc] init];
    
    int time4Pic = 0;
    NSError *error;
    CMTime actualTime;
    int prefreWidth=0;
    
    //generate frames.
    for (int i=1, ii = 0; i<= picsCnt; i++){
        
        time4Pic = i * picWidth;
        
        CMTime timeFrame = CMTimeMakeWithSeconds(durationSeconds * time4Pic / 320, 600);
        
        [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
        
        CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:timeFrame actualTime:&actualTime error:&error];
        
        UIImage *videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
        
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        
        CGRect currentFrame = tmp.frame;
        currentFrame.origin.x = ii * picWidth;
        
        currentFrame.size.width=picWidth;
        prefreWidth += currentFrame.size.width;
        
        if( i == picsCnt-1){
            currentFrame.size.width-=6;
        }
        tmp.frame = currentFrame;
        int all = (ii+1)*tmp.frame.size.width;
        
        if (all > 320){
            int delta = all - 320;
            currentFrame.size.width -= delta;
        }
        
        ii++;
        
        __weak VNVideoFramesView *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf addSubview:tmp];
        });
        
        CGImageRelease(halfWayImage);
    }
    
}

- (void) handlePan:(UIPanGestureRecognizer *)gesture
{
    CGFloat x = [gesture locationInView:self].x;
    if (delegate && [delegate respondsToSelector:@selector(didSelecteTime:)]) {
        [delegate didSelecteTime:x / self.frame.size.width * self.duration];
    }
}

@end
