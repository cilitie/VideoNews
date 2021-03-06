//
//  VNProfileViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-17.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProfileViewController.h"
#import "VNProfileVideoTableViewCell.h"
#import "SVPullToRefresh.h"
#import "VNUserProfileHeaderView.h"
#import "VNProfileFansTableViewCell.h"
#import "VNNewsDetailViewController.h"
#import "UMSocial.h"
#import "VNLoginViewController.h"
#import "VNMineProfileViewController.h"
#import "VNProfileDetailViewController.h"
#import "VNOriginImgViewController.h"

@interface VNProfileViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UMSocialUIDelegate, UIAlertViewDelegate> {
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
    BOOL isTabBarHidden;
    BOOL firstLoading;
    BOOL isAutoPlayOption;
    BOOL firstLoad;
}

@property (weak, nonatomic) IBOutlet UIButton *followBtn;
@property (weak, nonatomic) IBOutlet UIButton *popBtn;
@property (weak, nonatomic) IBOutlet UITableView *videoTableView;
@property (weak, nonatomic) IBOutlet UITableView *followTableView;
@property (weak, nonatomic) IBOutlet UITableView *fansTableView;

@property (strong, nonatomic) NSMutableArray *userVideoArr;
@property (strong, nonatomic) NSMutableArray *followArr;
@property (strong, nonatomic) NSMutableArray *fansArr;
//@property (strong, nonatomic) NSIndexPath *seletedIndexPath;
//为了检测用户与其他user的关系
@property (strong, nonatomic) NSMutableArray *idolListArr;
@property (strong, nonatomic) VNUser *userInfo;
@property (strong, nonatomic) NSString *followLastPageTime;
@property (strong, nonatomic) NSString *fansLastPageTime;
@property (strong, nonatomic) NSMutableArray *favouriteNewsArr;

@property (strong, nonatomic) NSString *mineUid;
@property (strong, nonatomic) NSString *mineUser_token;
@property (strong, nonatomic) VNNews *shareNews;
@property (strong, nonatomic) VNNews *selectedNews;//选中的news
@property (strong, nonatomic) NSIndexPath *selectedNewsIndexPath;//选中的news对应的位置


@property (strong, nonatomic) NSArray *headerViewArr;

- (IBAction)follow:(id)sender;
- (IBAction)pop:(id)sender;

@end

static NSString *shareStr;

@implementation VNProfileViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _userVideoArr = [NSMutableArray array];
        _followArr = [NSMutableArray array];
        _fansArr = [NSMutableArray array];
        _idolListArr = [NSMutableArray array];
        _favouriteNewsArr = [NSMutableArray array];
        _followLastPageTime = nil;
        _fansLastPageTime = nil;
        _shareNews = nil;
        isTabBarHidden = NO;
        firstLoading = YES;
        isAutoPlayOption = [[[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay] boolValue];
        _headerViewArr = [NSArray array];
        firstLoad=YES;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (firstLoad) {
        firstLoad=NO;
        return;
    }
    if (!self.mineUid || !self.mineUser_token) {
        NSDictionary *userInfoDic = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfoDic && userInfoDic.count) {
            self.mineUid = [userInfoDic objectForKey:@"openid"];
            self.mineUser_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        }
    }
    //刷新网络
    __weak typeof(self) weakSelf=self;
    if (self.headerViewArr.count) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([VNHTTPRequestManager isReachable]) {
                [VNHTTPRequestManager userInfoForUser:weakSelf.uid completion:^(VNUser *userInfo, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (userInfo) {
                        weakSelf.userInfo = userInfo;
                        for (VNUserProfileHeaderView *headerView in weakSelf.headerViewArr) {
                            headerView.userInfo = userInfo;
                            [headerView reload];
                        }
                    }
                }];
            }
        });
    }
    if (weakSelf.mineUid!=nil && weakSelf.mineUser_token) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [VNHTTPRequestManager favouriteNewsListFor:weakSelf.mineUid userToken: weakSelf.mineUser_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
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
            [VNHTTPRequestManager idolListForUser:weakSelf.mineUid userToken:weakSelf.mineUser_token completion:^(NSArray *idolArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (idolArr.count) {
                    [weakSelf.idolListArr removeAllObjects];
                    [weakSelf.idolListArr addObjectsFromArray:idolArr];
                }
                else if(idolArr.count==0){
                    [weakSelf.idolListArr removeAllObjects];
                }
            }];
        });

    }
    
    if (!self.videoTableView.hidden && weakSelf.userVideoArr.count!=0) {
        firstLoading = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            int pagesize=weakSelf.userVideoArr.count;
            if (pagesize<10) {
                    pagesize=10;
            }
                //int pagesize=[weakSelf.userInfo.video_count intValue];
            [VNHTTPRequestManager videoListForUserWithPagesize:weakSelf.uid perPage:pagesize type:@"video" fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    [weakSelf.userVideoArr removeAllObjects];
                    [weakSelf.userVideoArr addObjectsFromArray:videoArr];
                        //NSLog(@"%d", weakSelf.mineVideoArr.count);
                    [weakSelf.videoTableView reloadData];
                }
            }];
        });
    }
    if (!self.followTableView.hidden) {
        if (self.mineUid && self.mineUser_token) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                //刷新关注列表，并且改变可见cell的状态
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                int pagesize=weakSelf.followArr.count;
                if (pagesize<10) {
                        pagesize=10;
                }
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp perPage:pagesize completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                            NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        for (VNUser *user in userArr) {
                            if ([weakSelf.idolListArr containsObject:user.uid]) {
                                    user.isMineIdol = YES;
                            }
                            else if ([weakSelf.mineUid isEqualToString:user.uid]) {
                                    user.isMineIdol = YES;
                            }
                            else {
                                    user.isMineIdol = NO;
                            }
                        }
                        [weakSelf.followArr removeAllObjects];
                        [weakSelf.followArr addObjectsFromArray:userArr];
                        if (lastTimeStamp) {
                                weakSelf.followLastPageTime = lastTimeStamp;
                        }
                        [weakSelf.followTableView reloadData];
                    }
                }];
                if ([weakSelf.idolListArr containsObject:weakSelf.uid]) {
                    [weakSelf.followBtn setTitle:@"取消关注" forState:UIControlStateNormal];
                    [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xa2a2a2]];
                }
                else
                {
                    [weakSelf.followBtn setTitle:@"关注" forState:UIControlStateNormal];
                    [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xce2426]];
                }
            });
        }
        else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                //int pagesize=[weakSelf.userInfo.idol_count intValue];
                int pagesize=weakSelf.followArr.count;
                if (pagesize<10) {
                    pagesize=10;
                }
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp perPage:pagesize completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        [weakSelf.followArr removeAllObjects];
                        [weakSelf.followArr addObjectsFromArray:userArr];
                        if (lastTimeStamp) {
                            weakSelf.followLastPageTime = lastTimeStamp;
                        }
                        [weakSelf.followTableView reloadData];
                    }
                }];
            });
        }
    }
    if (!self.fansTableView.hidden) {
        if (self.mineUid && self.mineUser_token) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                //刷新数据源
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                int pagesize=weakSelf.fansArr.count;
                if (pagesize<10) {
                    pagesize=10;
                }
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp perPage:pagesize completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                            NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                            for (VNUser *user in userArr) {
                                if ([weakSelf.idolListArr containsObject:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else if ([weakSelf.mineUid isEqualToString:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else {
                                    user.isMineIdol = NO;
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
                if ([weakSelf.idolListArr containsObject:weakSelf.uid]) {
                        [weakSelf.followBtn setTitle:@"取消关注" forState:UIControlStateNormal];
                        [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xa2a2a2]];
                }
                else
                {
                    [weakSelf.followBtn setTitle:@"关注" forState:UIControlStateNormal];
                    [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xce2426]];
                }
            });
        }
        else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                //刷新数据源
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    //int pagesize=[weakSelf.userInfo.fans_count intValue];
                int pagesize=weakSelf.fansArr.count;
                if (pagesize<10) {
                    pagesize=10;
                }
                    [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp perPage:pagesize completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else {
                            [weakSelf.fansArr removeAllObjects];
                            [weakSelf.fansArr addObjectsFromArray:userArr];
                            if (lastTimeStamp) {
                                weakSelf.fansLastPageTime = lastTimeStamp;
                            }
                            [weakSelf.fansTableView reloadData];
                        }
                        
                }];
            });
        }
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.userVideoArr.count) {
        if (!self.videoTableView.hidden) {
            for (VNProfileVideoTableViewCell *cell in [self.videoTableView visibleCells]) {
               // if (cell.isPlaying) {
                    [cell startOrPausePlaying:NO];
                    [cell.moviePlayer stop];
               // }
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
    [self.popBtn setHitTestEdgeInsets:UIEdgeInsetsMake(-15.0, -15.0, -15.0, -15.0)];
    
    _videoTableView.showsVerticalScrollIndicator=NO;
    _followTableView.showsVerticalScrollIndicator=NO;
    _fansTableView.showsVerticalScrollIndicator=NO;
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        self.mineUid = [userInfo objectForKey:@"openid"];
        self.mineUser_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    }
    
    self.followBtn.layer.cornerRadius = 5.0;
    self.followBtn.layer.masksToBounds = YES;
    
    [self.followTableView setTableFooterView:[[UIView alloc] init]];
    [self.fansTableView setTableFooterView:[[UIView alloc] init]];
    __weak typeof (self) weakSelf=self;
    if (self.mineUid && self.mineUser_token) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [VNHTTPRequestManager idolListForUser:weakSelf.mineUid userToken:weakSelf.mineUser_token completion:^(NSArray *idolArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (idolArr.count) {
                  //  NSLog(@"%@",idolArr);
                    [weakSelf.idolListArr removeAllObjects];
                    [weakSelf.idolListArr addObjectsFromArray:idolArr];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([idolArr containsObject:weakSelf.uid]) {
                            [weakSelf.followBtn setTitle:@"取消关注" forState:UIControlStateNormal];
                            [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xa2a2a2]];
                        }
                        else {
                            [weakSelf.followBtn setTitle:@"关注" forState:UIControlStateNormal];
                            [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xce2426]];
                        }
                    });
                }
                else if(idolArr.count==0){
                    [weakSelf.idolListArr removeAllObjects];
                }
            }];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [VNHTTPRequestManager favouriteNewsListFor:weakSelf.mineUid userToken:weakSelf.mineUser_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (favouriteNewsArr.count) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //                NSLog(@"%@", favouriteNewsArr);
                        [weakSelf.favouriteNewsArr removeAllObjects];
                        [weakSelf.favouriteNewsArr addObjectsFromArray:favouriteNewsArr];
                    });
                }
                else if (favouriteNewsArr.count==0)
                {
                    [weakSelf.favouriteNewsArr removeAllObjects];
                }
            }];
        });
    }
    
    VNUserProfileHeaderView *videoHeaderView = loadXib(@"VNUserProfileHeaderView");
    VNUserProfileHeaderView *followHeaderView = loadXib(@"VNUserProfileHeaderView");
    VNUserProfileHeaderView *fansHeaderView = loadXib(@"VNUserProfileHeaderView");
    self.headerViewArr = @[videoHeaderView, followHeaderView, fansHeaderView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager userInfoForUser:weakSelf.uid completion:^(VNUser *userInfo, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            if (userInfo) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.userInfo = userInfo;
                    //videoHeaderView
                    videoHeaderView.userInfo = userInfo;
                    [videoHeaderView reload];
                    
                    followHeaderView.userInfo = userInfo;
                    [followHeaderView reload];
                    
                    fansHeaderView.userInfo = userInfo;
                    [fansHeaderView reload];
                });
            }
        }];
    });
    
    //__weak typeof(self) weakSelf = self;
    
    videoHeaderView.tabHandler = ^(NSUInteger index){
        if (weakSelf.userVideoArr.count) {
            for (VNProfileVideoTableViewCell *cell in [weakSelf.videoTableView visibleCells]) {
                if (cell.isPlaying) {
                    [cell startOrPausePlaying:NO];
                }
            }
        }
        
        switch (index) {
            case 0: {
                weakSelf.videoTableView.hidden = NO;
                weakSelf.followTableView.hidden = YES;
                weakSelf.fansTableView.hidden = YES;
                [(VNUserProfileHeaderView *)weakSelf.videoTableView.tableHeaderView reloadTabStatus:0];
               // [weakSelf.videoTableView triggerPullToRefresh];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    [VNHTTPRequestManager videoListForUser:weakSelf.uid type:@"video" fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else {
                                firstLoading = YES;
                                [weakSelf.userVideoArr removeAllObjects];
                                [weakSelf.userVideoArr addObjectsFromArray:videoArr];
                                [weakSelf.videoTableView reloadData];
                            }
                            //[weakSelf reloadHeaderView];
                        });
                    }];
                    
                });
            }
                break;
            case 1: {
                weakSelf.videoTableView.hidden = YES;
                weakSelf.followTableView.hidden = NO;
                weakSelf.fansTableView.hidden = YES;
                [(VNUserProfileHeaderView *)weakSelf.followTableView.tableHeaderView reloadTabStatus:1];
                //[weakSelf.followTableView triggerPullToRefresh];
                if (weakSelf.mineUid && weakSelf.mineUser_token) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                        if (error) {
                                    NSLog(@"%@", error.localizedDescription);
                        }
                        else {
                            for (VNUser *user in userArr) {
                                if ([weakSelf.idolListArr containsObject:user.uid]) {
                                            user.isMineIdol = YES;
                                }
                                else if ([weakSelf.mineUid isEqualToString:user.uid]) {
                                            user.isMineIdol = YES;
                                }
                                else {
                                            user.isMineIdol = NO;
                                        }
                        }
                        [weakSelf.followArr removeAllObjects];
                        [weakSelf.followArr addObjectsFromArray:userArr];
                        if (lastTimeStamp) {
                            weakSelf.followLastPageTime = lastTimeStamp;
                        }
                        [weakSelf.followTableView reloadData];
                    }
                                //zmy add 刷新头
                                //[weakSelf reloadHeaderView];
                                //
                    }];
                });
                }
                else {
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                        [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else {
                                [weakSelf.followArr removeAllObjects];
                                [weakSelf.followArr addObjectsFromArray:userArr];
                                if (lastTimeStamp) {
                                    weakSelf.followLastPageTime = lastTimeStamp;
                                }
                                [weakSelf.followTableView reloadData];
                            }
                            //zmy add 刷新头
                            //[weakSelf reloadHeaderView];
                            //
                        }];
                    });
                }
            }
                break;
            case 2: {
                weakSelf.videoTableView.hidden = YES;
                weakSelf.followTableView.hidden = YES;
                weakSelf.fansTableView.hidden = NO;
                [(VNUserProfileHeaderView *)weakSelf.fansTableView.tableHeaderView reloadTabStatus:2];
                //[weakSelf.fansTableView triggerPullToRefresh];
                if (weakSelf.mineUid && weakSelf.mineUser_token) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                        [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                                if (error) {
                                    NSLog(@"%@", error.localizedDescription);
                                }
                                else {
                                    for (VNUser *user in userArr) {
                                        if ([weakSelf.idolListArr containsObject:user.uid]) {
                                            user.isMineIdol = YES;
                                        }
                                        else if ([weakSelf.mineUid isEqualToString:user.uid]) {
                                            user.isMineIdol = YES;
                                        }
                                        else {
                                            user.isMineIdol = NO;
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
                                //[weakSelf reloadHeaderView];
                                //
                        }];
                    });
                }
                else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                        [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else {
                                [weakSelf.fansArr removeAllObjects];
                                [weakSelf.fansArr addObjectsFromArray:userArr];
                                if (lastTimeStamp) {
                                    weakSelf.fansLastPageTime = lastTimeStamp;
                                }
                                [weakSelf.fansTableView reloadData];
                            }
                            //zmy add 刷新头
                            //[weakSelf reloadHeaderView];
                            //
                        }];
                    });
                }
                }
                break;
            case 11: {
                if (self.userInfo.avatar) {
                    VNOriginImgViewController *originImgViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNOriginImgViewController"];
                    originImgViewController.imgURL = weakSelf.userInfo.avatar;
                    originImgViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    [weakSelf presentViewController:originImgViewController animated:YES completion:nil];
                }
                return ;
            }
                break;
            case 12: {
                if (self.userInfo) {
                    VNProfileDetailViewController *profileDetailViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNProfileDetailViewController"];
                   // NSLog(@"%@",weakSelf.userInfo);
                    profileDetailViewController.user = weakSelf.userInfo;
                    [weakSelf.navigationController pushViewController:profileDetailViewController animated:YES];
                }
            }
                break;
        }
    };
    followHeaderView.tabHandler = videoHeaderView.tabHandler;
    fansHeaderView.tabHandler = videoHeaderView.tabHandler;

    //用户视频
    self.videoTableView.tableHeaderView = videoHeaderView;
    [self.videoTableView registerNib:[UINib nibWithNibName:@"VNProfileVideoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNUserProfileVideoTableViewCellIdentifier"];
    
    [self.videoTableView addPullToRefreshWithActionHandler:^{
        [self reloadAutoPlayStatus];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf reloadHeaderView];
        });
        /*
        if (weakSelf.mineUid && weakSelf.mineUser_token) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [VNHTTPRequestManager favouriteNewsListFor:weakSelf.mineUid userToken:weakSelf.mineUser_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (favouriteNewsArr.count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //                NSLog(@"%@", favouriteNewsArr);
                            [weakSelf.favouriteNewsArr removeAllObjects];
                            [weakSelf.favouriteNewsArr addObjectsFromArray:favouriteNewsArr];
                        });
                    }
                    else if (favouriteNewsArr.count==0)
                    {
                        [weakSelf.favouriteNewsArr removeAllObjects];
                    }
                }];
            });
        }
         */
        // FIXME: Hard code
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager videoListForUser:weakSelf.uid type:@"video" fromTime:refreshTimeStamp completion:^(NSArray *videoArr, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        firstLoading = YES;
                        [weakSelf.userVideoArr removeAllObjects];
                        [weakSelf.userVideoArr addObjectsFromArray:videoArr];
                        [weakSelf.videoTableView reloadData];
                    }
                    [weakSelf.videoTableView.pullToRefreshView stopAnimating];
                });
            }];
        });
    }];
    
    [self.videoTableView addInfiniteScrollingWithActionHandler:^{
        [self reloadAutoPlayStatus];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *moreTimeStamp = nil;
            if (weakSelf.userVideoArr.count) {
                VNNews *lastNews = [weakSelf.userVideoArr lastObject];
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
                        [weakSelf.userVideoArr addObjectsFromArray:videoArr];
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
    
    //用户关注
    self.followTableView.tableHeaderView = followHeaderView;
    [self.followTableView registerNib:[UINib nibWithNibName:@"VNProfileFansTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNUserProfileFollowTableViewCellIdentifier"];
    
    [self.followTableView addPullToRefreshWithActionHandler:^{
        // FIXME: Hard code
        if (weakSelf.mineUid && weakSelf.mineUser_token) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                /*[VNHTTPRequestManager idolListForUser:weakSelf.mineUid userToken:weakSelf.mineUser_token completion:^(NSArray *idolArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (idolArr.count) {
                        [weakSelf.idolListArr removeAllObjects];
                        [weakSelf.idolListArr addObjectsFromArray:idolArr];
                    }
                 */
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else {
                            for (VNUser *user in userArr) {
                                if ([weakSelf.idolListArr containsObject:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else if ([weakSelf.mineUid isEqualToString:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else {
                                    user.isMineIdol = NO;
                                }
                            }
                            [weakSelf.followArr removeAllObjects];
                            [weakSelf.followArr addObjectsFromArray:userArr];
                            if (lastTimeStamp) {
                                weakSelf.followLastPageTime = lastTimeStamp;
                            }
                            [weakSelf.followTableView reloadData];
                        }
                        //zmy add 刷新头
                       // [weakSelf reloadHeaderView];
                        //
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.followTableView.pullToRefreshView stopAnimating];
                        });
                    }];
               // }];
                });
            }
            else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        
                        [weakSelf.followArr removeAllObjects];
                        [weakSelf.followArr addObjectsFromArray:userArr];
                        if (lastTimeStamp) {
                            weakSelf.followLastPageTime = lastTimeStamp;
                        }
                        [weakSelf.followTableView reloadData];
                    }
                    //zmy add 刷新头
                   // [weakSelf reloadHeaderView];
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.followTableView.pullToRefreshView stopAnimating];
                    });
                }];
                });
            }
    }];
    
    [self.followTableView addInfiniteScrollingWithActionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *moreTimeStamp = nil;
        if (weakSelf.followLastPageTime) {
            moreTimeStamp = weakSelf.followLastPageTime;
            NSLog(@"%@", moreTimeStamp);
        }
        else {
            moreTimeStamp = [VNHTTPRequestManager timestamp];
        }
        [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"idols" pageTime:moreTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else {
                if (weakSelf.idolListArr.count) {
                    for (VNUser *user in userArr) {
                        if ([weakSelf.idolListArr containsObject:user.uid]) {
                            user.isMineIdol = YES;
                        }
                        else if ([weakSelf.mineUid isEqualToString:user.uid]) {
                            user.isMineIdol = YES;
                        }
                        else {
                            user.isMineIdol = NO;
                        }
                    }
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
    self.fansTableView.tableHeaderView = fansHeaderView;
    [self.fansTableView registerNib:[UINib nibWithNibName:@"VNProfileFansTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNUserProfileFansTableViewCellIdentifier"];
    
    [self.fansTableView addPullToRefreshWithActionHandler:^{
        if (weakSelf.mineUid && weakSelf.mineUser_token) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                /*
                [VNHTTPRequestManager idolListForUser:weakSelf.mineUid userToken:weakSelf.mineUser_token completion:^(NSArray *idolArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    if (idolArr.count) {
                        [weakSelf.idolListArr removeAllObjects];
                        [weakSelf.idolListArr addObjectsFromArray:idolArr];
                    }
                    else if (idolArr.count==0)
                    {
                        [weakSelf.idolListArr removeAllObjects];
                    }
                 */
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else {
                            for (VNUser *user in userArr) {
                                if ([weakSelf.idolListArr containsObject:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else if ([weakSelf.mineUid isEqualToString:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else {
                                    user.isMineIdol = NO;
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
                       // [weakSelf reloadHeaderView];
                        //
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.fansTableView.pullToRefreshView stopAnimating];
                        });
                    }];
                //}];
            });
        }
        else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager userListForUser:weakSelf.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        [weakSelf.fansArr removeAllObjects];
                        [weakSelf.fansArr addObjectsFromArray:userArr];
                        if (lastTimeStamp) {
                            weakSelf.fansLastPageTime = lastTimeStamp;
                        }
                        [weakSelf.fansTableView reloadData];
                    }
                    //zmy add 刷新头
                    //[weakSelf reloadHeaderView];
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.fansTableView.pullToRefreshView stopAnimating];
                    });
                }];
            });
        }
        // FIXME: Hard code
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
                        else if ([weakSelf.mineUid isEqualToString:user.uid]) {
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
            dispatch_async(dispatch_get_main_queue(),^{
                [weakSelf.fansTableView.infiniteScrollingView stopAnimating];
            });
        }];
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:VNProfileCellDeleteNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:VNProfileVideoLikeHandlerNotification object:nil];
    
}

//zmy add
-(void)reloadHeaderView
{
    __weak typeof (self)weakSelf=self;
    [VNHTTPRequestManager userInfoForUser:weakSelf.uid completion:^(VNUser *userInfo, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        if (userInfo) {
            self.userInfo = userInfo;
            for (VNUserProfileHeaderView *headerView in weakSelf.headerViewArr) {
                headerView.userInfo = userInfo;
                [headerView reload];
            }
        }
    }];
}
//
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.videoTableView) {
        return self.userVideoArr.count ? self.userVideoArr.count : 1;
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
    VNUserProfileHeaderView *videoHeaderView = self.headerViewArr[0];
    if (CGRectGetHeight(videoHeaderView.frame) != 145.0) {
        CGRect frame = videoHeaderView.frame;
        frame.size.height = 145.0;
        videoHeaderView.frame = frame;
        VNUserProfileHeaderView *favHeaderView = self.headerViewArr[1];
        VNUserProfileHeaderView *fansHeaderView = self.headerViewArr[2];
        favHeaderView.frame = frame;
        fansHeaderView.frame = frame;
    }
    
    if (tableView == self.videoTableView) {
        if (self.userVideoArr.count) {
            VNProfileVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNUserProfileVideoTableViewCellIdentifier"];
            VNNews *news = [self.userVideoArr objectAtIndex:indexPath.row];
            cell.news = news;
            cell.isFavouriteNews=NO;
            __weak typeof(self) weakSelf = self;
            //if ([self.favouriteNewsArr containsObject:[NSNumber numberWithInt:news.nid]])
            //{
            if (self.favouriteNewsArr.count!=0) {
                for (NSDictionary *dic in self.favouriteNewsArr) {
                    // NSLog(@"%@",dic[@"nid"]);
                    if ([[dic objectForKey:@"nid"] isEqualToString:[NSString stringWithFormat:@"%d", news.nid]])
                    {
                        cell.isFavouriteNews=YES;
                        break;
                        //[cell likeStatus:YES];
                        //[self.favouriteBtn setSelected:YES];
                        //break;
                    }
                }
            }
            
            //}
            [cell reload];
            if (indexPath.row == 0 && firstLoading && isAutoPlayOption &&[VNHTTPRequestManager isReachableViaWiFi]) {
                [cell startOrPausePlaying:YES];
                firstLoading = NO;
            }
            cell.commentHandler = ^(){
                VNNewsDetailViewController *newsDetailViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
                newsDetailViewController.news = news;
                newsDetailViewController.indexPath=indexPath;
                newsDetailViewController.hidesBottomBarWhenPushed = YES;
                newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
                _selectedNewsIndexPath=indexPath;
                _selectedNews=news;
                [weakSelf.navigationController pushViewController:newsDetailViewController animated:YES];
            };
            
            
            __weak typeof(cell) weakCell = cell;
            
            cell.moreHandler = ^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager isNewsDeleted:weakCell.news.nid completion:^(BOOL isNewsDeleted,NSError *error)
                     {
                         //isNewsDeleted=YES;
                         if (error) {
                             NSLog(@"%@", error.localizedDescription);
                         }
                         else if (isNewsDeleted) {
                             [weakSelf.userVideoArr removeObjectAtIndex:indexPath.row];
                             if (indexPath.row == 0) {
                                 [tableView reloadData];
                             }
                             else {
                                // [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                 [tableView reloadData];
                             }
                             [VNUtility showHUDText:@"该视频已被删除!" forView:weakSelf.view];
                             
                         }
                         else
                         {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 UIActionSheet *actionSheet = nil;
                                 actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接",@"举报", nil];
                                 weakSelf.shareNews = news;
                                 [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];

                             });
                        }
                     }];
                });
            };
            
            cell.likeHandler = ^(){
                if (!self.mineUid || !self.mineUser_token) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                    [alert show];
                    return;
                }
                if (!weakCell.isFavouriteNews) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        //fix me news可以随着点赞操作返回 zmy
                        [VNHTTPRequestManager favouriteNews:news.nid operation:@"add" userID:weakSelf.mineUid user_token:weakSelf.mineUser_token completion:^(BOOL succeed,BOOL isNewsDeleted,int  like_count,int user_like_count, NSError *error) {
                       // [VNHTTPRequestManager profileFavouriteNews:news.nid operation:@"add" userID:self.mineUid user_token:self.mineUser_token completion:^(BOOL succeed,BOOL isNewsDeleted,VNNews *news,int user_like_count,NSError *error){
                            //isNewsDeleted=YES;
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else if (isNewsDeleted) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    //删除相应的cell
                                    [weakSelf.userVideoArr removeObjectAtIndex:indexPath.row];
                                    if (indexPath.row == 0) {
                                        [tableView reloadData];
                                    }
                                    else {
                                        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                        [tableView reloadData];
                                    }

                                });
                                [VNUtility showHUDText:@"该视频已被删除!" forView:self.view];
                            }
                            else if (succeed) {
                                            //修改数据源
                            [weakSelf.favouriteNewsArr addObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
                            weakCell.news.like_count=like_count;
                            weakCell.isFavouriteNews=YES;
                            [weakCell.likeImg setImage:[UIImage imageNamed:@"30-30heart_a"]];
                            weakCell.favouriteLabel.text = [VNUtility countFormatToDisplay:like_count];
                                //[VNUtility showHUDText:@"点赞成功!" forView:self.view];
                            }
                            else {
                                [VNUtility showHUDText:@"已点赞!" forView:weakSelf.view];
                            }
                        }];
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [VNHTTPRequestManager favouriteNews:news.nid operation:@"remove" userID:weakSelf.mineUid user_token:weakSelf.mineUser_token completion:^(BOOL succeed,BOOL isNewsDeleted,int  like_count, int user_like_count,NSError *error) {
                       // [VNHTTPRequestManager profileFavouriteNews:news.nid operation:@"remove" userID:self.mineUid user_token:self.mineUser_token completion:^(BOOL succeed,BOOL isNewsDeleted,VNNews *news,int user_like_count,NSError *error){
                        //isNewsDeleted=YES;
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else if (isNewsDeleted) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                            //删除相应的cell
                            [weakSelf.userVideoArr removeObjectAtIndex:indexPath.row];
                            if (indexPath.row == 0) {
                                [tableView reloadData];
                            }
                            else {
                                [tableView reloadData];
                            }
                            });
                            [VNUtility showHUDText:@"该视频已被删除!" forView:weakSelf.view];
                        }
                        else if (succeed) {
                            [weakSelf.favouriteNewsArr removeObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
                            weakCell.news.like_count=like_count;
                            weakCell.isFavouriteNews=NO;
                            weakCell.favouriteLabel.text = [VNUtility countFormatToDisplay:like_count];
                            [NSString stringWithFormat:@"%d", like_count];
                            [weakCell.likeImg setImage:[UIImage imageNamed:@"30-30heart"]];
                            //[VNUtility showHUDText:@"取消点赞成功!" forView:self.view];
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
            if ([self.userInfo.video_count isEqualToString:@"0"]) {
                label.text = @"TA还没有发表过视频哦～";
            }
            else
            {
               label.text = @"加载中...";
            }
            label.textColor = [UIColor colorWithRGBValue:0x474747];
            label.textAlignment = NSTextAlignmentCenter;
            [cell addSubview:label];
            return cell;
        }
    }
    if (tableView == self.followTableView) {
        __weak typeof(self)weakSelf=self;
        if (self.followArr.count) {
            VNProfileFansTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNUserProfileFollowTableViewCellIdentifier"];
            VNUser *user = [self.followArr objectAtIndex:indexPath.row];
            cell.user = user;
            [cell reload];
            __weak typeof(cell) weakCell = cell;
            cell.followHandler = ^(){
                if (!weakSelf.mineUid || !weakSelf.mineUser_token) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                    [alert show];
                    return;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [VNHTTPRequestManager followIdol:user.uid follower:weakSelf.mineUid userToken:weakSelf.mineUser_token operation:@"add" completion:^(BOOL succeed, int fans_count,int idol_count,NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        //[VNUtility showHUDText:@"关注成功!" forView:self.view];
                        //dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.idolListArr addObject:user.uid];
                        weakCell.followBtn.hidden = YES;
                        weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        //post notification
                        NSDictionary *dic=@{@"operate":@"follow",@"user":weakCell.user};
                        [[NSNotificationCenter defaultCenter] postNotificationName:VNProfileFollowHandlerNotification object:dic];
                        //});
                    }
                    else {
                        weakCell.followBtn.hidden = YES;
                        weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        [VNUtility showHUDText:@"已关注!" forView:weakSelf.view];
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
            if ([self.userInfo.idol_count isEqualToString:@"0"]) {
                label.text = @"TA还没有关注的人～";
            }
            else
            {
                label.text = @"加载中...";
            }
            label.textColor = [UIColor colorWithRGBValue:0x474747];
            label.textAlignment = NSTextAlignmentCenter;
            [cell addSubview:label];
            return cell;
        }
    }
    if (tableView == self.fansTableView) {
        __weak typeof(self)weakSelf=self;
        if (self.fansArr.count) {
            VNProfileFansTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNUserProfileFansTableViewCellIdentifier"];
            VNUser *user = [self.fansArr objectAtIndex:indexPath.row];
            cell.user = user;
            [cell reload];
            __weak typeof(cell) weakCell = cell;
            cell.followHandler = ^(){
                if (!self.mineUid || !self.mineUser_token) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                    [alert show];
                    return;
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [VNHTTPRequestManager followIdol:user.uid follower:weakSelf.mineUid userToken:weakSelf.mineUser_token operation:@"add" completion:^(BOOL succeed, int fans_count,int idol_count,NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        //[VNUtility showHUDText:@"关注成功!" forView:self.view];
                        //dispatch_async(dispatch_get_main_queue(), ^{
                        weakCell.followBtn.hidden = YES;
                        [weakSelf.idolListArr removeObject:user.uid];
                        weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        NSDictionary *dic=@{@"operate":@"follow",@"user":weakCell.user};
                        [[NSNotificationCenter defaultCenter] postNotificationName:VNProfileFollowHandlerNotification object:dic];
                       // });
                    }
                    else {
                        weakCell.followBtn.hidden = YES;
                        weakCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        [VNUtility showHUDText:@"已关注!" forView:weakSelf.view];
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
            if ([self.userInfo.fans_count isEqualToString:@"0"]) {
                label.text = @"TA还有没有粉丝哦～";
            }
            else
            {
                label.text = @"加载中...";
            }
            //label.text = @"TA还有没有粉丝哦～";
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
        if (self.userVideoArr.count) {
            VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
            VNNews *news = [self.userVideoArr objectAtIndex:indexPath.row];
            newsDetailViewController.news = news;
            newsDetailViewController.indexPath=indexPath;
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
            _selectedNews=news;
            _selectedNewsIndexPath=indexPath;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        }
    }
    else if (tableView == self.followTableView) {
        if (self.followArr.count) {
            VNUser *user = [self.followArr objectAtIndex:indexPath.row];
            if ([self.mineUid isEqualToString:user.uid]) {
                VNMineProfileViewController *mineProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNMineProfileViewController"];
                mineProfileViewController.isPush = YES;
                [self.navigationController pushViewController:mineProfileViewController animated:YES];
            }
            else {
                VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
                profileViewController.uid = user.uid;
                [self.navigationController pushViewController:profileViewController animated:YES];
            }

        }
     }
    else if (tableView == self.fansTableView) {
        if (self.fansArr.count) {
            VNUser *user = [self.fansArr objectAtIndex:indexPath.row];
            if ([self.mineUid isEqualToString:user.uid]) {
                VNMineProfileViewController *mineProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNMineProfileViewController"];
                mineProfileViewController.isPush = YES;
                [self.navigationController pushViewController:mineProfileViewController animated:YES];
            }
            else {
                VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
                profileViewController.uid = user.uid;
                [self.navigationController pushViewController:profileViewController animated:YES];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
        if (self.userVideoArr.count) {
            VNNews *news = [self.userVideoArr objectAtIndex:indexPath.row];
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
- (void)removeCellForNewsDeleted:(NSNotification *)notification {
    //int newsNid = [notification.object integerValue];
    //NSLog(@"%d",[notification.object integerValue]);
    NSIndexPath *index=notification.object;
    [_userVideoArr removeObjectAtIndex:index.row];
    if (index.row == 0) {
        [_videoTableView reloadData];
    }
    else {
       // [_videoTableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationLeft];
        [_videoTableView reloadData];
    }
    //[_videoTableView reloadData];
}
//从个人主页 他人个人主页的Video列表跳转详情页时，如果用户对点赞有进行操作，则会发起该通知
-(void)removelikeListForLikeHandler:(NSNotification *)notification{
    NSDictionary *dic=notification.object;
    NSIndexPath *index=dic[@"index"];
    NSString *operate=dic[@"operate"];
    //NSLog(@"%d",index.row);
    if ([operate isEqualToString:@"remove"]) {
        VNNews *news=[_userVideoArr objectAtIndex:index.row];
        //删除对应的收藏列表
        [_favouriteNewsArr removeObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
    }
    else
    {
        VNNews *news=[_userVideoArr objectAtIndex:index.row];
        //添加对应的收藏列表
        [_favouriteNewsArr addObject:@{@"nid":[NSString stringWithFormat:@"%d",news.nid]}];
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


- (IBAction)follow:(id)sender {
    UIButton *button = sender;
    if (!self.mineUid || !self.mineUser_token) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        [alert show];
        return;
    }
    __weak typeof(self) weakSelf = self;
    
    if ([button.currentTitle isEqual:@"关注"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [VNHTTPRequestManager followIdol:weakSelf.uid follower:weakSelf.mineUid userToken:weakSelf.mineUser_token operation:@"add" completion:^(BOOL succeed,int fans_count, int idol_count,NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (succeed) {
                    //[VNUtility showHUDText:@"关注成功!" forView:self.view];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.followBtn setTitle:@"取消关注" forState:UIControlStateNormal];
                        [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xa2a2a2]];
                    });
                    //post notification
                    NSDictionary *dic=@{@"operate":@"follow",@"user":_userInfo};
                    [[NSNotificationCenter defaultCenter] postNotificationName:VNProfileFollowHandlerNotification object:dic];
                    
                    //zmy add 刷新头
                    //[weakSelf reloadHeaderView];
                    weakSelf.userInfo.fans_count = [VNUtility countFormatToDisplay:fans_count];
                    for (VNUserProfileHeaderView *headerView in weakSelf.headerViewArr) {
                        headerView.userInfo = weakSelf.userInfo;
                        //[headerView reload];
                        [headerView.fansCountLabel setText:[VNUtility countFormatToDisplay:fans_count]];
                    }
                    [weakSelf.idolListArr addObject:weakSelf.uid];

                    //fix me 比较trike的作法，直接插入cell
                    [VNHTTPRequestManager userInfoForUser:weakSelf.mineUid completion:^(VNUser *userInfo, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        if (userInfo) {
                            userInfo.isMineIdol=YES;
                            [weakSelf.fansArr insertObject:userInfo atIndex:0];
                            [weakSelf.fansTableView reloadData];
                        }
                    }];

                    //让程序延迟0.5秒,因为时间太短，刷新粉丝列表时无法将最新添加的粉丝返回
                    /*
                    [NSThread sleepForTimeInterval:1];
                    NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                    NSLog(@"%@",refreshTimeStamp);
                    [VNHTTPRequestManager userListForUser:self.uid type:@"fans" pageTime:refreshTimeStamp completion:^(NSArray *userArr, NSString *lastTimeStamp, NSError *error) {
                        if (error) {
                            NSLog(@"%@", error.localizedDescription);
                        }
                        else {
                            for (VNUser *user in userArr) {
                                if ([self.idolListArr containsObject:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else if ([self.mineUid isEqualToString:user.uid]) {
                                    user.isMineIdol = YES;
                                }
                                else {
                                    user.isMineIdol = NO;
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
                        [weakSelf reloadHeaderView];
                        //
                        
                    }];
*/
                //
                }
                else {
                    [weakSelf.followBtn setTitle:@"取消关注" forState:UIControlStateNormal];
                    [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xa2a2a2]];
                    [VNUtility showHUDText:@"已关注!" forView:weakSelf.view];
                }
            }];

        });
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager followIdol:weakSelf.uid follower:weakSelf.mineUid userToken:weakSelf.mineUser_token operation:@"remove" completion:^(BOOL succeed,int fans_count, int idol_count,NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (succeed) {
                //[VNUtility showHUDText:@"取消关注成功!" forView:self.view];
                dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.followBtn setTitle:@"关注" forState:UIControlStateNormal];
                [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xce2426]];
                });
                //zmy add 刷新头
                //[weakSelf reloadHeaderView];
                weakSelf.userInfo.fans_count = [VNUtility countFormatToDisplay:fans_count];
                for (VNUserProfileHeaderView *headerView in weakSelf.headerViewArr) {
                    headerView.userInfo = weakSelf.userInfo;
                    //[headerView reload];
                    [headerView.fansCountLabel setText:[VNUtility countFormatToDisplay:fans_count]];
                }
                [weakSelf.idolListArr removeObject:weakSelf.uid];
                NSDictionary *dic=@{@"operate":@"unfollow",@"user":_userInfo};
                [[NSNotificationCenter defaultCenter] postNotificationName:VNProfileFollowHandlerNotification object:dic];
                for (VNUser *user in weakSelf.fansArr) {
                    if ([user.uid isEqualToString:weakSelf.mineUid]) {
                        [weakSelf.fansArr removeObject:user];
                        break;
                    }
                }
                [weakSelf.fansTableView reloadData];
                //
            }
            else {
                [weakSelf.followBtn setTitle:@"关注" forState:UIControlStateNormal];
                [weakSelf.followBtn setBackgroundColor:[UIColor colorWithRGBValue:0xce2426]];
                [VNUtility showHUDText:@"已取消!" forView:weakSelf.view];
            }
        }];
        });
    }
}

- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
    
    if (self.userVideoArr.count) {
        UITableView *tableView = (UITableView *)scrollView;
        if (tableView == self.videoTableView) {
            for (NSUInteger i=0; i<self.userVideoArr.count; i++) {
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
        
        if (isAutoPlayOption && [VNHTTPRequestManager isReachableViaWiFi]) {
            UITableView *tableView = (UITableView *)scrollView;
            if (tableView == self.videoTableView) {
                NSArray *visibleCells=[tableView visibleCells];
                CGFloat minGap = CGRectGetHeight(self.view.window.bounds);
                VNProfileVideoTableViewCell *curCell = nil;
                for (VNProfileVideoTableViewCell *cell in visibleCells) {
                    CGRect cellFrameInTableView = [tableView rectForRowAtIndexPath:[tableView indexPathForCell:cell]];
                    CGRect cellFrameInWindow = [tableView convertRect:cellFrameInTableView toView:[UIApplication sharedApplication].keyWindow];
                    //NSLog(@"%f", self.view.window.center.y);
                    CGFloat gap = fabs(CGRectGetMidY(cellFrameInWindow)-self.view.window.center.y);
                    if (gap < minGap) {
                       // NSLog(@"%f, %f", minGap, gap);
                        minGap = gap;
                        curCell = cell;
                    }
                }
                if (curCell) {
                    [curCell startOrPausePlaying:YES];
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
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = self.shareNews.url;
                [VNUtility showHUDText:@"已复制该视频链接" forView:self.view];
            }
                break;
                //删除或举报
            case 8: {
                NSString *buttonTitle = [actionSheet buttonTitleAtIndex:8];
                __weak typeof(self)weakSelf=self;
                if ([buttonTitle isEqualToString:@"删除"]) {
                    //TODO: 删除帖子
                }
                else if ([buttonTitle isEqualToString:@"举报"]) {
                    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                    if (userInfo && userInfo.count) {
                        NSString *uid = [userInfo objectForKey:@"openid"];
                        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                        if (uid && user_token) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                [VNHTTPRequestManager report:[NSString stringWithFormat:@"%d", self.shareNews.nid] type:@"reportNews" userID:uid userToken:user_token completion:^(BOOL succeed, NSError *error) {
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
                //取消
            case 9: {
                return ;
            }
                break;
        }
        //设置分享内容，和回调对象
        if (buttonIndex < 7) {
           // NSString *shareText = [NSString stringWithFormat:@"我在用follow my style看到一个有趣的视频：“%@”，来自@“%@”快来看看吧~ %@", self.shareNews.title, self.shareNews.author.name,self.shareNews.url];
            //NSString *shareText = [NSString stringWithFormat:@"分享%@的视频：“%@”，快来看看吧~ %@",  self.shareNews.author.name,self.shareNews.title,self.shareNews.url];
            NSString *shareText = [NSString stringWithFormat:@"我用“时尚拍”制作了一段视频，欢迎围观~：“%@”",self.shareNews.url];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager commentNews:weakSelf.shareNews.nid content:shareStr completion:^(BOOL succeed, BOOL isNewsDeleted,VNComment *comment, int comment_count,NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (isNewsDeleted)
            {
                //删除cell
            }
            else if (succeed) {
                //NSLog(@"分享添加评论成功！");
            }
        }];
        });
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else if (buttonIndex == 1) {
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        UINavigationController *loginNavCtl = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        [self presentViewController:loginNavCtl animated:YES completion:nil];
    }
}

@end
