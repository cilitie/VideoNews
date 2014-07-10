//
//  VNNotificationViewController.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-10.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNotificationViewController.h"

#import "SVPullToRefresh.h"

//#import "VNNotificationTableViewController.h"

@interface VNNotificationViewController ()

@property (weak, nonatomic) IBOutlet UITableView *messageTableView;

@property (strong, nonatomic) NSMutableArray *messageArr;

@end

@implementation VNNotificationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.messageTableView registerNib:[UINib nibWithNibName:@"VNCommentTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNCommentTableViewCellIdentifier"];
    
    VNAuthUser *authUser = nil;
    NSString *user_token = @"";
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:isLogin] boolValue]) {
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfo.count) {
            authUser = [[VNAuthUser alloc] initWithDict:userInfo];
        }
        user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    }
    else {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        //[alert show];
        return;
    }

    [VNHTTPRequestManager messageListForUser:authUser.openid timestamp:[VNHTTPRequestManager timestamp] completion:^(NSArray *messageArr, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            [self.messageArr addObjectsFromArray:messageArr];
            [self.messageTableView reloadData];
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    
    [self.messageTableView addPullToRefreshWithActionHandler:^{
        // FIXME: Hard code
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager messageListForUser:authUser.openid timestamp:refreshTimeStamp completion:^(NSArray *messageArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    [weakSelf.messageArr removeAllObjects];
                    [weakSelf.messageArr addObjectsFromArray:messageArr];
                    [weakSelf.messageTableView reloadData];
                }
                [weakSelf.messageTableView.pullToRefreshView stopAnimating];
            }];;
        });
    }];
    
    [self.messageTableView addInfiniteScrollingWithActionHandler:^{
        NSString *moreTimeStamp = nil;
        if (weakSelf.messageArr.count) {
            VNComment *lastComent = [weakSelf.messageArr lastObject];
            //            NSLog(@"%@", lastComent.insert_time);
            moreTimeStamp = lastComent.insert_time;
        }
        else {
            moreTimeStamp = [VNHTTPRequestManager timestamp];
        }
        
        [VNHTTPRequestManager messageListForUser:authUser.openid timestamp:moreTimeStamp completion:^(NSArray *commemtArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else {
                [weakSelf.messageArr addObjectsFromArray:commemtArr];
                [weakSelf.messageTableView reloadData];
            }
            [weakSelf.messageTableView.infiniteScrollingView stopAnimating];
        }];
    }];

    

    
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

@end
