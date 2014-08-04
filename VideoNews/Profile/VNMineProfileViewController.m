//
//  VNMineProfileViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNMineProfileViewController.h"
#import "VNProfileVideoTableViewCell.h"
#import "SVPullToRefresh.h"
#import "VNMineProfileHeaderView.h"
#import "VNProfileFansTableViewCell.h"
#import "VNNewsDetailViewController.h"
#import "UMSocial.h"
#import "VNLoginViewController.h"
#import "VNProfileViewController.h"
#import "VNOriginImgViewController.h"
#import "VNEditProfileViewController.h"
#import "VNSettingViewController.h"
#import "VNUploadManager.h"
#import "VNUploadVideoProgressView.h"

@interface VNMineProfileViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UMSocialUIDelegate, UIAlertViewDelegate, VNUploadManagerDelegate> {
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
    BOOL isTabBarHidden;
    
    BOOL isAutoPlayOption;
}

@property (weak, nonatomic) IBOutlet UITableView *videoTableView;
@property (weak, nonatomic) IBOutlet UITableView *favouriteTableView;
@property (weak, nonatomic) IBOutlet UITableView *followTableView;
@property (weak, nonatomic) IBOutlet UITableView *fansTableView;
@property (weak, nonatomic) IBOutlet UIButton *popBtn;

@property (strong, nonatomic) NSMutableArray *mineVideoArr;
@property (strong, nonatomic) NSMutableArray *favVideoArr;
@property (strong, nonatomic) NSMutableArray *followArr;
@property (strong, nonatomic) NSMutableArray *fansArr;
//为了检测用户与其他user的关系
@property (strong, nonatomic) NSMutableArray *idolListArr;
@property (strong, nonatomic) VNUser *mineInfo;
@property (strong, nonatomic) NSString *followLastPageTime;
@property (strong, nonatomic) NSString *fansLastPageTime;
@property (strong, nonatomic) NSMutableArray *favouriteNewsArr;
@property (strong, nonatomic) UIAlertView *deleteAlert;

@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *user_token;
@property (strong, nonatomic) VNNews *shareNews;
@property (strong, nonatomic) NSIndexPath *shareNewsIndexPath;
@property (strong, nonatomic) NSArray *headerViewArr;

@property (nonatomic, strong) NSDictionary *uploadVideoInfo;    //上传video信息
@property (nonatomic, strong) VNUploadVideoProgressView *progressView;   //进度条
- (IBAction)setting:(id)sender;
- (IBAction)pop:(id)sender;

@end

static BOOL firstLoading = YES;
static NSString *shareStr;

@implementation VNMineProfileViewController

- (VNUploadVideoProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[VNUploadVideoProgressView alloc] initWithFrame:CGRectMake(0, 64, 320, 20)];
    }
    return _progressView;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _mineVideoArr = [NSMutableArray array];
        _favVideoArr = [NSMutableArray array];
        _followArr = [NSMutableArray array];
        _fansArr = [NSMutableArray array];
        _idolListArr = [NSMutableArray array];
        _favouriteNewsArr=[NSMutableArray array];
        _followLastPageTime = nil;
        _fansLastPageTime = nil;
        _shareNews = nil;
        _shareNewsIndexPath=nil;
        _uid = nil;
        _user_token = nil;
        _isPush = NO;
        isTabBarHidden = NO;
        
        isAutoPlayOption = [[[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay] boolValue];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.headerViewArr.count) {
        if ([VNHTTPRequestManager isReachable]) {
            [VNHTTPRequestManager userInfoForUser:self.uid completion:^(VNUser *userInfo, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (userInfo) {
                    self.mineInfo = userInfo;
                    for (VNMineProfileHeaderView *headerView in self.headerViewArr) {
                        headerView.userInfo = userInfo;
                        [headerView reload];
                    }
                }
            }];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.videoTableView.hidden) {
        for (VNProfileVideoTableViewCell *cell in [self.videoTableView visibleCells]) {
            if (cell.isPlaying) {
                [cell startOrPausePlaying:NO];
            }
        }
    }
    if (!self.favouriteTableView.hidden) {
        for (VNProfileVideoTableViewCell *cell in [self.favouriteTableView visibleCells]) {
            if (cell.isPlaying) {
                [cell startOrPausePlaying:NO];
            }
        }
    }
    if (isTabBarHidden) {
        [self showTabBar];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.popBtn setHitTestEdgeInsets:UIEdgeInsetsMake(-10.0, -10.0, -10.0, -10.0)];
    if (self.isPush) {
        self.popBtn.hidden = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeVideoCellForNewsDeleted:) name:VNMineProfileVideoCellDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeFavouriteCellForNewsDeleted:) name:VNMineProfileFavouriteCellDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadVideoFile:) name:VNMineProfileUploadVideoNotifiction object:nil];

    [self reload];
    
    [self.view addSubview:self.progressView];

}

- (void)reload {
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        self.uid = [userInfo objectForKey:@"openid"];
        self.user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    }
    
    if (self.uid && self.user_token) {
        [VNHTTPRequestManager favouriteNewsListFor:self.uid userToken:_user_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            if (favouriteNewsArr.count) {
                NSLog(@"%@", favouriteNewsArr);
                [self.favouriteNewsArr removeAllObjects];
                [self.favouriteNewsArr addObjectsFromArray:favouriteNewsArr];
            }
        }];

        VNMineProfileHeaderView *videoHeaderView = loadXib(@"VNMineProfileHeaderView");
        VNMineProfileHeaderView *favHeaderView = loadXib(@"VNMineProfileHeaderView");
        VNMineProfileHeaderView *followHeaderView = loadXib(@"VNMineProfileHeaderView");
        VNMineProfileHeaderView *fansHeaderView = loadXib(@"VNMineProfileHeaderView");
        self.headerViewArr = @[videoHeaderView, favHeaderView, followHeaderView, fansHeaderView];
        if ([VNHTTPRequestManager isReachable]) {
            [VNHTTPRequestManager userInfoForUser:self.uid completion:^(VNUser *userInfo, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (userInfo) {
                    self.mineInfo = userInfo;
                    videoHeaderView.userInfo = userInfo;
                    [videoHeaderView reload];
                    
                    favHeaderView.userInfo = userInfo;
                    [favHeaderView reload];
                    
                    followHeaderView.userInfo = userInfo;
                    [followHeaderView reload];
                    
                    fansHeaderView.userInfo = userInfo;
                    [fansHeaderView reload];
                }
            }];
        }
        else {
            NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNProfileInfo];
            VNUser *user = [[VNUser alloc] initWithDict:userInfo];
            self.mineInfo = user;
            videoHeaderView.userInfo = user;
            [videoHeaderView reload];
            
            favHeaderView.userInfo = user;
            [favHeaderView reload];
            
            followHeaderView.userInfo = user;
            [followHeaderView reload];
            
            fansHeaderView.userInfo = user;
            [fansHeaderView reload];
        }
        
        __weak typeof(self) weakSelf = self;
        
        videoHeaderView.editHandler = ^(){
            VNEditProfileViewController *editProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNEditProfileViewController"];
            editProfileViewController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:editProfileViewController animated:YES];
        };
        
        videoHeaderView.tabHandler = ^(NSUInteger index){
            for (VNProfileVideoTableViewCell *cell in [weakSelf.videoTableView visibleCells]) {
                if (cell.isPlaying) {
                    [cell startOrPausePlaying:NO];
                }
            }
            for (VNProfileVideoTableViewCell *cell in [weakSelf.favouriteTableView visibleCells]) {
                if (cell.isPlaying) {
                    [cell startOrPausePlaying:NO];
                }
            }
            switch (index) {
                case 0: {
                    firstLoading = YES;
                    weakSelf.videoTableView.hidden = NO;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = YES;
                    [weakSelf.videoTableView triggerPullToRefresh];
                }
                    break;
                case 1: {
                    firstLoading = YES;
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = NO;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = YES;
                    [weakSelf.favouriteTableView triggerPullToRefresh];
                }
                    break;
                case 2: {
                    firstLoading = YES;
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = NO;
                    weakSelf.fansTableView.hidden = YES;
                    [weakSelf.followTableView triggerPullToRefresh];
                }
                    break;
                case 3: {
                    firstLoading = YES;
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = NO;
                    [weakSelf.fansTableView triggerPullToRefresh];
                }
                    break;
                case 11: {
                    if (self.mineInfo.avatar) {
                        VNOriginImgViewController *originImgViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNOriginImgViewController"];
                        originImgViewController.imgURL = self.mineInfo.avatar;
                        originImgViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                        [self presentViewController:originImgViewController animated:YES completion:nil];
                    }
                    return ;
                }
            }
        };
        favHeaderView.editHandler = videoHeaderView.editHandler;
        favHeaderView.tabHandler = videoHeaderView.tabHandler;
        followHeaderView.editHandler = videoHeaderView.editHandler;
        followHeaderView.tabHandler = videoHeaderView.tabHandler;
        fansHeaderView.editHandler = videoHeaderView.editHandler;
        fansHeaderView.tabHandler = videoHeaderView.tabHandler;
        
        //我的视频
        self.videoTableView.tableHeaderView = videoHeaderView;
        [self.videoTableView registerNib:[UINib nibWithNibName:@"VNProfileVideoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileVideoTableViewCellIdentifier"];
        
        [self.videoTableView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager videoListForUser:self.uid type:@"video" fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        [weakSelf.mineVideoArr removeAllObjects];
                        [weakSelf.mineVideoArr addObjectsFromArray:videoArr];
                        [weakSelf.videoTableView reloadData];
                    }
                    firstLoading = YES;
                    [weakSelf.videoTableView.pullToRefreshView stopAnimating];
                }];
            });
        }];
        
        [self.videoTableView addInfiniteScrollingWithActionHandler:^{
            NSString *moreTimeStamp = nil;
            if (weakSelf.mineVideoArr.count) {
                VNNews *lastNews = [weakSelf.mineVideoArr lastObject];
                moreTimeStamp = lastNews.timestamp;
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
            
            [VNHTTPRequestManager videoListForUser:self.uid type:@"video" fromTime:moreTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    [weakSelf.mineVideoArr addObjectsFromArray:videoArr];
                    [weakSelf.videoTableView reloadData];
                }
                [weakSelf.videoTableView.infiniteScrollingView stopAnimating];
            }];
        }];
        [self.videoTableView triggerPullToRefresh];
        
        //我的收藏
        self.favouriteTableView.tableHeaderView = favHeaderView;
        [self.favouriteTableView registerNib:[UINib nibWithNibName:@"VNProfileVideoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileFavTableViewCellIdentifier"];
        
        [self.favouriteTableView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager favVideoListForUser:self.uid userToken:self.user_token fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        [weakSelf.favVideoArr removeAllObjects];
                        [weakSelf.favVideoArr addObjectsFromArray:videoArr];
                        [weakSelf.favouriteTableView reloadData];
                    }
                    firstLoading = YES;
                    [weakSelf.favouriteTableView.pullToRefreshView stopAnimating];
                }];
            });
        }];
        
        [self.favouriteTableView addInfiniteScrollingWithActionHandler:^{
            NSString *moreTimeStamp = nil;
            if (weakSelf.favVideoArr.count) {
                VNNews *lastNews = [weakSelf.favVideoArr lastObject];
                moreTimeStamp = lastNews.timestamp;
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
            
            [VNHTTPRequestManager favVideoListForUser:self.uid userToken:self.user_token fromTime:moreTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    [weakSelf.favVideoArr addObjectsFromArray:videoArr];
                    [weakSelf.favouriteTableView reloadData];
                }
                [weakSelf.favouriteTableView.infiniteScrollingView stopAnimating];
                
            }];
        }];
        
        //我的关注
        self.followTableView.tableHeaderView = followHeaderView;
        [self.followTableView registerNib:[UINib nibWithNibName:@"VNProfileFansTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileFollowTableViewCellIdentifier"];
        
        [self.followTableView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager userListForUser:self.uid type:@"idols" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        for (VNUser *user in userArr) {
                            user.isMineIdol = YES;
                        }
                        [weakSelf.followArr removeAllObjects];
                        [weakSelf.followArr addObjectsFromArray:userArr];
                        if (lastTimeStamp) {
                            weakSelf.followLastPageTime = lastTimeStamp;
                        }
                        [weakSelf.followTableView reloadData];
                    }
                    [weakSelf.followTableView.pullToRefreshView stopAnimating];
                }];
            });
        }];
        
        [self.followTableView addInfiniteScrollingWithActionHandler:^{
            NSString *moreTimeStamp = nil;
            if (self.followLastPageTime) {
                moreTimeStamp = self.followLastPageTime;
                NSLog(@"%@", moreTimeStamp);
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
            
            [VNHTTPRequestManager userListForUser:self.uid type:@"idols" pageTime:moreTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    for (VNUser *user in userArr) {
                        user.isMineIdol = YES;
                    }
                    [weakSelf.followArr addObjectsFromArray:userArr];
                    if (lastTimeStamp) {
                        weakSelf.followLastPageTime = lastTimeStamp;
                    }
                    [weakSelf.followTableView reloadData];
                }
                [weakSelf.followTableView.infiniteScrollingView stopAnimating];
            }];
        }];
        
        //我的粉丝
        self.fansTableView.tableHeaderView = fansHeaderView;
        [self.fansTableView registerNib:[UINib nibWithNibName:@"VNProfileFansTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileFansTableViewCellIdentifier"];
        
        [self.fansTableView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [VNHTTPRequestManager idolListForUser:self.uid userToken:self.user_token completion:^(NSArray *idolArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (idolArr.count) {
                        [self.idolListArr removeAllObjects];
                        [self.idolListArr addObjectsFromArray:idolArr];
                    }
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    [VNHTTPRequestManager userListForUser:self.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else {
                            if (self.idolListArr.count) {
                                for (VNUser *user in userArr) {
                                    if ([self.idolListArr containsObject:user.uid]) {
                                        user.isMineIdol = YES;
                                    }
                                    else {
                                        user.isMineIdol = NO;
                                    }
                                }
                            }
                            [weakSelf.fansArr removeAllObjects];
                            [weakSelf.fansArr addObjectsFromArray:userArr];
                            if (lastTimeStamp) {
                                weakSelf.fansLastPageTime = lastTimeStamp;
                            }
                            [weakSelf.fansTableView reloadData];
                        }
                        [weakSelf.fansTableView.pullToRefreshView stopAnimating];
                    }];
                }];
            });
        }];
        
        [self.fansTableView addInfiniteScrollingWithActionHandler:^{
            NSString *moreTimeStamp = nil;
            if (weakSelf.fansLastPageTime ) {
                moreTimeStamp = weakSelf.fansLastPageTime ;
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
            
            [VNHTTPRequestManager userListForUser:self.uid type:@"fans" pageTime:moreTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    if (self.idolListArr.count) {
                        for (VNUser *user in userArr) {
                            if ([self.idolListArr containsObject:user.uid]) {
                                user.isMineIdol = YES;
                            }
                            else {
                                user.isMineIdol = NO;
                            }
                        }
                    }
                    [weakSelf.fansArr addObjectsFromArray:userArr];
                    if (lastTimeStamp) {
                        weakSelf.fansLastPageTime = lastTimeStamp;
                    }
                    [weakSelf.fansTableView reloadData];
                }
                [weakSelf.fansTableView.infiniteScrollingView stopAnimating];
            }];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VNMineProfileFavouriteCellDeleteNotification object:nil];
   
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VNMineProfileVideoCellDeleteNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VNMineProfileUploadVideoNotifiction object:nil];
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
- (void)removeVideoCellForNewsDeleted:(NSNotification *)notification {
    //int newsNid = [notification.object integerValue];
    //NSLog(@"%d",[notification.object integerValue]);
    NSIndexPath *index=notification.object;
    [_mineVideoArr removeObjectAtIndex:index.row];
    [_videoTableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationLeft];
    //[_videoTableView deleteCellAtIndexPath:notification.object];
    [_videoTableView reloadData];
}

- (void)removeFavouriteCellForNewsDeleted:(NSNotification *)notification {
    //int newsNid = [notification.object integerValue];
    //NSLog(@"%d",[notification.object integerValue]);
    NSIndexPath *index=notification.object;
    //NSLog(@"%d",index.row);
    [_favVideoArr removeObjectAtIndex:index.row];
    [_favouriteTableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationLeft];
    //[_videoTableView deleteCellAtIndexPath:notification.object];
    [_favouriteTableView reloadData];
}

- (void)uploadVideoFile:(NSNotification *)not
{
    
    self.uploadVideoInfo = not.userInfo;
    
    VNUploadManager *uploadManager=[VNUploadManager sharedInstance];
    uploadManager.delegate = self;
    
    NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    
    [self.progressView show];
    
    NSString *videoPath = [self.uploadVideoInfo valueForKey:@"videoPath"];
    NSString *titleString = [self.uploadVideoInfo valueForKey:@"title"];
    NSString *tagsString = [self.uploadVideoInfo valueForKey:@"tags"];
    CGFloat coverTime = [[self.uploadVideoInfo valueForKey:@"coverTime"] floatValue];
    
    NSData *videoData = [NSData dataWithContentsOfFile:videoPath];
    
    __weak VNMineProfileViewController *weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [uploadManager uploadVideo:videoData Uid:uid Title:titleString Tags:tagsString ThumbnailTime:coverTime completion:^(bool success, NSError *err){
            if (err) {
                NSLog(@"%@", err.localizedDescription);
                
                [weakSelf.progressView hide];
                
                [weakSelf doSaveToDraft];
                
                BOOL fromDraft = [[weakSelf.uploadVideoInfo valueForKey:@"isFromDraft"] boolValue];
                
                if (fromDraft) {
                    //clear draft video
                    [weakSelf clearDraftVideo];
                }else {
                    //clear clips and temp video.
                    [weakSelf clearTempVideos];
                }
                
            }
            else if (success) {
                //process after submit success.
            }
        }];
    });
    
}

- (void)clearDraftVideo
{
    
    NSString *videoPath = [self.uploadVideoInfo valueForKey:@"videoPath"];

    NSString *filesPath = [videoPath stringByDeletingLastPathComponent];
    
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:filesPath error:&err];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshDraftListNotification" object:nil userInfo:nil];
    
}

/**
 *  @description: clear temp videos in temp directory.
 */
- (void)clearTempVideos
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *videoFilePath = [VNUtility getNSCachePath:@"VideoFiles"];
    
    NSString *filePath = [videoFilePath stringByAppendingPathComponent:@"Clips"];
    
    NSArray *arr = [fm contentsOfDirectoryAtPath:filePath error:nil];
    
    for (NSString *dir in arr) {
        [fm removeItemAtPath:[filePath stringByAppendingPathComponent:dir] error:nil];
    }
    
    filePath = [videoFilePath stringByAppendingPathComponent:@"Temp"];
    
    arr = [fm contentsOfDirectoryAtPath:filePath error:nil];
    
    for (NSString *dir in arr) {
        [fm removeItemAtPath:[filePath stringByAppendingPathComponent:dir] error:nil];
    }
    
}

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.videoTableView) {
        return self.mineVideoArr.count;
    }
    if (tableView == self.favouriteTableView) {
        return self.favVideoArr.count;
    }
    if (tableView == self.followTableView) {
        return self.followArr.count;
    }
    if (tableView == self.fansTableView) {
        return self.fansArr.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
         VNProfileVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileVideoTableViewCellIdentifier"];
        VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
        cell.news = news;
        for (NSDictionary *dic in self.favouriteNewsArr) {
            if ([[dic objectForKey:@"nid"] isEqualToString:[NSString stringWithFormat:@"%d", news.nid]]) {
                cell.isFavouriteNews=YES;
                //[self.favouriteBtn setSelected:YES];
                break;
            }
        }
        [cell reload];
        if (indexPath.row == 0 && firstLoading && isAutoPlayOption) {
            [cell startOrPausePlaying:YES];
            firstLoading = NO;
        }
        cell.commentHandler = ^(){
            VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
            newsDetailViewController.news = news;
            newsDetailViewController.indexPath=indexPath;
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        };
        
        __weak typeof(self) weakSelf = self;
        __weak typeof(cell) weakCell = cell;

        cell.moreHandler = ^{
            UIActionSheet *actionSheet = nil;
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [news.author.uid isEqualToString:weakSelf.uid] ? @"删除" : @"举报", nil];
            weakSelf.shareNews = news;
            weakSelf.shareNewsIndexPath=indexPath;
            [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
        };
        cell.likeHandler = ^(){
            if (!self.uid || !self.user_token) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                [alert show];
                return;
            }
            if (!weakCell.isFavouriteNews) {
                [VNHTTPRequestManager favouriteNews:news.nid operation:@"add" userID:self.uid user_token:self.user_token completion:^(BOOL succeed,BOOL isNewsDeleted,int  like_count, NSError *error) {
                    //isNewsDeleted=YES;
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (isNewsDeleted) {
                        //删除相应的cell
                        //[weakSelf.userVideoArr removeObjectAtIndex:indexPath.row];
                        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        [VNUtility showHUDText:@"该视频已被删除!" forView:self.view];
                    }
                    else if (succeed) {
                        weakCell.isFavouriteNews=YES;
                        if (like_count>10000) {
                            weakCell.favouriteLabel.text=[NSString stringWithFormat:@"%d万",like_count/10000];
                        }
                        else
                        {
                            weakCell.favouriteLabel.text=[NSString stringWithFormat:@"%d",like_count];
                        }
                        for (VNMineProfileHeaderView *headerView in self.headerViewArr) {
                            headerView.fansCountLabel.text = [self bigNumberToString:like_count];
                            //[headerView reload];
                        }
                        //[VNUtility showHUDText:@"点赞成功!" forView:self.view];
                    }
                    else {
                        [VNUtility showHUDText:@"已点赞!" forView:self.view];
                    }
                }];
            }
            else
            {
                [VNHTTPRequestManager favouriteNews:news.nid operation:@"remove" userID:self.uid user_token:self.user_token completion:^(BOOL succeed,BOOL isNewsDeleted,int  like_count, NSError *error) {
                    //isNewsDeleted=YES;
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (isNewsDeleted) {
                        //删除相应的cell
                        //[weakSelf.userVideoArr removeObjectAtIndex:indexPath.row];
                       // [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        [VNUtility showHUDText:@"该视频已被删除!" forView:self.view];
                    }
                    else if (succeed) {
                        weakCell.isFavouriteNews=NO;
                        if (like_count>10000) {
                            weakCell.favouriteLabel.text=[NSString stringWithFormat:@"%d万",like_count/10000];
                        }
                        else
                        {
                            weakCell.favouriteLabel.text=[NSString stringWithFormat:@"%d",like_count];
                        }
                        for (VNMineProfileHeaderView *headerView in self.headerViewArr) {
                            headerView.fansCountLabel.text = [self bigNumberToString:like_count];
                            //[headerView reload];
                        }
                        //[VNUtility showHUDText:@"取消点赞成功!" forView:self.view];
                    }
                    else {
                        [VNUtility showHUDText:@"取消点赞失败!" forView:self.view];
                    }
                }];
            }
        };
        return cell;
    }
    if (tableView == self.favouriteTableView) {
        VNProfileVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileFavTableViewCellIdentifier"];
        VNNews *news = [self.favVideoArr objectAtIndex:indexPath.row];
        cell.news = news;
        [cell reload];
        if (indexPath.row == 0 && firstLoading) {
            [cell startOrPausePlaying:YES];
            firstLoading = NO;
        }
        cell.commentHandler = ^(){
            VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
            newsDetailViewController.news = news;
            newsDetailViewController.indexPath=indexPath;
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        };
        
        __weak typeof(self) weakSelf = self;
        __weak typeof(cell) weakCell = cell;
        cell.moreHandler = ^{
            [VNHTTPRequestManager isNewsDeleted:weakCell.news.nid completion:^(BOOL isNewsDeleted,NSError *error)
             {
                 //isNewsDeleted=YES;
                 if (error) {
                     NSLog(@"%@", error.localizedDescription);
                 }
                 else if (isNewsDeleted) {
                     [weakSelf.favVideoArr removeObjectAtIndex:indexPath.row];
                     [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                     [VNUtility showHUDText:@"该视频已被删除!" forView:self.view];
                     
                 }
                 else
                 {
                     UIActionSheet *actionSheet = nil;
                     actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [news.author.uid isEqualToString:weakSelf.uid] ? @"删除" : @"举报", @"取消喜欢",nil];
                     weakSelf.shareNews = news;
                     weakSelf.shareNewsIndexPath=indexPath;
                     [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
                 }
             }];
            /*UIActionSheet *actionSheet = nil;
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [news.author.uid isEqualToString:weakSelf.uid] ? @"删除" : @"举报", nil];
            weakSelf.shareNews = news;
            [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];*/
        };
        
        return cell;
    }
    if (tableView == self.followTableView) {
        VNProfileFansTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileFollowTableViewCellIdentifier"];
        VNUser *user = [self.followArr objectAtIndex:indexPath.row];
        cell.user = user;
        [cell reload];
        __weak typeof(cell) weakCell = cell;
        cell.followHandler = ^(){
            [VNHTTPRequestManager followIdol:user.uid follower:self.uid userToken:self.user_token operation:@"add" completion:^(BOOL succeed, int fans_count,NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (succeed) {
                    //[VNUtility showHUDText:@"关注成功!" forView:self.view];
                    weakCell.followBtn.hidden = YES;
                    [self addIdolOrFans:NO];
                    weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                else {
                    [VNUtility showHUDText:@"关注失败!" forView:self.view];
                }
            }];
        };
        return cell;
    }
    if (tableView == self.fansTableView) {
        VNProfileFansTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileFansTableViewCellIdentifier"];
        VNUser *user = [self.fansArr objectAtIndex:indexPath.row];
        cell.user = user;
        [cell reload];
        __weak typeof(cell) weakCell = cell;
        cell.followHandler = ^(){
            [VNHTTPRequestManager followIdol:user.uid follower:self.uid userToken:self.user_token operation:@"add" completion:^(BOOL succeed,int fans_count, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (succeed) {
                   // [VNUtility showHUDText:@"关注成功!" forView:self.view];
                    weakCell.followBtn.hidden = YES;
                    [self addIdolOrFans:YES];
                    weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                else {
                    [VNUtility showHUDText:@"关注失败!" forView:self.view];
                }
            }];
        };
        return cell;
    }
    
    return nil;
}

-(NSString *)bigNumberToString:(int)number
{
    if (number>10000) {
        return [NSString stringWithFormat:@"%d万",number/10000];
    }
    else
    {
        return [NSString stringWithFormat:@"%d",number];
    }

}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
        VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
        VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
        newsDetailViewController.news = news;
        newsDetailViewController.indexPath=indexPath;
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
        newsDetailViewController.controllerType = SourceViewControllerTypeMineProfileVideo;
        [self.navigationController pushViewController:newsDetailViewController animated:YES];
    }
    else if (tableView == self.favouriteTableView) {
        VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
        VNNews *news = [self.favVideoArr objectAtIndex:indexPath.row];
        newsDetailViewController.news = news;
        newsDetailViewController.indexPath=indexPath;
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
        newsDetailViewController.controllerType = SourceViewControllerTypeMineProfileFavourite;
        [self.navigationController pushViewController:newsDetailViewController animated:YES];
    }
    else if (tableView == self.followTableView) {
        VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
        VNUser *user = [self.followArr objectAtIndex:indexPath.row];
        profileViewController.uid = user.uid;
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
    else if (tableView == self.fansTableView) {
        VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
        VNUser *user = [self.fansArr objectAtIndex:indexPath.row];
        profileViewController.uid = user.uid;
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
        VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
        return [self cellHeightFor:news];
    }
    if (tableView == self.favouriteTableView) {
        VNNews *news = [self.favVideoArr objectAtIndex:indexPath.row];
        return [self cellHeightFor:news];
    }
    if (tableView == self.followTableView || tableView == self.fansTableView) {
        return 50.0;
    }
    return 0;
}

#pragma mark - SEL

- (void)addIdolOrFans:(BOOL)isAFan {
    for (VNMineProfileHeaderView *headerView in self.headerViewArr) {
        if (isAFan) {
            NSInteger fansCount = [headerView.fansCountLabel.text integerValue];
            fansCount++;
            headerView.fansCountLabel.text = [NSString stringWithFormat:@"%d", fansCount];
        }
        else {
            NSInteger idolCount = [headerView.followCountLabel.text integerValue];
            idolCount++;
            headerView.followCountLabel.text = [NSString stringWithFormat:@"%d", idolCount];
        }
    }
}

- (CGFloat)cellHeightFor:(VNNews *)news {
    __block CGFloat cellHeight = 390.0;
    
    NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:17.0]};
    CGRect rect = [news.title boundingRectWithSize:CGSizeMake(280.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    cellHeight += CGRectGetHeight(rect);
    NSLog(@"%f", cellHeight);
    return cellHeight;
}

- (void)hideTabBar {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    for(UIView *view in self.tabBarController.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            [view setFrame:CGRectMake(view.frame.origin.x, CGRectGetHeight(self.view.bounds), view.frame.size.width, view.frame.size.height)];
        }
    }
    isTabBarHidden = YES;
    [UIView commitAnimations];
}

- (void)showTabBar {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    for(UIView *view in self.tabBarController.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            [view setFrame:CGRectMake(view.frame.origin.x, CGRectGetHeight(self.view.bounds)-49, view.frame.size.width, view.frame.size.height)];
        }
    }
    isTabBarHidden = NO;
    [UIView commitAnimations];
}

#pragma mark - Scrollview Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    userScrolling = YES;
    initialScrollOffset = scrollView.contentOffset;
    
    UITableView *tableView = (UITableView *)scrollView;
    if (tableView == self.videoTableView || tableView == self.favouriteTableView) {
        NSArray *visibleCells=[tableView visibleCells];
        for (VNProfileVideoTableViewCell *cell in visibleCells) {
            if (cell.isPlaying) {
                [cell startOrPausePlaying:NO];
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!userScrolling) return;
    
    //initialize
    if (scrollView.contentSize.height <= scrollView.bounds.size.height) {
        [self showTabBar];
        return;
    }
    
    if (scrollView.contentOffset.y <= 0) {
        //Scrolling above the page
        [self showTabBar];
        return;
    }
    
    //contentOffset
    CGFloat contentOffset = scrollView.contentOffset.y - initialScrollOffset.y;
    
    if (scrollView.contentOffset.y <= 24) {
        contentOffset = scrollView.contentOffset.y;
    } else {
        if (contentOffset < 0 && (scrollView.contentOffset.y - previousScrollOffset.y) > 0) {
            initialScrollOffset = scrollView.contentOffset;
        }
    }
    
    contentOffset = roundf(contentOffset);
    
    if (contentOffset >= 0 && (scrollView.contentOffset.y + scrollView.frame.size.height < scrollView.contentSize.height) && scrollView.contentOffset.y > 24) {
        [self hideTabBar];
    }
    
    //scroll to bottom, quit fullScreen
    if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height+49) {
        [self showTabBar];
    }
    
    if (scrollView.contentOffset.y + scrollView.frame.size.height <= scrollView.contentSize.height) {
        previousScrollOffset = scrollView.contentOffset;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (velocity.y < -0.5) {
        userScrolling = NO;
        [self showTabBar];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    userScrolling = NO;
    initialScrollOffset = CGPointMake(0, 0);
    
    if (isAutoPlayOption) {
        UITableView *tableView = (UITableView *)scrollView;
        if (tableView == self.videoTableView || tableView == self.favouriteTableView) {
            NSArray *visibleCells=[tableView visibleCells];
            CGFloat minGap = CGRectGetHeight(self.view.window.bounds);
            VNProfileVideoTableViewCell *curCell = nil;
            for (VNProfileVideoTableViewCell *cell in visibleCells) {
                CGRect cellFrameInTableView = [tableView rectForRowAtIndexPath:[tableView indexPathForCell:cell]];
                CGRect cellFrameInWindow = [tableView convertRect:cellFrameInTableView toView:[UIApplication sharedApplication].keyWindow];
                NSLog(@"%f", self.view.window.center.y);
                CGFloat gap = fabs(CGRectGetMidY(cellFrameInWindow)-self.view.window.center.y);
                if (gap < minGap) {
                    NSLog(@"%f, %f", minGap, gap);
                    minGap = gap;
                    curCell = cell;
                }
            }
            if (curCell && !curCell.isPlaying) {
                [curCell startOrPausePlaying:YES];
            }
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.shareNews) {
        NSLog(@"%@", [UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray);
        NSString *shareURL = self.shareNews.url;
        if (!shareURL || [shareURL isEqualToString:@""]) {
            shareURL = [[NSString alloc]initWithFormat:@"http://zmysp.sinaapp.com/web/view.php?id=%d&start=1",self.shareNews.nid];
        }
        NSString *snsName = nil;
        switch (buttonIndex) {
                //微信朋友圈
            case 0: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:3];
                [UMSocialData defaultData].extConfig.wechatTimelineData.url = shareURL;
            }
                break;
                //微信好友
            case 1: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:2];
                [UMSocialData defaultData].extConfig.wechatSessionData.url = shareURL;
            }
                break;
                //新浪微博
            case 2: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:0];
            }
                break;
                //QQ空间
            case 3: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:5];
                [UMSocialData defaultData].extConfig.qzoneData.url = shareURL;
            }
                break;
                //QQ好友
            case 4: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:6];
                [UMSocialData defaultData].extConfig.qqData.url = shareURL;
            }
                break;
                //腾讯微博
            case 5: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:1];
            }
                break;
                //人人网
            case 6: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:7];
            }
                break;
                //取消或复制
            case 7: {
                if (self.shareNews.url) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    pasteboard.string = self.shareNews.url;
                    [VNUtility showHUDText:@"已复制该文章链接" forView:self.view];
                }
                else {
                    [VNUtility showHUDText:@"暂无该文章链接" forView:self.view];
                }
            }
                break;
                //删除或举报
            case 8: {
                NSString *buttonTitle = [actionSheet buttonTitleAtIndex:8];
                if ([buttonTitle isEqualToString:@"删除"]) {
                    //TODO: 删除帖子
                    [actionSheet dismissWithClickedButtonIndex:10 animated:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确定要永久删除视频？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                    _deleteAlert=alert;
                    [alert show];

                }
                else if ([buttonTitle isEqualToString:@"举报"]) {
                    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                    if (userInfo && userInfo.count) {
                        NSString *uid = [userInfo objectForKey:@"openid"];
                        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                        if (uid && user_token) {
                            [VNHTTPRequestManager report:[NSString stringWithFormat:@"%d", self.shareNews.nid] type:@"reportNews" userID:uid userToken:user_token completion:^(BOOL succeed, NSError *error) {
                                if (error) {
                                    NSLog(@"%@", error.localizedDescription);
                                }
                                else if (succeed) {
                                    [VNUtility showHUDText:@"举报成功!" forView:self.view];
                                }
                                else {
                                    [VNUtility showHUDText:@"您已举报该文章" forView:self.view];
                                }
                            }];
                        }
                    }
                    else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                        [alert show];
                        return;
                    }
                }
            }
                break;
                //取消喜欢
            case 9:{
                NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
                NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                if (mineUid && user_token) {
                    [VNHTTPRequestManager favouriteNews:_shareNews.nid operation:@"remove" userID:mineUid user_token:user_token completion:^(BOOL succeed,BOOL isNewsDeleted, int like_count,NSError *error){
                        //isNewsDeleted=YES;
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else if (isNewsDeleted)
                        {
                            [self.favVideoArr removeObjectAtIndex:_shareNewsIndexPath.row];
                            [self.favouriteTableView deleteRowsAtIndexPaths:@[_shareNewsIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                            [VNUtility showHUDText:@"该视频已被删除!" forView:self.view];
                        }
                        else if(succeed)
                        {
                            [self.favVideoArr removeObjectAtIndex:_shareNewsIndexPath.row];
                            [self.favouriteTableView deleteRowsAtIndexPaths:@[_shareNewsIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                            for (VNMineProfileHeaderView *headerView in self.headerViewArr) {
                                headerView.fansCountLabel.text = [self bigNumberToString:like_count];
                                //[headerView reload];
                            }
                        }
                        else
                        {
                            [VNUtility showHUDText:@"取消喜欢失败!" forView:self.view];
                        }
                    }];
                }
            }
                break;
                //取消
            case 10: {
                return ;
            }
                break;
        }
        //设置分享内容，和回调对象
        if (buttonIndex < 7) {
            NSString *shareText = [NSString stringWithFormat:@"我在用follow my style看到一个有趣的视频：“%@”，来自@“%@”快来看看吧~ %@", self.shareNews.title, self.shareNews.author.name,self.shareNews.url];
            UIImage *shareImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.shareNews.imgMdeia.url]]];
            shareStr = shareText;
            
            [[UMSocialControllerService defaultControllerService] setShareText:shareText shareImage:shareImage socialUIDelegate:self];
            UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:snsName];
            snsPlatform.snsClickHandler(self,[UMSocialControllerService defaultControllerService],YES);
        }
    }
}

#pragma mark - UMSocialUIDelegate

-(void)didCloseUIViewController:(UMSViewControllerType)fromViewControllerType
{
    NSLog(@"didClose is %d",fromViewControllerType);
}

//下面得到分享完成的回调
-(void)didFinishGetUMSocialDataInViewController:(UMSocialResponseEntity *)response
{
    NSLog(@"didFinishGetUMSocialDataInViewController with response is %@",response);
    //根据`responseCode`得到发送结果,如果分享成功
    if(response.responseCode == UMSResponseCodeSuccess) {
        //得到分享到的微博平台名
        NSLog(@"share to sns name is %@",[[response.data allKeys] objectAtIndex:0]);
        [VNUtility showHUDText:@"分享成功!" forView:self.view];
        [VNHTTPRequestManager commentNews:self.shareNews.nid content:shareStr completion:^(BOOL succeed,BOOL isNewsDeleted, VNComment *comment, int comment_count,NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (isNewsDeleted)
            {
                //删除相应的cell
            }
            else if (succeed) {
                NSLog(@"分享添加评论成功！");
            }
        }];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_deleteAlert ==alertView) {
        if (buttonIndex==1) {
            NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
            NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
            if (mineUid && user_token) {
                [VNHTTPRequestManager deleteNews:_shareNews.nid userID:mineUid userToken:user_token completion:^(BOOL succeed,int news_count,NSError *error)
                 {
                     if (error) {
                         NSLog(@"%@", error.localizedDescription);
                     }
                     else if(succeed)
                     {
                         //[self deleteCellAndPop:1];
                         [self.mineVideoArr removeObjectAtIndex:_shareNewsIndexPath.row];
                         [self.videoTableView deleteRowsAtIndexPaths:@[_shareNewsIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                         for (VNMineProfileHeaderView *headerView in self.headerViewArr) {
                             headerView.videoCountLabel.text = [self bigNumberToString:news_count];
                             //[headerView reload];
                         }
                         [VNUtility showHUDText:@"该视频已被删除!" forView:self.view];
                     }
                     else
                     {
                         [VNUtility showHUDText:@"删除视频失败" forView:self.view];
                     }
                 }];
            }
        }
        else
        {return;}
        return;
    }
    if (buttonIndex == 0) {
        return;
    }
    else if (buttonIndex == 1) {
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

#pragma mark - IBAction

- (IBAction)setting:(id)sender {
    VNSettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNSettingViewController"];
    settingViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:settingViewController animated:YES];
}

- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - VNUploadManagerDelegate

// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)key ret:(NSDictionary *)ret
{
    
    [self.progressView hide];
    
    [self reload];
    
    __weak VNMineProfileViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *titleString = [self.uploadVideoInfo valueForKey:@"title"];
        
        NSString *nickNameString = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] valueForKey:@"nickname"];
        
        NSString *urlString = [NSString stringWithFormat:@"http://fashion-video.qiniudn.com/%@",key];
        
        NSString *shareText = [NSString stringWithFormat:@"我在用follow my style看到一个有趣的视频：“%@”，来自@“%@”快来看看吧~ %@", titleString, nickNameString, urlString];
        NSLog(@"upload video info :%@",weakSelf.uploadVideoInfo);
        UIImage *coverImage = [weakSelf.uploadVideoInfo objectForKey:@"coverImg"];
        
        if ([[weakSelf.uploadVideoInfo valueForKey:@"isSinaOn"] boolValue]) {
            //分享新浪
            [[UMSocialDataService defaultDataService] postSNSWithTypes:@[UMShareToSina] content:shareText image:coverImage location:nil urlResource:nil presentedController:weakSelf completion:^(UMSocialResponseEntity * response){
                if (response.responseCode == UMSResponseCodeSuccess) {
                    NSLog(@"新浪微博分享成功了");
                } else if(response.responseCode != UMSResponseCodeCancel) {
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"失败" message:@"新浪微博分享失败" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
                    [alertView show];
                }
            }];
        }
        if ([[weakSelf.uploadVideoInfo valueForKey:@"isWeChatOn"] boolValue]) {
            //分享朋友圈
            [[UMSocialDataService defaultDataService] postSNSWithTypes:@[UMShareToWechatTimeline] content:shareText image:coverImage location:nil urlResource:nil presentedController:weakSelf completion:^(UMSocialResponseEntity * response){
                if (response.responseCode == UMSResponseCodeSuccess) {
                    NSLog(@"朋友圈分享成功了");
                } else if(response.responseCode != UMSResponseCodeCancel) {
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"失败" message:@"微信朋友圈分享失败" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
                    [alertView show];
                }
            }];
        }
    });
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        BOOL fromDraft = [[weakSelf.uploadVideoInfo valueForKey:@"isFromDraft"] boolValue];
        
        if (fromDraft) {
            //clear draft video
            [self clearDraftVideo];
        }else {
            //clear clips and temp video.
            [self clearTempVideos];
        }
    });
    
}

// Upload failed.
- (void)uploadFailed:(NSString *)key error:(NSError *)error
{
    [self.progressView hide];
}

- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent
{
    self.progressView.progress = percent;
}

- (void)doSaveToDraft
{
    
    double timeInterval = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *filePath = [VNUtility getNSCachePath:[NSString stringWithFormat:@"VideoFiles/Draft/%lf",timeInterval]];
    
    
    BOOL _isDir;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&_isDir]){
        if (![[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil]) {
            
        }
    }
    
    NSString *videoFilePath = [NSString stringWithFormat:@"%@/%lf.mp4",filePath,timeInterval];
    NSString *coverFilePath = [NSString stringWithFormat:@"%@/%lf.jpg",filePath,timeInterval];
    NSString *coverTimePointFilePath = [NSString stringWithFormat:@"%@/%lf",filePath,timeInterval];
    
    NSString *videoPath = [self.uploadVideoInfo valueForKey:@"videoPath"];
    NSString *coverTimeString = [NSString stringWithFormat:@"%@",[self.uploadVideoInfo valueForKey:@"coverTime"]];
    UIImage *coverImage = [self.uploadVideoInfo valueForKey:@"coverImg"];

    NSError *err;
    
    [coverTimeString writeToFile:coverTimePointFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
    NSData *data = UIImageJPEGRepresentation(coverImage, 1);
    [data writeToFile:coverFilePath atomically:YES];
    
    [[NSFileManager defaultManager] copyItemAtPath:videoPath toPath:videoFilePath error:&err];
    
}

@end
