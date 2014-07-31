//
//  VNProfileVideoTableViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProfileVideoTableViewCell.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VNProfileVideoTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *videoImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentNumLabel;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer;
@property (strong, nonatomic) UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeightLC;

- (IBAction)like:(id)sender;
- (IBAction)more:(id)sender;
- (IBAction)comment:(id)sender;

@end

@implementation VNProfileVideoTableViewCell

- (void)awakeFromNib
{
    self.bgView.layer.cornerRadius = 5.0;
    self.bgView.layer.masksToBounds = YES;
    self.moviePlayer = [[MPMoviePlayerController alloc] init];
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    [self.moviePlayer.view setFrame:self.videoImgView.frame];
    self.moviePlayer.shouldAutoplay = NO;
    [self.moviePlayer.view setBackgroundColor:[UIColor clearColor]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFinishedPlayCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [self.bgView addSubview:self.moviePlayer.view];
    
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.frame = CGRectMake(0, 0, 100.0, 100.0);
    self.playBtn.center = self.videoImgView.center;
    [self.bgView addSubview:self.playBtn];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)playVideo {
    NSLog(@"PlayMovieAction====");
    if (self.moviePlayer) {
        self.moviePlayer.view.hidden = NO;
        self.videoImgView.hidden = YES;
        //[self.moviePlayer play];
        [self playAndCount];
        [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.playBtn addTarget:self action:@selector(pauseVideo) forControlEvents:UIControlEventTouchUpInside];
        self.isPlaying = YES;
    }
}

-(void)playAndCount
{
    [self.moviePlayer play];
    [MobClick event:@"video_play" label:@"porfile"];
}

- (void)pauseVideo {
    if (self.moviePlayer) {
        [self.moviePlayer pause];
        [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        self.isPlaying = NO;
    }
}

-(void)videoFinishedPlayCallback:(NSNotification*)notify {
    self.moviePlayer.view.hidden = YES;
    self.videoImgView.hidden = NO;
    [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    self.isPlaying = NO;
    NSLog(@"视频播放完成");
}

- (void)reload {
    if (self.news) {
        
        [self.videoImgView setImageWithURL:[NSURL URLWithString:self.news.imgMdeia.url] placeholderImage:[UIImage imageNamed:@"600-600pic"]];
        
        NSLog(@"%@", self.news.title);
        self.titleLabel.text = self.news.title;
        NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:17.0]};
        CGRect rect = [self.news.title boundingRectWithSize:CGSizeMake(280.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        self.titleLabelHeightLC.constant = CGRectGetHeight(rect);
        
        self.timeLabel.text = self.news.date;
        self.commentNumLabel.text = [NSString stringWithFormat:@"%d", self.news.comment_count];
        self.favouriteLabel.text = [NSString stringWithFormat:@"%d", self.news.like_count];
        
        //视频URL
        NSLog(@"%@", self.news.videoMedia.url);
        NSURL *url = [NSURL URLWithString:self.news.videoMedia.url];
//        NSURL *url = [NSURL URLWithString:@"http://cloud.video.taobao.com//play/u/320975160/p/1/e/2/t/1/12378629.M3u8"];
        self.moviePlayer.contentURL = url;
    }
}

- (void)startOrPausePlaying:(BOOL)toPlay {
    if (!toPlay) {
        if (self.moviePlayer && self.isPlaying) {
            [self.moviePlayer pause];
            [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
            self.isPlaying = NO;
        }
    }
    else {
        if (self.moviePlayer && !self.isPlaying) {
            if (self.moviePlayer.view.hidden) {
                self.moviePlayer.view.hidden = NO;
                self.videoImgView.hidden = YES;
            }
            //[self.moviePlayer play];
            [self playAndCount];
            [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.playBtn addTarget:self action:@selector(pauseVideo) forControlEvents:UIControlEventTouchUpInside];
            self.isPlaying = YES;
        }
    }
}

- (IBAction)like:(id)sender {
    if (self.likeHandler) {
        self.likeHandler();
    }
}

- (IBAction)more:(id)sender {
    if (self.moreHandler) {
        self.moreHandler();
    }
}

- (IBAction)comment:(id)sender {
    if (self.commentHandler) {
        self.commentHandler();
    }
}
@end
