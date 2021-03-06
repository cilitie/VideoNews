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
    BOOL mineVideofirstLoading;
    BOOL favVideofirstLoading;
    BOOL firstLoad;
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
@property (strong, nonatomic) NSString *favVideoPageTime;
@property (strong, nonatomic) NSMutableArray *favouriteNewsArr;
@property (strong, nonatomic) UIAlertView *deleteAlert;
@property (strong ,nonatomic) UIActionSheet *likeActionSheet;
@property (strong, nonatomic) NSString *urlStrToShare;

@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *user_token;
@property (strong, nonatomic) VNNews *shareNews;//分享的news
@property (strong, nonatomic) NSIndexPath *shareNewsIndexPath;//分享的news对应的位置
@property (strong, nonatomic) VNNews *selectedNews;//选中的news
@property (strong, nonatomic) NSIndexPath *selectedNewsIndexPath;//选中的news对应的位置

@property (strong, nonatomic) NSArray *headerViewArr;

@property (nonatomic, strong) NSDictionary *uploadVideoInfo;    //上传video信息
@property (nonatomic, strong) VNUploadVideoProgressView *progressView;   //进度条
- (IBAction)setting:(id)sender;
- (IBAction)pop:(id)sender;

@end

static NSString *shareStr;
#define KVideoTag 101
#define KLikeTag 102
#define KDeleteFromLikes 200

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
        _selectedNews=nil;
        _selectedNewsIndexPath=nil;
        _uid = nil;
        _user_token = nil;
        _isPush = NO;
        isTabBarHidden = NO;
        mineVideofirstLoading = YES;
        favVideofirstLoading = NO;
        firstLoad=YES;
        isAutoPlayOption = [[[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay] boolValue];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (firstLoad) {
        firstLoad=NO;
        return;
    }
//请求喜欢列表和关注列表
    __weak typeof(self)weakSelf=self;
    if (self.headerViewArr.count) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([VNHTTPRequestManager isReachable]) {
                [VNHTTPRequestManager userInfoForUser:weakSelf.uid completion:^(VNUser *userInfo, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (userInfo) {
                        weakSelf.mineInfo = userInfo;
                        for (VNMineProfileHeaderView *headerView in weakSelf.headerViewArr) {
                            NSLog(@"%@", NSStringFromCGRect(headerView.frame));
                            headerView.userInfo = userInfo;
                            [headerView reload];
                        }
                    }
                }];
            }
            else
            {
                [VNUtility showHUDText:@"请检查你的网络！" forView:weakSelf.view];
                return ;
            }
        });
    }
    //__weak typeof(self) weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager favouriteNewsListFor:weakSelf.uid userToken:weakSelf.user_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (favouriteNewsArr.count) {
                [weakSelf.favouriteNewsArr removeAllObjects];
                [weakSelf.favouriteNewsArr addObjectsFromArray:favouriteNewsArr];
                // NSLog(@"%d", favouriteNewsArr.count);
            }
            else if(favouriteNewsArr.count==0)
            {
                [weakSelf.favouriteNewsArr removeAllObjects];
            }
        }];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager idolListForUser:weakSelf.uid userToken:weakSelf.user_token completion:^(NSArray *idolArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            if (idolArr.count) {
                [weakSelf.idolListArr removeAllObjects];
                [weakSelf.idolListArr addObjectsFromArray:idolArr];
            }
            else if(idolArr.count==0)
            {
                [weakSelf.idolListArr removeAllObjects];
            }
        }];
    });

    if (!self.videoTableView.hidden) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /*[VNHTTPRequestManager favouriteNewsListFor:self.uid userToken:_user_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (favouriteNewsArr.count) {
                    [self.favouriteNewsArr removeAllObjects];
                    [self.favouriteNewsArr addObjectsFromArray:favouriteNewsArr];
                    // NSLog(@"%d", favouriteNewsArr.count);
                }
                else if(favouriteNewsArr.count==0)
                {
                    [self.favouriteNewsArr removeAllObjects];
                }
                VNNews *news=[weakSelf.mineVideoArr firstObject];
                NSString *refreshTimeStamp = news.timestamp;
               
                int pagesize=[weakSelf.mineVideoArr count];
            
                [VNHTTPRequestManager updateVideoListForUser:weakSelf.uid pageTime:refreshTimeStamp pageSize:pagesize completion:^(BOOL succeed,NSArray *videoArr,NSArray *list,NSError *error){
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else
                    {
                        if (list && list.count!=0) {
                            //for (VNNews *news in weakSelf.mineVideoArr) {
                            for (int i=0; i<weakSelf.mineVideoArr.count; ) {
                                int flag=0;
                                VNNews *news=[weakSelf.mineVideoArr objectAtIndex:i];
                                for (NSDictionary *dic in list) {
                                    if (news.nid==[dic[@"nid"]intValue]) {
                                        news.like_count=[dic[@"like_count"]intValue];
                                        news.comment_count=[dic[@"comment_count"]intValue];
                                        flag=1;
                                        break;
                                    }
                                }
                                if (flag==0) {
                                    [weakSelf.mineVideoArr removeObjectAtIndex:i];
                                }
                                else
                                {i++;}
                            }
                        }
                        if (videoArr && [videoArr count]!=0) {
                            NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                                                   NSMakeRange(0,[videoArr count])];
                            [weakSelf.mineVideoArr insertObjects:videoArr atIndexes:indexes];
                        }
                        [weakSelf.videoTableView reloadData];
                    }
                }];
             */
            NSString *refreshTimeStamp =[VNHTTPRequestManager timestamp];
            int pagesize=[weakSelf.mineVideoArr count];
                [VNHTTPRequestManager videoListForUserWithPagesize:weakSelf.uid perPage:pagesize type:@"video" fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                    if (error) {
                    }
                    else {
                        [weakSelf.mineVideoArr removeAllObjects];
                        [weakSelf.mineVideoArr addObjectsFromArray:videoArr];
                        [weakSelf.videoTableView reloadData];
                    }
                }];
           // }];
        });
    }
    if (!self.favouriteTableView.hidden) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int pagesize=weakSelf.favVideoArr.count;
           /* VNNews *news=[weakSelf.favVideoArr firstObject];
            NSString *refreshTimeStamp = news.like_timestamp;
            [VNHTTPRequestManager updateFavListForUser:weakSelf.uid userToken:weakSelf.user_token pageTime:refreshTimeStamp pageSize:pagesize completion:^(BOOL succeed,NSArray *videoArr,NSArray *list,NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else
                    {
                        if (list && list.count!=0) {
                            //for (VNNews *news in weakSelf.favVideoArr) {
                            for (int i=0; i<weakSelf.favVideoArr.count; ) {
                                VNNews *news=[weakSelf.favVideoArr objectAtIndex:i];
                                int flag=0;
                                NSLog(@"%@",weakSelf.favVideoArr);
                                for (NSDictionary *dic in list) {
                                    
                                    if (news.nid==[dic[@"nid"]intValue]) {
                                        news.like_count=[dic[@"like_count"]intValue];
                                        news.comment_count=[dic[@"comment_count"]intValue];
                                        flag=1;
                                        break;
                                    }
                                }
                                if (flag==0) {
                                    VNNews *n=news;
                                    [weakSelf.favVideoArr removeObject:n];
                                    NSLog(@"%@",weakSelf.favVideoArr);
                                }
                                else
                                {i++;}
                            }
                        }
                        if (videoArr && [videoArr count]!=0) {
                            NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                                                   NSMakeRange(0,[videoArr count])];
                            [weakSelf.favVideoArr insertObjects:videoArr atIndexes:indexes];
                        }
                        [weakSelf.favouriteTableView reloadData];
                    }

                });
            }];
             */
            NSString *refreshTimeStamp=[VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager favVideoListForUser:weakSelf.uid userToken:weakSelf.user_token fromTime:refreshTimeStamp perPage:pagesize completion:^(NSArray *videoArr, NSString *moreTimestamp,NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.favVideoArr removeAllObjects];
                        [weakSelf.favVideoArr addObjectsFromArray:videoArr];
                        [weakSelf.favouriteTableView reloadData];
                    });
                    weakSelf.favVideoPageTime=moreTimestamp;
                }
            }];
        });

    }
    if (!self.followTableView.hidden) {
        [self.followTableView reloadData];

    }
    if (!self.fansTableView.hidden) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           /* [VNHTTPRequestManager idolListForUser:self.uid userToken:self.user_token completion:^(NSArray *idolArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (idolArr.count) {
                    [self.idolListArr removeAllObjects];
                    [self.idolListArr addObjectsFromArray:idolArr];
                }
                else if(idolArr.count==0)
                {
                    [self.idolListArr removeAllObjects];
                }*/
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                int pagesize=weakSelf.fansArr.count;
                if (pagesize<10) {
                    pagesize=10;
                }
                //int pagesize=[weakSelf.mineInfo.fans_count intValue];
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp perPage:pagesize completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        if (weakSelf.idolListArr.count) {
                            for (VNUser *user in userArr) {
                                if ([weakSelf.idolListArr containsObject:user.uid]) {
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
                }];
            //}];
        });
    }
}
//zmy add
-(void)reloadHeaderView:(VNMineProfileHeaderView *)headerView
{
    __weak typeof(self)weakSelf=self;
    [VNHTTPRequestManager userInfoForUser:weakSelf.uid completion:^(VNUser *userInfo, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        if (userInfo) {
            weakSelf.mineInfo = userInfo;
            //for (VNMineProfileHeaderView *headerView in self.headerViewArr) {
                NSLog(@"%@", NSStringFromCGRect(headerView.frame));
                headerView.userInfo = userInfo;
                [headerView reload];
           // }
        }
    }];

}
//
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.mineVideoArr.count) {
        if (!self.videoTableView.hidden) {
            for (VNProfileVideoTableViewCell *cell in [self.videoTableView visibleCells]) {
                //if (cell.isPlaying) {
                    [cell startOrPausePlaying:NO];
                    [cell.moviePlayer stop];
               // }
            }
        }
    }
    if (self.favVideoArr.count) {
        if (!self.favouriteTableView.hidden) {
            for (VNProfileVideoTableViewCell *cell in [self.favouriteTableView visibleCells]) {
               // if (cell.isPlaying) {
                    [cell startOrPausePlaying:NO];
                    [cell.moviePlayer stop];
               // }
            }
        }
    }
    if (isTabBarHidden && self.isPush) {
        [self showTabBar];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.isPush) {
        self.popBtn.hidden = NO;
        [self.popBtn setHitTestEdgeInsets:UIEdgeInsetsMake(-15.0, -15.0, -15.0, -15.0)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadVideoFile:) name:VNMineProfileUploadVideoNotifiction object:nil];
    //zmy add
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userReLogin:) name:VNLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(modifyFollowListForFollowHandler:) name:VNProfileFollowHandlerNotification object:nil];
    //
    VNMineProfileHeaderView *videoHeaderView = loadXib(@"VNMineProfileHeaderView");
    VNMineProfileHeaderView *favHeaderView = loadXib(@"VNMineProfileHeaderView");
    VNMineProfileHeaderView *followHeaderView = loadXib(@"VNMineProfileHeaderView");
    VNMineProfileHeaderView *fansHeaderView = loadXib(@"VNMineProfileHeaderView");
    self.headerViewArr = @[videoHeaderView, favHeaderView, followHeaderView, fansHeaderView];
    
    self.videoTableView.tableHeaderView = videoHeaderView;
    self.favouriteTableView.tableHeaderView = favHeaderView;
    self.followTableView.tableHeaderView = followHeaderView;
    self.fansTableView.tableHeaderView = fansHeaderView;
    //NSLog(@"%@", NSStringFromCGRect(videoHeaderView.frame));
    
    [self.followTableView setTableFooterView:[[UIView alloc] init]];
    [self.fansTableView setTableFooterView:[[UIView alloc] init]];
    [self.view addSubview:self.progressView];
    //NSLog(@"%@", NSStringFromCGRect(videoHeaderView.frame));
    
    _videoTableView.showsVerticalScrollIndicator=NO;
    _favouriteTableView.showsVerticalScrollIndicator=NO;
    _followTableView.showsVerticalScrollIndicator=NO;
    _fansTableView.showsVerticalScrollIndicator=NO;
    
    [self reload];
}
//zmy add
-(void)userReLogin:(NSNotification *)notification
{
    [self reload];
    firstLoad=YES;
    [_headerViewArr[0] reloadTabStatus:0];
    self.videoTableView.hidden = NO;
    self.favouriteTableView.hidden = YES;
    self.followTableView.hidden = YES;
    self.fansTableView.hidden = YES;
    [self reloadAutoPlayStatus];
}
//zmy add
- (void)reload {
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        self.uid = [userInfo objectForKey:@"openid"];
        self.user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    }
    
    if (self.uid && self.user_token) {
        VNMineProfileHeaderView *videoHeaderView = self.headerViewArr[0];
        VNMineProfileHeaderView *favHeaderView = self.headerViewArr[1];
        VNMineProfileHeaderView *followHeaderView = self.headerViewArr[2];
        VNMineProfileHeaderView *fansHeaderView = self.headerViewArr[3];
        __weak typeof(self)weakSelf=self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([VNHTTPRequestManager isReachable]) {
                [VNHTTPRequestManager userInfoForUser:weakSelf.uid completion:^(VNUser *userInfo, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (userInfo) {
                        weakSelf.mineInfo = userInfo;
                        NSLog(@"%@", NSStringFromCGRect(videoHeaderView.frame));
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
                weakSelf.mineInfo = user;
                videoHeaderView.userInfo = user;
                NSLog(@"%@", NSStringFromCGRect(videoHeaderView.frame));
                [videoHeaderView reload];
                
                favHeaderView.userInfo = user;
                [favHeaderView reload];
                
                followHeaderView.userInfo = user;
                [followHeaderView reload];
                
                fansHeaderView.userInfo = user;
                [fansHeaderView reload];
            }
        });
        
       // __weak typeof(self) weakSelf = self;
        
        videoHeaderView.editHandler = ^(){
            VNEditProfileViewController *editProfileViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNEditProfileViewController"];
            editProfileViewController.hidesBottomBarWhenPushed = YES;
            [weakSelf.navigationController pushViewController:editProfileViewController animated:YES];
        };
        
        videoHeaderView.tabHandler = ^(NSUInteger index){
            if (weakSelf.mineVideoArr.count) {
                for (VNProfileVideoTableViewCell *cell in [weakSelf.videoTableView visibleCells]) {
                    if (cell.isPlaying) {
                        [cell startOrPausePlaying:NO];
                    }
                }
            }
            if (weakSelf.favVideoArr.count) {
                for (VNProfileVideoTableViewCell *cell in [weakSelf.favouriteTableView visibleCells]) {
                    if (cell.isPlaying) {
                        [cell startOrPausePlaying:NO];
                    }
                }
            }
            
            /*for (VNMineProfileHeaderView *headView in self.headerViewArr) {
                [headView reloadTabStatus:index];
            }*/
            
            switch (index) {
                case 0: {
                    [(VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView reloadTabStatus:0];
                    weakSelf.videoTableView.hidden = NO;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = YES;
                    [self reloadAutoPlayStatus];
                    // FIXME: Hard code
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        //不需要请求喜欢列表
                        /*[VNHTTPRequestManager favouriteNewsListFor:self.uid userToken:_user_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else if (favouriteNewsArr.count) {
                                [weakSelf.favouriteNewsArr removeAllObjects];
                                [weakSelf.favouriteNewsArr addObjectsFromArray:favouriteNewsArr];
                                // NSLog(@"%d", favouriteNewsArr.count);
                            }
                            else if (favouriteNewsArr.count==0)
                            {
                                [weakSelf.favouriteNewsArr removeAllObjects];
                            }*/
                            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                            [VNHTTPRequestManager videoListForUser:weakSelf.uid type:@"video" fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (error) {
                                    }
                                    else {
                                        [weakSelf.mineVideoArr removeAllObjects];
                                        [weakSelf.mineVideoArr addObjectsFromArray:videoArr];
                                        [weakSelf.videoTableView reloadData];
                                    }
                                    mineVideofirstLoading = YES;
                                });
                              //  [weakSelf reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView];
                            }];
                        //}];
                    });
                }
                    break;
                case 1: {
                    [(VNMineProfileHeaderView *)weakSelf.favouriteTableView.tableHeaderView reloadTabStatus:1];
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = NO;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = YES;
                    //[weakSelf.favouriteTableView triggerPullToRefresh];
                    [self reloadAutoPlayStatus];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                        [VNHTTPRequestManager favVideoListForUser:weakSelf.uid userToken:weakSelf.user_token fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSString *moreTimestamp,NSError *error) {
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else {
                                [weakSelf.favVideoArr removeAllObjects];
                                [weakSelf.favVideoArr addObjectsFromArray:videoArr];
                                [weakSelf.favouriteTableView reloadData];
                                weakSelf.favVideoPageTime=moreTimestamp;
                                
                            }
                            favVideofirstLoading = YES;
                            //zmy add 刷新头
                           // [self reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.favouriteTableView.tableHeaderView];
                            //
                           
                        }];
                    });

                }
                    break;
                case 2: {
                    [(VNMineProfileHeaderView *)weakSelf.followTableView.tableHeaderView reloadTabStatus:2];
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = NO;
                    weakSelf.fansTableView.hidden = YES;
                    [weakSelf reloadAutoPlayStatus];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                        [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
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
                            //zmy add 刷新头
                            //[self reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.followTableView.tableHeaderView];
                            //
                        }];

                    });

                }
                    break;
                case 3: {
                    [(VNMineProfileHeaderView *)weakSelf.fansTableView.tableHeaderView reloadTabStatus:3];
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = NO;
                    //[weakSelf.fansTableView triggerPullToRefresh];
                    [weakSelf reloadAutoPlayStatus];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        //不需要更新关注列表
                        if (weakSelf.idolListArr.count==0) {
                            [VNHTTPRequestManager idolListForUser:weakSelf.uid userToken:weakSelf.user_token completion:^(NSArray *idolArr, NSError *error) {
                                if (error) {
                                    NSLog(@"%@", error.localizedDescription);
                                }
                                if (idolArr.count) {
                                    [weakSelf.idolListArr removeAllObjects];
                                    [weakSelf.idolListArr addObjectsFromArray:idolArr];
                                }
                            }];
                        }
                        NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                        [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                                if (error) {
                                    NSLog(@"%@", error.localizedDescription);
                                }
                                else {
                                    if (weakSelf.idolListArr.count) {
                                        for (VNUser *user in userArr) {
                                            if ([weakSelf.idolListArr containsObject:user.uid]) {
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
                                //zmy add 刷新头
                               // [self reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.fansTableView.tableHeaderView];
                                //
                        }];
                    });
                    }
                    break;
                case 11: {
                    if (self.mineInfo.avatar) {
                        VNOriginImgViewController *originImgViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNOriginImgViewController"];
                        originImgViewController.imgURL = weakSelf.mineInfo.avatar;
                        originImgViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                        [weakSelf presentViewController:originImgViewController animated:YES completion:nil];
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
        [self.videoTableView registerNib:[UINib nibWithNibName:@"VNProfileVideoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileVideoTableViewCellIdentifier"];
        
        [self.videoTableView addPullToRefreshWithActionHandler:^{
            [weakSelf reloadAutoPlayStatus];
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [VNHTTPRequestManager favouriteNewsListFor:weakSelf.uid userToken:weakSelf.user_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (favouriteNewsArr.count) {
                        [weakSelf.favouriteNewsArr removeAllObjects];
                        [weakSelf.favouriteNewsArr addObjectsFromArray:favouriteNewsArr];
                    }
                    else if (favouriteNewsArr.count==0)
                    {
                        [weakSelf.favouriteNewsArr removeAllObjects];
                    }
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    [VNHTTPRequestManager videoListForUser:weakSelf.uid type:@"video" fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (error) {
                                //  NSLog(@"%@", error.localizedDescription);
                            }
                            else {
                                [weakSelf.mineVideoArr removeAllObjects];
                                [weakSelf.mineVideoArr addObjectsFromArray:videoArr];
                                //NSLog(@"%d", weakSelf.mineVideoArr.count);
                                [weakSelf.videoTableView reloadData];
                            }
                            mineVideofirstLoading = YES;
                            //zmy add 刷新头
                            [weakSelf reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView];
                            //
                            [weakSelf.videoTableView.pullToRefreshView stopAnimating];
                        });
                    }];
                }];
            });
        }];
        
        [self.videoTableView addInfiniteScrollingWithActionHandler:^{
            [weakSelf reloadAutoPlayStatus];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *moreTimeStamp = nil;
            if (weakSelf.mineVideoArr.count) {
                VNNews *lastNews = [weakSelf.mineVideoArr lastObject];
                moreTimeStamp = lastNews.timestamp;
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
                [VNHTTPRequestManager videoListForUser:weakSelf.uid type:@"video" fromTime:moreTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        if (videoArr.count) {
                            [weakSelf.mineVideoArr addObjectsFromArray:videoArr];
                            [weakSelf.videoTableView reloadData];
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.videoTableView.infiniteScrollingView stopAnimating];
                    });
                }];
            });
        }];
        [self.videoTableView triggerPullToRefresh];
        
        //我的收藏
        [self.favouriteTableView registerNib:[UINib nibWithNibName:@"VNProfileVideoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileFavTableViewCellIdentifier"];
        
        [self.favouriteTableView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            [weakSelf reloadAutoPlayStatus];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager favVideoListForUser:weakSelf.uid userToken:weakSelf.user_token fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSString *moreTimestamp,NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        [weakSelf.favVideoArr removeAllObjects];
                        [weakSelf.favVideoArr addObjectsFromArray:videoArr];
                        [weakSelf.favouriteTableView reloadData];
                        weakSelf.favVideoPageTime=moreTimestamp;
                        
                    }
                    favVideofirstLoading = YES;
                    //zmy add 刷新头
                    [weakSelf reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.favouriteTableView.tableHeaderView];
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.favouriteTableView.pullToRefreshView stopAnimating];
                    });
                }];
            });
        }];

        [self.favouriteTableView addInfiniteScrollingWithActionHandler:^{
            [weakSelf reloadAutoPlayStatus];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //NSString *moreTimeStamp = nil;
            if (!weakSelf.favVideoArr.count) {
                weakSelf.favVideoPageTime = [VNHTTPRequestManager timestamp];
            }
            [VNHTTPRequestManager favVideoListForUser:weakSelf.uid userToken:weakSelf.user_token fromTime:weakSelf.favVideoPageTime completion:^(NSArray *videoArr,NSString * moreTimestamp, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        if (videoArr.count) {
                            [weakSelf.favVideoArr addObjectsFromArray:videoArr];
                            [weakSelf.favouriteTableView reloadData];
                        }
                        if (moreTimestamp) {
                            weakSelf.favVideoPageTime=moreTimestamp;
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.favouriteTableView.infiniteScrollingView stopAnimating];
                    });
                }];
            });
        }];
        
        //我的关注
        [self.followTableView registerNib:[UINib nibWithNibName:@"VNProfileFansTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileFollowTableViewCellIdentifier"];
        
        [self.followTableView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
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
                    //zmy add 刷新头
                    [weakSelf reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.followTableView.tableHeaderView];
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.followTableView.pullToRefreshView stopAnimating];
                    });
                }];
            });
        }];
        
        [self.followTableView addInfiniteScrollingWithActionHandler:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *moreTimeStamp = nil;
            if (weakSelf.followLastPageTime) {
                moreTimeStamp = weakSelf.followLastPageTime;
                //NSLog(@"%@", moreTimeStamp);
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
            [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:moreTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.followTableView.infiniteScrollingView stopAnimating];
                    });
                }];
            });
        }];
        
        //我的粉丝
        [self.fansTableView registerNib:[UINib nibWithNibName:@"VNProfileFansTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileFansTableViewCellIdentifier"];
        
        [self.fansTableView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [VNHTTPRequestManager idolListForUser:weakSelf.uid userToken:weakSelf.user_token completion:^(NSArray *idolArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (idolArr.count) {
                        [weakSelf.idolListArr removeAllObjects];
                        [weakSelf.idolListArr addObjectsFromArray:idolArr];
                    }
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else {
                            if (weakSelf.idolListArr.count) {
                                for (VNUser *user in userArr) {
                                    if ([weakSelf.idolListArr containsObject:user.uid]) {
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
                        //zmy add 刷新头
                        [weakSelf reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.fansTableView.tableHeaderView];
                        //
                        dispatch_async(dispatch_get_main_queue(),^{
                            [weakSelf.fansTableView.pullToRefreshView stopAnimating];
                        });
                    }];
                }];
            });
        }];
        
        [self.fansTableView addInfiniteScrollingWithActionHandler:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *moreTimeStamp = nil;
                if (weakSelf.fansLastPageTime ) {
                    moreTimeStamp = weakSelf.fansLastPageTime ;
                }
                else {
                    moreTimeStamp = [VNHTTPRequestManager timestamp];
                }
                
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:moreTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        if (weakSelf.idolListArr.count) {
                            for (VNUser *user in userArr) {
                                if ([weakSelf.idolListArr containsObject:user.uid]) {
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.fansTableView.infiniteScrollingView stopAnimating];
                    });
                }];
            });
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VNMineProfileUploadVideoNotifiction object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VNLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:VNProfileFollowHandlerNotification object:nil];
}

- (void)removeVideoCellForNewsDeleted:(NSNotification *)notification {
    NSIndexPath *index=notification.object;
    [_mineVideoArr removeObjectAtIndex:index.row];
    if (index.row == 0) {
        [_videoTableView reloadData];
    }
    else {
        [_videoTableView reloadData];
    }
}
//若用户在详情页对视频做了取消点赞操作，则也同样会发起这个通知
- (void)removeFavouriteCellForNewsDeleted:(NSNotification *)notification {
    NSIndexPath *index=notification.object;
    VNNews *news=[_favVideoArr objectAtIndex:index.row];
    //删除对应的收藏列表
    [_favouriteNewsArr removeObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
    //删除对应的收藏视频
    [_favVideoArr removeObjectAtIndex:index.row];
    if (index.row == 0) {
        [_favouriteTableView reloadData];
    }
    else {
        //[_favouriteTableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationLeft];
        [_favouriteTableView reloadData];
    }
}
//为了避免重复请求收藏列表，从个人主页 他人个人主页的Video列表跳转详情页时，如果用户对点赞有进行操作，则会发起该通知
-(void)removelikeListForLikeHandler:(NSNotification *)notification{
    NSDictionary *dic=notification.object;
    NSIndexPath *index=dic[@"index"];
    NSString *operate=dic[@"operate"];
    //NSLog(@"%d",index.row);
    if ([operate isEqualToString:@"remove"]) {
        VNNews *news=[_mineVideoArr objectAtIndex:index.row];
        //删除对应的收藏列表
        [_favouriteNewsArr removeObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
    }
    else
    {
        VNNews *news=[_mineVideoArr objectAtIndex:index.row];
        //添加对应的收藏列表
        [_favouriteNewsArr addObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
    }
    
}
-(void)modifyFollowListForFollowHandler:(NSNotification *)notification{
    NSDictionary *dic=notification.object;
    VNUser *user=dic[@"user"];
    NSString *operate=dic[@"operate"];
    //NSLog(@"%d",index.row);
    if ([operate isEqualToString:@"unfollow"]) {
       for(VNUser *user1 in _followArr)
       {
           if ([user1.uid isEqualToString:user.uid]) {
               [_followArr removeObject:user1];
               break;
           }
       }
    }
    else
    {
        user.isMineIdol=YES;
        [_followArr insertObject:user atIndex:0];
    }
    
}

- (void)uploadVideoFile:(NSNotification *)not
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [uploadManager uploadVideo:videoData Uid:uid Title:titleString Tags:tagsString ThumbnailTime:coverTime completion:^(bool success, NSError *err){
            if (err) {
                NSLog(@"%@", err.localizedDescription);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.progressView hide];
                });
                
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

- (void)uploadCoverImage:(NSString *)timestamp
{
    //image data
    NSData *imageData = [self.uploadVideoInfo valueForKey:@"coverImg"];
    
    NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    
    VNUploadManager *uploadManager=[VNUploadManager sharedInstance];
    uploadManager.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [uploadManager uploadVideoThumbnail:imageData Uid:uid timestamp:timestamp completion:^(bool success, NSError *err){
            if (err) {
                NSLog(@"%@", err.localizedDescription);
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
        return self.mineVideoArr.count ? self.mineVideoArr.count : 1;
    }
    if (tableView == self.favouriteTableView) {
        return self.favVideoArr.count ? self.favVideoArr.count : 1;
    }
    if (tableView == self.followTableView) {
        return self.followArr.count ? self.followArr.count : 1;
    }
    if (tableView == self.fansTableView) {
        return self.fansArr.count ? self.fansArr.count : 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //for ipad 诡异
    VNMineProfileHeaderView *videoHeaderView = self.headerViewArr[0];
    if (CGRectGetHeight(videoHeaderView.frame) != 145.0) {
        CGRect frame = videoHeaderView.frame;
        frame.size.height = 145.0;
        videoHeaderView.frame = frame;
        VNMineProfileHeaderView *favHeaderView = self.headerViewArr[1];
        VNMineProfileHeaderView *followHeaderView = self.headerViewArr[2];
        VNMineProfileHeaderView *fansHeaderView = self.headerViewArr[3];
        favHeaderView.frame = frame;
        followHeaderView.frame = frame;
        fansHeaderView.frame = frame;
    }
    
    if (tableView == self.videoTableView) {
        if (self.mineVideoArr.count) {
            VNProfileVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileVideoTableViewCellIdentifier"];
            VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
            cell.news = news;
            cell.isFavouriteNews=NO;
            for (NSDictionary *dic in self.favouriteNewsArr) {
                if ([[dic objectForKey:@"nid"] isEqualToString:[NSString stringWithFormat:@"%d", news.nid]]) {
                    cell.isFavouriteNews=YES;
                    break;
                }
            }
            [cell reload];
            /*改为不自动播放
            if (indexPath.row == 0 && mineVideofirstLoading && isAutoPlayOption && [VNHTTPRequestManager isReachableViaWiFi]) {
                //[cell startOrPausePlaying:YES];
                mineVideofirstLoading = NO;
            }
             */
            __weak typeof(self)weakSelf=self;
            cell.commentHandler = ^(){
                VNNewsDetailViewController *newsDetailViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
                newsDetailViewController.news = news;
                newsDetailViewController.indexPath=indexPath;
                newsDetailViewController.hidesBottomBarWhenPushed = YES;
                newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
                weakSelf.selectedNews=news;
                weakSelf.selectedNewsIndexPath=indexPath;
                [weakSelf.navigationController pushViewController:newsDetailViewController animated:YES];
            };
            
           // __weak typeof(self) weakSelf = self;
            __weak typeof(cell) weakCell = cell;
            
            cell.moreHandler = ^{
                UIActionSheet *actionSheet = nil;
                actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [news.author.uid isEqualToString:weakSelf.uid] ? @"删除" : @"举报", nil];
                weakSelf.shareNews = news;
                weakSelf.shareNewsIndexPath=indexPath;
                actionSheet.tag=KVideoTag;
                [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
            };
            
            cell.likeHandler = ^(){
                if (!weakSelf.uid || !weakSelf.user_token) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                    [alert show];
                    return;
                }
                if (!weakCell.isFavouriteNews) {
                    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager favouriteNews:news.nid operation:@"add" userID:weakSelf.uid user_token:weakSelf.user_token completion:^(BOOL succeed,BOOL isNewsDeleted,int  like_count, int user_like_count,NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else if (isNewsDeleted) {
                            [VNUtility showHUDText:@"该视频已被删除!" forView:weakSelf.view];
                        }
                        else if (succeed) {
                            //dispatch_async(dispatch_get_main_queue(), ^{
                                        //修改数据源
                        [weakSelf.favouriteNewsArr addObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
                        weakCell.news.like_count=like_count;
                        weakCell.isFavouriteNews=YES;
                        [weakCell.likeImg setImage:[UIImage imageNamed:@"30-30heart_a"]];
                        weakCell.favouriteLabel.text = [VNUtility countFormatToDisplay:like_count];
                            VNMineProfileHeaderView *headerView;
                            for (headerView in weakSelf.headerViewArr) {
                                headerView.userInfo.like_count=[VNUtility countFormatToDisplay:user_like_count];
                                [headerView.favouriteCountLabel setText:[VNUtility countFormatToDisplay:user_like_count]];
                            }
                            
                            //[(VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView reload];
                            //[weakSelf reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView];
                        }
                        else {
                            [VNUtility showHUDText:@"已点赞!" forView:weakSelf.view];
                        }
                    }];
                    });
                }
                else
                {
                    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),
                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager favouriteNews:news.nid operation:@"remove" userID:weakSelf.uid user_token:weakSelf.user_token completion:^(BOOL succeed,BOOL isNewsDeleted,int  like_count,int user_like_count, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else if (isNewsDeleted) {
                            [VNUtility showHUDText:@"该视频已被删除!" forView:weakSelf.view];
                            [weakSelf.favouriteNewsArr removeObject:news];
                        }
                        else if (succeed) {
                            [weakSelf.favouriteNewsArr removeObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
                            weakCell.news.like_count=like_count;
                            weakCell.isFavouriteNews=NO;
                            [weakCell.likeImg setImage:[UIImage imageNamed:@"30-30heart"]];
                            //[weakSelf reloadHeaderView:(VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView];
                            weakCell.favouriteLabel.text = [VNUtility countFormatToDisplay:like_count];
                            VNMineProfileHeaderView *headerView;
                            for (headerView in weakSelf.headerViewArr) {
                                headerView.userInfo.like_count=[VNUtility countFormatToDisplay:user_like_count];
                                [headerView.favouriteCountLabel setText:[VNUtility countFormatToDisplay:user_like_count]];
                            }
                            
                        }
                        else {
                            [VNUtility showHUDText:@"取消点赞失败!" forView:weakSelf.view];
                        }
                    }];
                    });
                }
            };
            
            return cell;
        }
        else {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor clearColor];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 145.0, 300, 20)];
            label.font = [UIFont systemFontOfSize:15.0];
            if ([self.mineInfo.video_count isEqualToString:@"0"]) {
                label.text = @"赶快分享你的第一段视频吧～";
            }
            else
            {
                label.text = @"加载中...";
            }
            //label.text = @"赶快分享你的第一段视频吧～";
            label.textColor = [UIColor colorWithRGBValue:0x474747];
            label.textAlignment = NSTextAlignmentCenter;
            [cell addSubview:label];
            return cell;
        }
    }
    if (tableView == self.favouriteTableView) {
        __weak typeof(self) weakSelf=self;
        
        if (self.favVideoArr.count) {
            VNProfileVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileFavTableViewCellIdentifier"];
            VNNews *news = [self.favVideoArr objectAtIndex:indexPath.row];
            cell.news = news;
            [cell reload];
            /*
            if (indexPath.row == 0 && favVideofirstLoading && isAutoPlayOption &&[VNHTTPRequestManager isReachableViaWiFi]) {
                [cell startOrPausePlaying:YES];
                favVideofirstLoading = NO;
            }*/
            cell.commentHandler = ^(){
                VNNewsDetailViewController *newsDetailViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
                newsDetailViewController.news = news;
                newsDetailViewController.indexPath=indexPath;
                newsDetailViewController.hidesBottomBarWhenPushed = YES;
                newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
                weakSelf.selectedNews=news;
                weakSelf.selectedNewsIndexPath=indexPath;
                [weakSelf.navigationController pushViewController:newsDetailViewController animated:YES];
            };
            
           // __weak typeof(self) weakSelf = self;
            __weak typeof(cell) weakCell = cell;
            cell.moreHandler = ^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager isNewsDeleted:weakCell.news.nid completion:^(BOOL isNewsDeleted,NSError *error)
                     {
                         if (error) {
                             NSLog(@"%@", error.localizedDescription);
                         }
                         else if (isNewsDeleted) {
                             [weakSelf.favVideoArr removeObjectAtIndex:indexPath.row];
                             if (indexPath.row == 0) {
                                 [tableView reloadData];
                             }
                             else {
                                 [tableView reloadData];
                             }
                             [VNUtility showHUDText:@"该视频已被删除!" forView:weakSelf.view];
                             
                         }
                         else
                         {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 UIActionSheet *actionSheet = nil;
                                 actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [news.author.uid isEqualToString:weakSelf.uid] ? @"删除" : @"举报", @"取消喜欢",nil];
                                 actionSheet.tag=KLikeTag;
                                 weakSelf.shareNews = news;
                                 weakSelf.shareNewsIndexPath=indexPath;
                                 [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
                             });
                        }
                     }];
                });
            };
            return cell;
        }
        else {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor clearColor];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 145.0, 300, 20)];
            label.font = [UIFont systemFontOfSize:15.0];
            if ([self.mineInfo.like_count isEqualToString:@"0"]) {
                label.text = @"你还没有喜欢的视频哦～";
            }
            else
            {
                label.text = @"加载中...";
            }
           //label.text = @"你还没有喜欢的视频哦～";
            label.textColor = [UIColor colorWithRGBValue:0x474747];
            label.textAlignment = NSTextAlignmentCenter;
            [cell addSubview:label];
            return cell;
        }
    }
    if (tableView == self.followTableView) {
        __weak typeof(self) weakSelf=self;
        if (self.followArr.count) {
            VNProfileFansTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileFollowTableViewCellIdentifier"];
            VNUser *user = [self.followArr objectAtIndex:indexPath.row];
            cell.user = user;
            [cell reload];
            __weak typeof(cell) weakCell = cell;
            cell.followHandler = ^(){
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager followIdol:user.uid follower:weakSelf.uid userToken:weakSelf.user_token operation:@"add" completion:^(BOOL succeed, int fans_count,int idol_count,NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else if (succeed) {
                            //[VNUtility showHUDText:@"关注成功!" forView:self.view];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                weakCell.followBtn.hidden = YES;
                                //[self reloadHeaderView];
                                weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                                ((VNMineProfileHeaderView *)weakSelf.followTableView.tableHeaderView).userInfo.idol_count=[VNUtility countFormatToDisplay:idol_count];
                                //[(VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView reload];
                                [((VNMineProfileHeaderView *)weakSelf.followTableView.tableHeaderView).followCountLabel setText:[VNUtility countFormatToDisplay:idol_count]];
                            });
                            [_followArr insertObject:weakCell.user atIndex:0];
                        }
                        else {
                            weakCell.followBtn.hidden=YES;
                            //[VNUtility showHUDText:@"关注失败!" forView:self.view];
                        }
                    }];
                });
            };
            return cell;
        }
        else {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor clearColor];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 145.0, 300, 20)];
            label.font = [UIFont systemFontOfSize:15.0];
            if ([self.mineInfo.idol_count isEqualToString:@"0"]) {
                label.text = @"你还没有关注的人～";
            }
            else
            {
                label.text = @"加载中...";
            }
            //label.text = @"你还没有关注的人～";
            label.textColor = [UIColor colorWithRGBValue:0x474747];
            label.textAlignment = NSTextAlignmentCenter;
            [cell addSubview:label];
            return cell;
        }
    }
    if (tableView == self.fansTableView) {
        __weak typeof(self) weakSelf=self;
        if (self.fansArr.count) {
            VNProfileFansTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileFansTableViewCellIdentifier"];
            VNUser *user = [self.fansArr objectAtIndex:indexPath.row];
            cell.user = user;
            [cell reload];
            __weak typeof(cell) weakCell = cell;
            cell.followHandler = ^(){
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager followIdol:user.uid follower:weakSelf.uid userToken:weakSelf.user_token operation:@"add" completion:^(BOOL succeed,int fans_count, int idol_count,NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else if (succeed) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                weakCell.followBtn.hidden = YES;
                                //[self reloadHeaderView];
                                weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                                ((VNMineProfileHeaderView *)weakSelf.fansTableView.tableHeaderView).userInfo.fans_count=[VNUtility countFormatToDisplay:fans_count];
                                [((VNMineProfileHeaderView *)weakSelf.fansTableView.tableHeaderView).fansCountLabel setText:[VNUtility countFormatToDisplay:fans_count]];
                                
                            });
                            [_followArr insertObject:weakCell.user atIndex:0];
                        }
                        else {
                            weakCell.followBtn.hidden=YES;
                           // [VNUtility showHUDText:@"关注失败!" forView:self.view];
                        }
                    }];

                });
            };
            return cell;
        }
        else {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor clearColor];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 145.0, 300, 20)];
            label.font = [UIFont systemFontOfSize:15.0];
            if ([self.mineInfo.fans_count isEqualToString:@"0"]) {
                label.text = @"你还有没有粉丝哦～";
            }
            else
            {
                label.text = @"加载中...";
            }
            //label.text = @"你还有没有粉丝哦～";
            label.textColor = [UIColor colorWithRGBValue:0x474747];
            label.textAlignment = NSTextAlignmentCenter;
            [cell addSubview:label];
            return cell;
        }
    }
    
    return nil;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
        if (self.mineVideoArr.count) {
            VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
            VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
            newsDetailViewController.news = news;
            newsDetailViewController.indexPath=indexPath;
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeMineProfileVideo;
            self.selectedNews=news;
            self.selectedNewsIndexPath=indexPath;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        }
    }
    else if (tableView == self.favouriteTableView) {
        if (self.favVideoArr.count) {
            VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
            VNNews *news = [self.favVideoArr objectAtIndex:indexPath.row];
            newsDetailViewController.news = news;
            newsDetailViewController.indexPath=indexPath;
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeMineProfileFavourite;
            self.selectedNews=news;
            self.selectedNewsIndexPath=indexPath;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        }
    }
    else if (tableView == self.followTableView) {
        if (self.followArr.count) {
            VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
            VNUser *user = [self.followArr objectAtIndex:indexPath.row];
            profileViewController.uid = user.uid;
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
    }
    else if (tableView == self.fansTableView) {
        if (self.fansArr.count) {
            VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
            VNUser *user = [self.fansArr objectAtIndex:indexPath.row];
            profileViewController.uid = user.uid;
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
        if (self.mineVideoArr.count) {
            VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
            return [self cellHeightFor:news];
        }
        else {
            return 310;
        }
    }
    if (tableView == self.favouriteTableView) {
        if (self.favVideoArr.count) {
            VNNews *news = [self.favVideoArr objectAtIndex:indexPath.row];
            return [self cellHeightFor:news];
        }
        else {
            return 310;
        }
    }
    if (tableView == self.followTableView) {
        if (self.followArr.count) {
            return 50.0;
        }
        else {
            return 310;
        }
    }
    if (tableView == self.fansTableView) {
        if (self.fansArr.count) {
            return 50.0;
        }
        else {
            return 310;
        }
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
    //NSLog(@"%f", cellHeight);
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

- (void)reloadAutoPlayStatus {
    BOOL isAutoPlayOptionNew = [[[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay] boolValue];
    if (isAutoPlayOption != isAutoPlayOptionNew) {
        isAutoPlayOption = isAutoPlayOptionNew;
    }
}

#pragma mark - Scrollview Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    userScrolling = YES;
    initialScrollOffset = scrollView.contentOffset;
    
//    UITableView *tableView = (UITableView *)scrollView;
//    if (tableView == self.videoTableView || tableView == self.favouriteTableView) {
//        NSArray *visibleCells=[tableView visibleCells];
//        for (VNProfileVideoTableViewCell *cell in visibleCells) {
//            if (cell.isPlaying) {
//                [cell startOrPausePlaying:NO];
//            }
//        }
//    }
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
    
    UITableView *tableView = (UITableView *)scrollView;
    if (tableView == self.videoTableView && self.mineVideoArr.count) {
        for (NSUInteger i=0; i<self.mineVideoArr.count; i++) {
            NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
            VNProfileVideoTableViewCell *cell = (VNProfileVideoTableViewCell *)[tableView cellForRowAtIndexPath:index];
            if (cell.isPlaying) {
                CGRect cellFrameInTableView = [tableView rectForRowAtIndexPath:index];
                CGRect cellFrameInWindow = [tableView convertRect:cellFrameInTableView toView:[UIApplication sharedApplication].keyWindow];
              //  NSLog(@"%@", NSStringFromCGRect(cellFrameInWindow));
                if (CGRectGetMaxY(cellFrameInWindow) < 210 || CGRectGetMinY(cellFrameInWindow) > CGRectGetHeight(self.view.window.frame)-210) {
                    [cell startOrPausePlaying:NO];
                }
            }
        }
    }
    else if (tableView == self.favouriteTableView && self.favVideoArr.count) {
        for (NSUInteger i=0; i<self.favVideoArr.count; i++) {
            NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
            VNProfileVideoTableViewCell *cell = (VNProfileVideoTableViewCell *)[tableView cellForRowAtIndexPath:index];
            NSLog(@"%d",cell.isPlaying);
            if (cell.isPlaying) {
                CGRect cellFrameInTableView = [tableView rectForRowAtIndexPath:index];
                //NSLog(@"%@", NSStringFromCGRect(cellFrameInTableView));
                CGRect cellFrameInWindow = [tableView convertRect:cellFrameInTableView toView:[UIApplication sharedApplication].keyWindow];
//                NSLog(@"%@", NSStringFromCGRect(cellFrameInWindow));
//                NSLog(@"%f",CGRectGetMinY(cellFrameInWindow));
//                NSLog(@"%f",CGRectGetHeight(self.view.window.frame));
//                NSLog(@"%f",CGRectGetMaxY(cellFrameInWindow));

                if (CGRectGetMaxY(cellFrameInWindow) < 210 || CGRectGetMinY(cellFrameInWindow) > CGRectGetHeight(self.view.window.frame)-210) {
                    [cell startOrPausePlaying:NO];
                    NSLog(@"stop");
                }
            }
        }
    }
    /*关闭WiFi下自动播放
    if (isAutoPlayOption && [VNHTTPRequestManager isReachableViaWiFi]) {
        UITableView *tableView = (UITableView *)scrollView;
        if ((tableView == self.videoTableView && self.mineVideoArr.count)|| (tableView == self.favouriteTableView && self.favVideoArr.count)) {
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
    */
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    UITableView *tableView = (UITableView *)scrollView;
    if (tableView == self.videoTableView && self.mineVideoArr.count) {
        for (NSUInteger i=0; i<self.mineVideoArr.count; i++) {
            NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
            VNProfileVideoTableViewCell *cell = (VNProfileVideoTableViewCell *)[tableView cellForRowAtIndexPath:index];
            if (cell.isPlaying) {
                CGRect cellFrameInTableView = [tableView rectForRowAtIndexPath:index];
                CGRect cellFrameInWindow = [tableView convertRect:cellFrameInTableView toView:[UIApplication sharedApplication].keyWindow];
                //  NSLog(@"%@", NSStringFromCGRect(cellFrameInWindow));
                if (CGRectGetMaxY(cellFrameInWindow) < 210 || CGRectGetMinY(cellFrameInWindow) > CGRectGetHeight(self.view.window.frame)-210) {
                    [cell startOrPausePlaying:NO];
                }
            }
        }
    }
    else if (tableView == self.favouriteTableView && self.favVideoArr.count) {
        for (NSUInteger i=0; i<self.favVideoArr.count; i++) {
            NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
            VNProfileVideoTableViewCell *cell = (VNProfileVideoTableViewCell *)[tableView cellForRowAtIndexPath:index];
            if (cell.isPlaying) {
                CGRect cellFrameInTableView = [tableView rectForRowAtIndexPath:index];
                //NSLog(@"%@", NSStringFromCGRect(cellFrameInTableView));
                CGRect cellFrameInWindow = [tableView convertRect:cellFrameInTableView toView:[UIApplication sharedApplication].keyWindow];
                if (CGRectGetMaxY(cellFrameInWindow) < 210 || CGRectGetMinY(cellFrameInWindow) > CGRectGetHeight(self.view.window.frame)-210) {
                    [cell startOrPausePlaying:NO];
                }
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
            shareURL = [[NSString alloc]initWithFormat:@"http://www.shishangpai.com.cn/ssp.php?id=%d",self.shareNews.nid];
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
                    [VNUtility showHUDText:@"已复制该视频链接" forView:self.view];
                }
                else {
                    [VNUtility showHUDText:@"暂无该视频链接" forView:self.view];
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
                    //zmy add
                   // NSLog(@"%d",actionSheet.tag);
                    if (actionSheet.tag==KLikeTag) {
                        alert.tag=KDeleteFromLikes;
                    }
                    _deleteAlert=alert;
                    //
                    [alert show];

                }
                else if ([buttonTitle isEqualToString:@"举报"]) {
                    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                    __weak typeof(self)weakSelf=self;
                    if (userInfo && userInfo.count) {
                        NSString *uid = [userInfo objectForKey:@"openid"];
                        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                        if (uid && user_token) {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                [VNHTTPRequestManager report:[NSString stringWithFormat:@"%d", weakSelf.shareNews.nid] type:@"reportNews" userID:uid userToken:user_token completion:^(BOOL succeed, NSError *error) {
                                    if (error) {
                                        NSLog(@"%@", error.localizedDescription);
                                    }
                                    else if (succeed) {
                                        [VNUtility showHUDText:@"举报成功!" forView:weakSelf.view];
                                    }
                                    else {
                                        [VNUtility showHUDText:@"您已举报该视频" forView:weakSelf.view];
                                    }
                                }];

                            });
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
                NSString *buttonTitle = [actionSheet buttonTitleAtIndex:9];
                if ([buttonTitle isEqualToString:@"取消喜欢"]) {
                   NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
                   NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                    __weak typeof(self) weakSelf=self;
                   if (mineUid && user_token) {
                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                           [VNHTTPRequestManager favouriteNews:_shareNews.nid operation:@"remove" userID:mineUid user_token:user_token completion:^(BOOL succeed,BOOL isNewsDeleted, int like_count,int user_like_count,NSError *error){
                               //isNewsDeleted=YES;
                               if (error) {
                                   NSLog(@"%@", error.localizedDescription);
                               }
                               else if (isNewsDeleted)
                               {
                                   [weakSelf.favVideoArr removeObjectAtIndex:_shareNewsIndexPath.row];
                                   if (_shareNewsIndexPath.row == 0) {
                                       [weakSelf.favouriteTableView reloadData];
                                   }
                                   else {
                                       //[self.favouriteTableView deleteRowsAtIndexPaths:@[_shareNewsIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                       [weakSelf.favouriteTableView reloadData];
                                   }
                                   //[self reloadHeaderView];
                                   ((VNMineProfileHeaderView *)weakSelf.favouriteTableView.tableHeaderView).userInfo.like_count=[VNUtility countFormatToDisplay:user_like_count];
                                   [((VNMineProfileHeaderView *)weakSelf.favouriteTableView.tableHeaderView).favouriteCountLabel setText:[VNUtility countFormatToDisplay:user_like_count]];
                                   [VNUtility showHUDText:@"该视频已被删除!" forView:weakSelf.view];
                               }
                               else if(succeed)
                               {
                                   [weakSelf.favVideoArr removeObjectAtIndex:_shareNewsIndexPath.row];
                                   if (_shareNewsIndexPath.row == 0) {
                                       [weakSelf.favouriteTableView reloadData];
                                   }
                                   else {
                                      // [self.favouriteTableView deleteRowsAtIndexPaths:@[_shareNewsIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                       [weakSelf.favouriteTableView reloadData];
                                   }
                                   //[self reloadHeaderView];
                                   ((VNMineProfileHeaderView *)weakSelf.favouriteTableView.tableHeaderView).userInfo.like_count=[VNUtility countFormatToDisplay:user_like_count];
                                   [((VNMineProfileHeaderView *)weakSelf.favouriteTableView.tableHeaderView).favouriteCountLabel setText:[VNUtility countFormatToDisplay:user_like_count]];
                               }
                               else
                               {
                                   [VNUtility showHUDText:@"取消喜欢失败!" forView:weakSelf.view];
                               }
                           }];
                       });
                    }
                }
                else
                {
                    return;
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
            NSString *shareText = [NSString stringWithFormat:@"我用“时尚拍”分享了一段视频，欢迎围观~：“%@”",self.shareNews.url];
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
    __weak typeof(self)weakSelf=self;
    //根据`responseCode`得到发送结果,如果分享成功
    if(response.responseCode == UMSResponseCodeSuccess) {
        //得到分享到的微博平台名
        NSLog(@"share to sns name is %@",[[response.data allKeys] objectAtIndex:0]);
        //[VNUtility showHUDText:@"分享成功!" forView:self.view];
        [VNHTTPRequestManager commentNews:weakSelf.shareNews.nid content:shareStr completion:^(BOOL succeed,BOOL isNewsDeleted, VNComment *comment, int comment_count,NSError *error) {
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
            __weak typeof(self) weakSelf=self;
            if (mineUid && user_token) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager deleteNews:_shareNews.nid userID:mineUid userToken:user_token completion:^(BOOL succeed,int news_count,NSError *error)
                     {
                         if (error) {
                             NSLog(@"%@", error.localizedDescription);
                         }
                         else if(succeed)
                         {
                             dispatch_async(dispatch_get_main_queue(), ^{

                                 [weakSelf.mineVideoArr removeObjectAtIndex:_shareNewsIndexPath.row];
                                 if (_shareNewsIndexPath.row == 0) {
                                     [weakSelf.videoTableView reloadData];
                                 }
                                 else {
                                     [weakSelf.videoTableView reloadData];
                                 }
                                 if (alertView.tag==KDeleteFromLikes) {
                                     [weakSelf.favVideoArr removeObjectAtIndex:_shareNewsIndexPath.row];
                                     if (_shareNewsIndexPath.row == 0) {
                                         [weakSelf.favouriteTableView reloadData];
                                     }
                                     else {
                                       //  [self.favouriteTableView deleteRowsAtIndexPaths:@[_shareNewsIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                         [weakSelf.favouriteTableView reloadData];
                                     }
                                 }
                                 [VNUtility showHUDText:@"视频删除成功!" forView:weakSelf.view];
                             });
                             //[self reloadHeaderView];
                             ((VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView).userInfo.video_count=[VNUtility countFormatToDisplay:news_count];
                             [((VNMineProfileHeaderView *)weakSelf.videoTableView.tableHeaderView).videoCountLabel setText:[VNUtility countFormatToDisplay:news_count]];
                        }
                         else
                         {
                            // NSLog(@"succeed:%d",succeed);
                             //NSLog(@"news_count:%d",news_count);
                             [VNUtility showHUDText:@"该视频已被删除！" forView:weakSelf.view];
                         }
                     }];
                });
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
        UINavigationController *loginNavCtl = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        [self presentViewController:loginNavCtl animated:YES completion:nil];
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
    
    if ([key hasSuffix:@"mp4"]) {
        [self.progressView hide];
        NSArray *conpons=[[key stringByDeletingPathExtension] componentsSeparatedByString:@"-"];
        NSString *timestamp=[conpons objectAtIndex:2];
        [self uploadCoverImage:timestamp];
       // NSLog(@"%@",ret);
        if (ret && [ret isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[ret objectForKey:@"status"] boolValue];
            if (responseStatus) {
                NSDictionary *news=[ret objectForKey:@"news"];
                if ([news isKindOfClass:[NSDictionary class]]) {
                    _urlStrToShare=news[@"url"];
                }
            }
        }
    }else if ([key hasSuffix:@"jpg"]) {
        [VNUtility showHUDText:@"上传成功" forView:self.view];

        __weak VNMineProfileViewController *weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *shareText = [NSString stringWithFormat:@"我用“时尚拍”制作了一段视频，欢迎围观~：“%@”",_urlStrToShare];
            NSData *shareImageData = [weakSelf.uploadVideoInfo objectForKey:@"coverImg"];
            
            if ([[weakSelf.uploadVideoInfo valueForKey:@"isSinaOn"] boolValue]) {
              //  NSLog(@"%@",shareText);
                [[UMSocialDataService defaultDataService] postSNSWithTypes:@[UMShareToSina] content:shareText image:shareImageData location:nil urlResource:nil presentedController:weakSelf completion:^(UMSocialResponseEntity * response){
                    if (response.responseCode == UMSResponseCodeSuccess) {
                        NSLog(@"新浪微博分享成功了");
                    } else if(response.responseCode != UMSResponseCodeCancel) {
                        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"新浪微博分享失败" message:response.message delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
                        [alertView show];
                    }
                }];
            }
            if ([[weakSelf.uploadVideoInfo valueForKey:@"isWeChatOn"] boolValue]) {
               // NSLog(@"%@",shareText);
                [UMSocialData defaultData].extConfig.wechatTimelineData.url = _urlStrToShare;
                shareStr = shareText;
                [[UMSocialControllerService defaultControllerService] setShareText:shareText shareImage:shareImageData socialUIDelegate:self];
                UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:UMShareToWechatTimeline];
                NSLog(@"%@", snsPlatform);
                snsPlatform.snsClickHandler(self,[UMSocialControllerService defaultControllerService],YES);
            }
            
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
    NSData *data = [self.uploadVideoInfo valueForKey:@"coverImg"];

    NSError *err;
    
    [coverTimeString writeToFile:coverTimePointFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
    [data writeToFile:coverFilePath atomically:YES];
    
    [[NSFileManager defaultManager] copyItemAtPath:videoPath toPath:videoFilePath error:&err];
    
}

@end
