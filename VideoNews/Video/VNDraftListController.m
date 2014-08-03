//
//  VNDraftListController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-23.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNDraftListController.h"
#import "VNVideoDraftTableViewCell.h"
#import <AVFoundation/AVFoundation.h>
#import "VNVideoShareViewController.h"
#import "VNAVPlayerPlayView.h"

@interface VNDraftListController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *dataSourceArr;

@property (nonatomic, strong) UITableView *draftListTableView;

@property (nonatomic, strong) VNAVPlayerPlayView *videoPlayView;     //播放视频的view
@property (nonatomic ,strong) AVPlayer *videoPlayer;                  //播放视频player
@property (nonatomic, strong) AVPlayerItem *videoPlayerItem;


@end

@implementation VNDraftListController

#pragma mark - ViewLifeCycle

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#define screenH ([[UIScreen mainScreen] bounds].size.height)

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *filePath = [VNUtility getNSCachePath:@"VideoFiles/Draft"];
    
    _dataSourceArr = [NSMutableArray arrayWithCapacity:1];
    
    BOOL _isDir;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&_isDir]){
        if (![[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil]) {
            
        }
    }

    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    
    if (arr && arr.count > 0) {
        [_dataSourceArr addObjectsFromArray:arr];
    }
    
    //initialize top bar view.
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    topView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 44)];
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(doDismiss) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:backBtn];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 44)];
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = @"草稿";
    titleLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
    [topView addSubview:titleLbl];
    
    [self.view addSubview:topView];
    
    __weak VNDraftListController *weakSelf = self;
    
    dispatch_after(0.3, dispatch_get_main_queue(), ^{
        weakSelf.draftListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, 320, self.view.frame.size.height - 64) style:UITableViewStylePlain];
        weakSelf.draftListTableView.delegate = self;
        weakSelf.draftListTableView.dataSource = self;
        weakSelf.draftListTableView.separatorInset = UIEdgeInsetsZero;
        weakSelf.draftListTableView.backgroundColor = [UIColor colorWithRGBValue:0xE1E1E1];
        [weakSelf.view addSubview:weakSelf.draftListTableView];
    });
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDraftList:) name:@"RefreshDraftListNotification" object:nil];
    
    _videoPlayView = [[VNAVPlayerPlayView alloc] initWithFrame:CGRectMake(0, 0, 320, screenH)];
    _videoPlayView.backgroundColor = [UIColor lightGrayColor];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.delegate = self;
    [_videoPlayView addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    
}

#pragma mark - SelfMethods

- (void)doDismiss
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshDraftListNotification" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//- (void)refreshDraftList:(NSNotification *)not
//{
//    [_dataSourceArr removeAllObjects];
//    NSString *filePath = [VNUtility getNSCachePath:@"VideoFiles/Draft"];
//
//    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
//    
//    if (arr && arr.count > 0) {
//        [_dataSourceArr addObjectsFromArray:arr];
//    }
//    
//    [self.draftListTableView reloadData];
//}

#pragma mark - UITableViewDataSource && Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSourceArr.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VNVideoDraftTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"draft"];
    
    if (cell == nil) {
        cell = [[VNVideoDraftTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"draft"];
    }
    
    NSString *timeIntervalStr = [self.dataSourceArr objectAtIndex:indexPath.row];
    NSString *filePath = [VNUtility getNSCachePath:[NSString stringWithFormat:@"VideoFiles/Draft/%@",timeIntervalStr]];
    NSString *coverPath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",timeIntervalStr]];
    
    UIImage *img = [UIImage imageWithContentsOfFile:coverPath];
    
    double time = [[self.dataSourceArr objectAtIndex:indexPath.row] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:time];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
    NSString *currentDateStr = [dateFormatter stringFromDate:date];
    
    [cell setDisplayImage:img timeLabelText:currentDateStr];
    
    __weak VNDraftListController *weakSelf = self;
    
    [cell setShareHandlerBlock:^{
        NSString *filePath = [VNUtility getNSCachePath:[NSString stringWithFormat:@"VideoFiles/Draft/%@",timeIntervalStr]];
        NSString *videoFilePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",timeIntervalStr]];
        NSString *coverTimeFilePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",timeIntervalStr]];
        NSString *coverTimeStr = [NSString stringWithContentsOfFile:coverTimeFilePath encoding:NSUTF8StringEncoding error:nil];
        
        VNVideoShareViewController *shareCtl = [[VNVideoShareViewController alloc] initWithVideoPath:videoFilePath andCoverImage:img];
        shareCtl.fromDraft = YES;
        shareCtl.coverTime = [coverTimeStr floatValue];
        [weakSelf.navigationController pushViewController:shareCtl animated:YES];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //show video
    NSString *timeIntervalStr = [self.dataSourceArr objectAtIndex:indexPath.row];
    NSString *filePath = [VNUtility getNSCachePath:[NSString stringWithFormat:@"VideoFiles/Draft/%@",timeIntervalStr]];
    NSString *videoFilePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",timeIntervalStr]];
    NSURL *videoUrl = [NSURL fileURLWithPath:videoFilePath];
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    
    self.videoPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_videoPlayerItem];
    
    self.videoPlayer = [AVPlayer playerWithPlayerItem:_videoPlayerItem];
    [self.videoPlayer addObserver:self forKeyPath:@"status" options:0 context:@"AVPlayerDemoPlaybackViewControllerStatusObservationContext"];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

//commit deleting.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *timeIntervalStr = [self.dataSourceArr objectAtIndex:indexPath.row];
    NSString *filePath = [VNUtility getNSCachePath:[NSString stringWithFormat:@"VideoFiles/Draft/%@",timeIntervalStr]];
    
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&err];
    
    if (!err) {
        [self.dataSourceArr removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除失败" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - VideoPlayRelated

/**
 *  @description: handle tap gesture for avplayer (close it)
 *
 *  @param gest ,input UITapGestureRecognizer
 */
- (void)handleTap:(UITapGestureRecognizer *)gest
{
    if (_videoPlayView.superview) {
        [_videoPlayer pause];
        
        [self.videoPlayer removeObserver:self forKeyPath:@"status" context:@"AVPlayerDemoPlaybackViewControllerStatusObservationContext"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_videoPlayerItem];
        
        [_videoPlayView removeFromSuperview];
    }
}

/**
 *  @description :observe for player start.
 *  @param path
 *  @param object
 *  @param change
 *  @param context
 */
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (_videoPlayer.status == AVPlayerStatusReadyToPlay) {
        
        [self.view addSubview:self.videoPlayView];
        [(AVPlayerLayer *)[self.videoPlayView layer] setPlayer:_videoPlayer];
        [_videoPlayer play];
    }
}

/**
 *  @description:observe for player stop, replay.

 *
 *  @param playerItem
 */
- (void)playerItemDidReachEnd:(AVPlayerItem *)playerItem
{
    [_videoPlayer seekToTime:kCMTimeZero];
    [_videoPlayer play];
}


@end
