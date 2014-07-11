//
//  VNNotificationViewController.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-10.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNotificationViewController.h"

#import "VNNotificationTableViewCell.h"

#import "UIImageView+AFNetworking.h"
#import "UIButton+AFNetworking.h"

#import "SVPullToRefresh.h"

//#import "VNNotificationTableViewController.h"

@interface VNNotificationViewController ()

@property (weak, nonatomic) IBOutlet UITableView *messageTableView;

@property (strong, nonatomic) NSMutableArray *messageArr;

@property (strong,nonatomic)VNMessage *curMessage;

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
        NSLog(@"uid:%@",authUser.openid);
    }
    else {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        //[alert show];
        return;
    }
    //userToken:(NSString *)user_token

    [VNHTTPRequestManager messageListForUser:authUser.openid  timestamp:[VNHTTPRequestManager timestamp] completion:^(NSArray *messageArr, NSError *error) {
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
#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"VNNotificationTableViewCellIdentifier";
    VNNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    [cell.thumbnail setImageForState:UIControlStateNormal withURL:[NSURL URLWithString:message.sender.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    [cell.thumbnail.layer setCornerRadius:CGRectGetHeight([cell.thumbnail bounds]) / 2];
    cell.thumbnail.layer.masksToBounds = YES;
    if ([message.type isEqualToString: @"user"]) {
        cell.nameLabel.text=message.sender.name;
        //NSString *text=[NSString stringWithFormat:@"@%@关注了你",message.sender.name];
        cell.contentLabel.text=@"关注了你";
        cell.timeLabel.text=message.time;
    }
    else if ([message.type isEqualToString:@"comment"])
    {
        cell.nameLabel.text=message.sender.name;
        NSString *text=[NSString stringWithFormat:@"在\"%@\"中回复了你",message.news.title];
        cell.contentLabel.text=text;
        cell.timeLabel.text=message.time;
        
        NSDictionary *attribute = @{NSFontAttributeName:cell.contentLabel.font};
        CGRect rect = [cell.contentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.contentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        CGRect titleLabelframe = cell.contentLabel.frame;
        titleLabelframe.size.height = CGRectGetHeight(rect);
        //    NSLog(@"%@", NSStringFromCGRect(titleLabelframe));
        cell.contentLabel.frame = titleLabelframe;

    }
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    self.curMessage = message;
    UIActionSheet *actionSheet = nil;
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    NSString *mineID = [userInfo objectForKey:@"openid"];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat diff = 0;
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    //    NSString *testString = @"沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了";
    VNNotificationTableViewCell *cell = loadXib(@"VNNotificationTableViewCell");
    NSDictionary *attribute = @{NSFontAttributeName:cell.contentLabel.font};
    CGRect rect = [message.news.title boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.contentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    //    NSLog(@"%@", NSStringFromCGRect(rect));
    if (CGRectGetHeight(rect) > 20) {
        diff = CGRectGetHeight(rect)-20;
    }
    return 90.0+diff;
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
