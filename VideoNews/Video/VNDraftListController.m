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

@interface VNDraftListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *dataSourceArr;

@property (nonatomic, strong) UITableView *draftListTableView;

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
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 45, 44)];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDraftList:) name:@"RefreshDraftListNotification" object:nil];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshDraftListNotification" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)refreshDraftList:(NSNotification *)not
{
    [_dataSourceArr removeAllObjects];
    NSString *filePath = [VNUtility getNSCachePath:@"VideoFiles/Draft"];

    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    
    if (arr && arr.count > 0) {
        [_dataSourceArr addObjectsFromArray:arr];
    }
    
    [self.draftListTableView reloadData];
}

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
    
    NSString *filePath = [VNUtility getNSCachePath:@"VideoFiles/DraftCover"];
    NSString *coverPath = [[filePath stringByAppendingPathComponent:[self.dataSourceArr objectAtIndex:indexPath.row]] stringByReplacingOccurrencesOfString:@".mp4" withString:@".jpg"];
    
    UIImage *img = [UIImage imageWithContentsOfFile:coverPath];
    
    double time = [[[self.dataSourceArr objectAtIndex:indexPath.row] stringByReplacingOccurrencesOfString:@".mov" withString:@""] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:time];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
    NSString *currentDateStr = [dateFormatter stringFromDate:date];
    
    [cell setDisplayImage:img timeLabelText:currentDateStr];
    
    __weak VNDraftListController *weakSelf = self;
    
    [cell setShareHandlerBlock:^{
        NSString *filePath = [VNUtility getNSCachePath:@"VideoFiles/Draft"];
        NSString *fileNamePath = [filePath stringByAppendingPathComponent:[weakSelf.dataSourceArr objectAtIndex:indexPath.row]];
        
        VNVideoShareViewController *shareCtl = [[VNVideoShareViewController alloc] initWithVideoPath:fileNamePath andCoverImage:img];
        shareCtl.fromDraft = YES;
        [weakSelf.navigationController pushViewController:shareCtl animated:YES];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //show video
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *filePath = [VNUtility getNSCachePath:@"VideoFiles/Draft"];
    NSString *fileNamePath = [filePath stringByAppendingPathComponent:[self.dataSourceArr objectAtIndex:indexPath.row]];
    NSString *coverPath = [VNUtility getNSCachePath:@"VideoFiles/DraftCover"];
    NSString *coverImagePath = [[coverPath stringByAppendingPathComponent:[self.dataSourceArr objectAtIndex:indexPath.row]] stringByReplacingOccurrencesOfString:@".mp4" withString:@".jpg"];
    
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:fileNamePath error:&err];
    [[NSFileManager defaultManager] removeItemAtPath:coverImagePath error:nil];
    
    if (!err) {
        [self.dataSourceArr removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除失败" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
}

@end
