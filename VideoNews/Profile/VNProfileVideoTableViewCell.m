//
//  VNProfileVideoTableViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProfileVideoTableViewCell.h"

#import "GPLoadingButton.h"

@interface VNProfileVideoTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *videoImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentNumLabel;

@property (strong, nonatomic) UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (strong, nonatomic)GPLoadingButton *loadingAni;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeightLC;

- (IBAction)like:(id)sender;
- (IBAction)more:(id)sender;
- (IBAction)comment:(id)sender;

@end

@implementation VNProfileVideoTableViewCell

- (void)awakeFromNib {
    if (!self.moviePlayer) {
        self.bgView.layer.cornerRadius = 5.0;
        self.bgView.layer.masksToBounds = YES;
        self.moviePlayer = [[MPMoviePlayerController alloc] init];
        self.moviePlayer.controlStyle = MPMovieControlStyleNone;
        self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
        [self.moviePlayer.view setFrame:self.videoImgView.frame];
        [self.moviePlayer.view setBackgroundColor:[UIColor clearColor]];
        //[self.moviePlayer prepareToPlay];这个函数会让播放器自动播放
        self.moviePlayer.shouldAutoplay=NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFinishedPlayCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MoviePlayerLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MoviePlayerPlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];
        [self.bgView addSubview:self.moviePlayer.view];
        self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playBtn.frame = CGRectMake(0, 0, 300.0, 300.0);
        self.playBtn.center = self.videoImgView.center;
        [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        self.isPlaying = NO;
        NSLog(@"awakeFromNib");
        [self.bgView addSubview:self.playBtn];
        if (!_loadingAni) {
            _loadingAni = [[GPLoadingButton alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
            _loadingAni.center=_videoImgView.center;
            //_loadingAni.rotatorColor = [UIColor colorWithRGBValue:0xCE2426];
            _loadingAni.rotatorColor = [UIColor whiteColor];
            [self.bgView addSubview:_loadingAni];
            
        }
    }
    else
    {
        [_moviePlayer stop];
        
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)playVideo {
    NSLog(@"PlayMovieAction====");
    if (self.moviePlayer) {
        [_loadingAni startActivity];
       // self.moviePlayer.view.hidden = NO;
       //self.videoImgView.hidden = YES;
        [self playAndCount];
        [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.playBtn addTarget:self action:@selector(pauseVideo) forControlEvents:UIControlEventTouchUpInside];
        self.isPlaying = YES;
        NSLog(@"s:playVideo");
    }
}

-(void)playAndCount
{
    
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
    //[MobClick event:@"video_play" label:@"porfile"];
}

- (void)pauseVideo {
    if (self.moviePlayer) {
        [self.moviePlayer pause];
        [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        self.isPlaying = NO;
        NSLog(@"pauseVideo");
    }
}

-(void)videoFinishedPlayCallback:(NSNotification*)notify {
    self.moviePlayer.view.hidden = YES;
    self.videoImgView.hidden = NO;
    [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    self.isPlaying = NO;
    [self.moviePlayer stop];
    //self.moviePlayer=nil;
    NSLog(@"videoFinishedPlayCallback");
    NSLog(@"视频播放完成");
    [_loadingAni stopActivity];
}

- (void)reload {
    if (self.news) {
        self.videoImgView.hidden=NO;
        [self.videoImgView setImageWithURL:[NSURL URLWithString:self.news.imgMdeia.url] placeholderImage:[UIImage imageNamed:@"600-600pic"]];
        [self.moviePlayer stop];
        self.moviePlayer.view.hidden=YES;
        [_loadingAni stopActivity];
        //视频URL
    //    NSLog(@"%@", self.news.videoMedia.url);
        NSURL *url = [NSURL URLWithString:self.news.videoMedia.url];
        self.moviePlayer.movieSourceType = MPMovieSourceTypeUnknown;
        self.moviePlayer.contentURL = url;
        self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
        //[self.moviePlayer prepareToPlay];
        self.moviePlayer.shouldAutoplay = NO;
        
       // NSLog(@"%@", self.news.title);
        self.titleLabel.text = self.news.title;
        NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:17.0]};
        CGRect rect = [self.news.title boundingRectWithSize:CGSizeMake(280.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        self.titleLabelHeightLC.constant = CGRectGetHeight(rect);
        
        self.timeLabel.text=[NSString stringWithFormat:@"上传于 %@",[VNUtility timeFormatToDisplay:[self.news.timestamp doubleValue]]];

        self.commentNumLabel.text =[VNUtility countFormatToDisplay:self.news.comment_count];
        //[NSString stringWithFormat:@"%d", self.news.comment_count];
        self.favouriteLabel.text =[VNUtility countFormatToDisplay:self.news.like_count];
        //[NSString stringWithFormat:@"%d", self.news.like_count];
        if (self.isFavouriteNews) {
            [self.likeImg setImage:[UIImage imageNamed:@"30-30heart_a"]];
        }
        else
        {
             [self.likeImg setImage:[UIImage imageNamed:@"30-30heart"]];
        }
    }
}

- (void)startOrPausePlaying:(BOOL)toPlay {
    if (!toPlay) {
        if (self.moviePlayer && self.isPlaying) {
            [_loadingAni stopActivity];
            [self.moviePlayer pause];
            [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
            self.isPlaying = NO;
            NSLog(@"startOrPausePlaying");
        }
    }
    else {
        if (self.moviePlayer && !self.isPlaying) {
//            if (self.moviePlayer.view.hidden) {
//                self.moviePlayer.view.hidden = NO;
//                self.videoImgView.hidden = YES;
//            }
            [_loadingAni startActivity];
            //self.videoImgView.hidden = YES;
            NSLog(@"PlayMovieAction====");
            [self playAndCount];
            [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.playBtn addTarget:self action:@selector(pauseVideo) forControlEvents:UIControlEventTouchUpInside];
            self.isPlaying = YES;
            NSLog(@"s:startOrPausePlaying");
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

- (void)likeStatus:(BOOL)liked {
    if (liked) {
        [self.likeImg setImage:[UIImage imageNamed:@"30-30heart_a"]];
    }
    else {
        [self.likeImg setImage:[UIImage imageNamed:@"30-30heart"]];
    }
}

//然后在下面的函数里处理
- (void) MoviePlayerLoadStateDidChange:(NSNotification*)notification
{
    
    //MPMoviePlayerController *player = notification.object;
    if(_moviePlayer.loadState ==MPMovieLoadStateUnknown){
        //[_loadingAni startActivity];
    }
    else if(_moviePlayer.loadState == MPMovieLoadStatePlayable){
    //第一次加载，或者前后拖动完成之后 /
        [_loadingAni stopActivity];
     //   [self playAndCount];
    }
    else if(_moviePlayer.loadState == MPMovieLoadStatePlaythroughOK){
        [_loadingAni stopActivity];
    }
    else if(_moviePlayer.loadState == MPMovieLoadStateStalled){
    //网络不好，开始缓冲了
        [_loadingAni startActivity];
    }
    
}

-(void)MoviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    if (self.moviePlayer.playbackState==MPMoviePlaybackStatePlaying) {
        [_loadingAni stopActivity];
        self.isPlaying=YES;
        _moviePlayer.view.hidden=NO;
        NSLog(@"s:MoviePlayerPlaybackStateDidChange");
        NSLog(@"%@",self.titleLabel.text);
    }
    else if (self.moviePlayer.playbackState==MPMoviePlaybackStatePaused) {
        [_loadingAni stopActivity];
    }
    else if (self.moviePlayer.playbackState==MPMoviePlaybackStateInterrupted)
    {
        [_loadingAni startActivity];
    }
    else if (self.moviePlayer.playbackState==MPMoviePlaybackStateStopped)
    {
        [_loadingAni stopActivity];
    }
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];
}

//http://blog.sina.com.cn/s/blog_8364f64b0100t0nn.html

@end
