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

@interface VNMineProfileViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *favouriteCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *followCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *fansCountLabel;
@property (weak, nonatomic) IBOutlet UITableView *videoTableView;
@property (weak, nonatomic) IBOutlet UITableView *favouriteTableView;
@property (weak, nonatomic) IBOutlet UITableView *followTableView;
@property (weak, nonatomic) IBOutlet UITableView *fansTableView;

@property (strong, nonatomic) NSMutableArray *mineVideoArr;
@property (strong, nonatomic) NSMutableArray *favVideoArr;
@property (strong, nonatomic) NSMutableArray *followArr;
@property (strong, nonatomic) NSMutableArray *fansArr;
@property (strong, nonatomic) VNUser *mineInfo;

@property (strong, nonatomic) NSString *uid;
@property (strong, nonatomic) NSString *user_token;

@end

@implementation VNMineProfileViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _mineVideoArr = [NSMutableArray array];
        _favVideoArr = [NSMutableArray array];
        _followArr = [NSMutableArray array];
        _fansArr = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.videoTableView registerNib:[UINib nibWithNibName:@"VNProfileVideoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNProfileVideoTableViewCellIdentifier"];
    self.videoTableView.layer.cornerRadius = 5.0;
    self.videoTableView.layer.masksToBounds = YES;
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        self.uid = [userInfo objectForKey:@"openid"];
        self.user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    }
    
    __weak typeof(self) weakSelf = self;
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
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
         VNProfileVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNProfileVideoTableViewCellIdentifier"];
        VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
        cell.news = news;
        [cell reload];
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.videoTableView) {
        VNNews *news = [self.mineVideoArr objectAtIndex:indexPath.row];
        return [self cellHeightFor:news];
    }
    return 0;
}

- (CGFloat)cellHeightFor:(VNNews *)news {
    __block CGFloat cellHeight = 380.0;
    
    NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:17.0]};
    CGRect rect = [news.title boundingRectWithSize:CGSizeMake(280.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    cellHeight += CGRectGetHeight(rect);
    
    return cellHeight;
}

@end
