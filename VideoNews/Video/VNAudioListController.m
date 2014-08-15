//
//  VNMusicListController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-31.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNAudioListController.h"
#import <AVFoundation/AVFoundation.h>

#define CommonStatusColor   [UIColor colorWithRGBValue:0x606366]
#define SelectedStatusColor [UIColor colorWithRGBValue:0xCE2426]

@interface VNAudioListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *audioPathsArr;

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation VNAudioListController

@synthesize onSelectionAudioPath, delegate;

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

    //initialize top bar view.
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    topView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 44)];
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = @"选择音乐";
    titleLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
    [topView addSubview:titleLbl];
    
    UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(260, 20, 60, 44)];
    [submitBtn setImage:[UIImage imageNamed:@"audio_submit"] forState:UIControlStateNormal];
    [submitBtn setImage:[UIImage imageNamed:@"audio_submit"] forState:UIControlStateSelected];
    [submitBtn addTarget:self action:@selector(doSubmit) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:submitBtn];
    
    [self.view addSubview:topView];
    
    //local audio files path array
    NSArray *arr = [[NSBundle mainBundle] pathsForResourcesOfType:@"" inDirectory:@"Audios"];
    //NSLog(@"%@",arr);
    _audioPathsArr = [NSMutableArray arrayWithCapacity:1];
    [_audioPathsArr addObjectsFromArray:arr];
   // NSLog(@"%@",_audioPathsArr);
    
    //tableview display audio list.
    UITableView *audioListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, 320, self.view.frame.size.height - 64 - 40) style:UITableViewStyleGrouped];
    audioListTableView.backgroundColor = [UIColor whiteColor];
    audioListTableView.separatorInset = UIEdgeInsetsZero;
    audioListTableView.dataSource = self;
    audioListTableView.delegate = self;
    [self.view addSubview:audioListTableView];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 40, 320, 40)];
    footerView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
    
    UILabel *footerLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 220, 40)];
    footerLbl.backgroundColor = [UIColor clearColor];
    footerLbl.text = @"我的音乐";
    footerLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
    footerLbl.textAlignment = NSTextAlignmentCenter;
    footerLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
    [footerView addSubview:footerLbl];
    
    [self.view addSubview:footerView];
    
    NSInteger row, section;
    if (!self.onSelectionAudioPath || [self.onSelectionAudioPath isEqualToString:@""]) {
        row = 0;
        section = 0;
    }else {
        row = [_audioPathsArr indexOfObject:self.onSelectionAudioPath];
        if (row < 0) {
            row = 0, section = 0;
        }else {
            section = 1;
        }
    }
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:section];

    __weak VNAudioListController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UITableViewCell *cell = [audioListTableView cellForRowAtIndexPath:weakSelf.selectedIndexPath];
        UILabel *lbl = (UILabel *)[cell.contentView viewWithTag:9001];
        lbl.textColor = SelectedStatusColor;
        
        [audioListTableView scrollToRowAtIndexPath:weakSelf.selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    });
    
    
    
    if (section == 0) {
        
    }else {
        NSError *error;
        NSURL *audioFileUrl = [NSURL fileURLWithPath:self.onSelectionAudioPath];
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:&error];
        
        if (!audioFileUrl || error) {
            NSLog(@"音频读取出错了。。。");
        }else {
            [_audioPlayer play];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)dealloc
{

}

#pragma mark - UserInteractionMethods

/**
 *  @description: submit user selection.
 */
- (void)doSubmit
{
    if (self.selectedIndexPath.section == 0) {
        [self.delegate didSelectedAudioAtFilePath:nil];
    }else {
        if (self.audioPlayer) {
            [self.audioPlayer stop];
        }
        [self.delegate didSelectedAudioAtFilePath:[_audioPathsArr objectAtIndex:self.selectedIndexPath.row]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate&&DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }else {
        return _audioPathsArr.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 50;
    }else {
        return 45;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{

    if (section == 0) {
        return nil;
    }else {
        //section title
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 32)];
        headerView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
        UILabel *textLbl = [[UILabel alloc] initWithFrame:CGRectMake(23, 6, 100, 20)];
        textLbl.backgroundColor = [UIColor clearColor];
        textLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:12];
        textLbl.textColor = [UIColor colorWithRGBValue:0x606366];
        textLbl.text = @"自带音乐";
        [headerView addSubview:textLbl];
        return headerView;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0.001;
    }else{
        return 32.0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    if (indexPath.section == 0) {
        identifier = @"AudioNone";
    }else {
        identifier = @"AudioLocal";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(23, 10, 280, 25)];
        titleLbl.backgroundColor = [UIColor clearColor];
        
        if (indexPath.section == 0) {
            titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
        }else {
            titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:12];
        }
        titleLbl.textColor = CommonStatusColor;
        
        titleLbl.tag = 9001;
        
        [cell.contentView addSubview:titleLbl];
        
        if (indexPath.section == 0) {
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(280, 15, 20, 20)];
            imgView.backgroundColor = [UIColor clearColor];
            imgView.image = [UIImage imageNamed:@"audio_no"];
            [cell.contentView addSubview:imgView];
        }
    }
    
    NSString *fileName;
    if (indexPath.section == 0) {
        fileName = @"无音乐";
    }else {
        NSString *audioPath = [_audioPathsArr objectAtIndex:indexPath.row];
        
        fileName = [[audioPath lastPathComponent] stringByDeletingPathExtension];
    }
   
    UILabel *titleLbl = (UILabel *)[cell.contentView viewWithTag:9001];
    
    titleLbl.text = fileName;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *lastCell = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
    UILabel *lastTitleLbl = (UILabel *)[lastCell.contentView viewWithTag:9001];
    lastTitleLbl.textColor = CommonStatusColor;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *titleLbl = (UILabel *)[cell.contentView viewWithTag:9001];
    titleLbl.textColor = SelectedStatusColor;
    
    self.selectedIndexPath = indexPath;
    
    if (indexPath.section == 0) {
        if (self.audioPlayer) {
            [self.audioPlayer stop];
        }
    }else {
        NSError *error;
        NSURL *audioFileUrl = [NSURL fileURLWithPath:[_audioPathsArr objectAtIndex:indexPath.row]];
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileUrl error:&error];
        
        if (!audioFileUrl || error) {
            NSLog(@"音频读取出错了。。。");
        }else {
            [_audioPlayer play];
        }
    }
}

@end
