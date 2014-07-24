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

@interface VNMineProfileViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UMSocialUIDelegate, UIAlertViewDelegate> {
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
    BOOL isTabBarHidden;
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

@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *user_token;
@property (strong, nonatomic) VNNews *shareNews;

- (IBAction)setting:(id)sender;
- (IBAction)pop:(id)sender;

@end

static BOOL firstLoading = YES;
static NSString *shareStr;

@implementation VNMineProfileViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _mineVideoArr = [NSMutableArray array];
        _favVideoArr = [NSMutableArray array];
        _followArr = [NSMutableArray array];
        _fansArr = [NSMutableArray array];
        _idolListArr = [NSMutableArray array];
        _followLastPageTime = nil;
        _fansLastPageTime = nil;
        _shareNews = nil;
        _uid = nil;
        _user_token = nil;
        _isPush = NO;
        isTabBarHidden = NO;
    }
    return self;
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
    [super viewDidDisappear:animated];
    if (isTabBarHidden) {
        [self showTabBar];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.isPush) {
        self.popBtn.hidden = NO;
    }
    
    [self reload];
}

- (void)reload {
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        self.uid = [userInfo objectForKey:@"openid"];
        self.user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    }
    
    if (self.uid && self.user_token) {
        VNMineProfileHeaderView *videoHeaderView = loadXib(@"VNMineProfileHeaderView");
        VNMineProfileHeaderView *favHeaderView = loadXib(@"VNMineProfileHeaderView");
        VNMineProfileHeaderView *followHeaderView = loadXib(@"VNMineProfileHeaderView");
        VNMineProfileHeaderView *fansHeaderView = loadXib(@"VNMineProfileHeaderView");
        
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
        
        __weak typeof(self) weakSelf = self;
        
        videoHeaderView.editHandler = ^(){};
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
            firstLoading = YES;
            switch (index) {
                case 0: {
                    weakSelf.videoTableView.hidden = NO;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = YES;
                    [weakSelf.videoTableView triggerPullToRefresh];
                }
                    break;
                case 1: {
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = NO;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = YES;
                    [weakSelf.favouriteTableView triggerPullToRefresh];
                }
                    break;
                case 2: {
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = NO;
                    weakSelf.fansTableView.hidden = YES;
                    [weakSelf.followTableView triggerPullToRefresh];
                }
                    break;
                case 3: {
                    weakSelf.videoTableView.hidden = YES;
                    weakSelf.favouriteTableView.hidden = YES;
                    weakSelf.followTableView.hidden = YES;
                    weakSelf.fansTableView.hidden = NO;
                    [weakSelf.fansTableView triggerPullToRefresh];
                }
                    break;
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
        [cell reload];
        if (indexPath.row == 0 && firstLoading) {
            [cell startOrPausePlaying:YES];
            firstLoading = NO;
        }
        cell.commentHandler = ^(){
            VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
            newsDetailViewController.news = news;
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        };
        
        __weak typeof(self) weakSelf = self;
        cell.moreHandler = ^{
            UIActionSheet *actionSheet = nil;
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [news.author.uid isEqualToString:weakSelf.uid] ? @"删除" : @"举报", nil];
            weakSelf.shareNews = news;
            [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
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
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        };
        
        __weak typeof(self) weakSelf = self;
        cell.moreHandler = ^{
            UIActionSheet *actionSheet = nil;
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [news.author.uid isEqualToString:weakSelf.uid] ? @"删除" : @"举报", nil];
            weakSelf.shareNews = news;
            [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
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
            [VNHTTPRequestManager followIdol:user.uid follower:self.uid userToken:self.user_token operation:@"add" completion:^(BOOL succeed, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (succeed) {
                    [VNUtility showHUDText:@"关注成功!" forView:self.view];
                    weakCell.followBtn.hidden = YES;
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
            [VNHTTPRequestManager followIdol:user.uid follower:self.uid userToken:self.user_token operation:@"add" completion:^(BOOL succeed, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (succeed) {
                    [VNUtility showHUDText:@"关注成功!" forView:self.view];
                    weakCell.followBtn.hidden = YES;
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

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
        VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
        VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
        newsDetailViewController.news = news;
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
        newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
        [self.navigationController pushViewController:newsDetailViewController animated:YES];
    }
    else if (tableView == self.favouriteTableView) {
        VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
        VNNews *news = [self.favVideoArr objectAtIndex:indexPath.row];
        newsDetailViewController.news = news;
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
        newsDetailViewController.controllerType = SourceViewControllerTypeProfile;
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
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = self.shareNews.url;
                [VNUtility showHUDText:@"已复制该文章链接" forView:self.view];
            }
                break;
                //删除或举报
            case 8: {
                NSString *buttonTitle = [actionSheet buttonTitleAtIndex:8];
                if ([buttonTitle isEqualToString:@"删除"]) {
                    //TODO: 删除帖子
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
                //取消
            case 9: {
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
        [VNHTTPRequestManager commentNews:self.shareNews.nid content:shareStr completion:^(BOOL succeed, VNComment *comment, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (succeed) {
                NSLog(@"分享添加评论成功！");
            }
        }];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else if (buttonIndex == 1) {
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

- (IBAction)setting:(id)sender {
}

- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
